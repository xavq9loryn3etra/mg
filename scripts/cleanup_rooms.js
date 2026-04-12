const admin = require('firebase-admin');

// Initialize Firebase Admin with Service Account credentials from environment variable
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: `https://${serviceAccount.project_id}-default-rtdb.firebaseio.com` // Ensure correct region if not us-central
});

const db = admin.database();

async function cleanupOldRooms() {
  console.log('Starting old rooms cleanup...');
  const now = Date.now();
  const TWENTY_FOUR_HOURS = 24 * 60 * 60 * 1000;
  
  const roomsRef = db.ref('rooms');
  const roomsSnapshot = await roomsRef.once('value');
  const rooms = roomsSnapshot.val() || {};
  
  let deletedCount = 0;

  for (const [roomCode, roomData] of Object.entries(rooms)) {
    const lastActive = roomData.lastActive;
    
    // If the room lacks a lastActive timestamp, check if it's older than 24 hrs based on some fallback, 
    // or just assume it's legacy and delete if we decide. For safety, let's skip or delete? 
    // Since we just added lastActive, older rooms without it should probably be removed.
    // Let's assume we remove them if they don't have lastActive.
    
    let shouldDelete = false;
    
    if (!lastActive) {
      console.log(`Room ${roomCode} has no lastActive timestamp. Marking for deletion.`);
      shouldDelete = true;
    } else if (now - lastActive > TWENTY_FOUR_HOURS) {
      console.log(`Room ${roomCode} has been inactive for > 24 hours. Marking for deletion.`);
      shouldDelete = true;
    }
    
    if (shouldDelete) {
      try {
        // Delete the room and all its associated data
        await db.ref(`rooms/${roomCode}`).remove();
        await db.ref(`players/${roomCode}`).remove();
        await db.ref(`player_names/${roomCode}`).remove();
        await db.ref(`pending_players/${roomCode}`).remove();
        await db.ref(`night_actions/${roomCode}`).remove();
        
        console.log(`Successfully deleted data for room: ${roomCode}`);
        deletedCount++;
      } catch (err) {
        console.error(`Error deleting room ${roomCode}:`, err);
      }
    }
  }
  
  console.log(`Cleanup complete. Deleted ${deletedCount} abandoned rooms.`);
  process.exit(0);
}

cleanupOldRooms().catch(console.error);
