# 🧩 Mafia Game — System Specification

## 👥 1. Player Roles

### 🔴 Required Roles (always present)
- **Mafia** (minimum 1)
- **Doctor** (1)
- **Detective** (1)

### ⚫ Optional Roles
- **Godfather** (0–1)
- **Rabid Dog** (0–1)

### 🟢 Villagers
- All players not assigned a special role are Villagers.
- Villagers have no special abilities.
- They participate only in discussion and voting.

---

## 🌙 2. Game Phases
Each round consists of:

### 🌙 Night Phase
Actions happen in this order:
1. **Mafia** chooses a target to eliminate.
2. **Doctor** chooses a player to heal (can self-heal).
3. **Rabid Dog** chooses a player to bite (if present).
4. **Detective** investigates one player.

### ☀️ Day Phase
1. **Announcement** of night events (who died, if anyone).
2. **Discussion Phase** (all players).
3. **Voting Phase** → one player is eliminated.

---

## ⚔️ 3. Role Mechanics

### 🔪 Mafia
- At least 1 Mafia must exist.
- Work together to eliminate players at night.
- Win by achieving majority control.

### 🩺 Doctor
- Selects 1 player each night to save.
- Can self-heal.
- **Prevents Mafia kills only.**
- ❌ Cannot prevent Rabid Dog bites.

### 🕵️ Detective
- Investigates 1 player each night.
- Receives: `Mafia` or `Not Mafia`.
- ⚠️ Godfather appears as `Not Mafia`.

### 🕴️ Godfather (optional)
- Appears as `Not Mafia` to Detective.
- Otherwise behaves as a standard Mafia member.

### 🐕 Rabid Dog (optional)
- Village-aligned.
- Bites 1 player each night.
- Keeps cumulative bite count per target.
- If a player is bitten twice (any nights) → they die.
- ❌ Cannot bite self.
- ❌ Bite cannot be prevented or healed.
- Does not directly win alone.

---

## 🏁 4. Win Conditions

### 🔴 Mafia Win Condition
Mafia wins immediately when:
🟥 **Mafia members are equal to or greater than all remaining non-mafia players** (Mafia achieves majority control of the game).
- ✔️ Includes Godfather as Mafia.
- ✔️ Dead players are ignored.
- ✔️ Rabid Dog does NOT affect Mafia win condition directly (counts as non-mafia).

### 🟢 Village Win Condition
Village wins when:
🟩 **All Mafia members (including Godfather if present) are eliminated.**
- ✔️ Rabid Dog is considered part of the Village.
- ✔️ Doctor and Detective are Village-aligned.
- ✔️ Villagers are Village-aligned.
- ✔️ Rabid Dog surviving is NOT required for win.

---

## ⚖️ 5. Death & Elimination Rules
A player dies if:
- Killed by Mafia (and not saved by Doctor).
- Receives 2 Rabid Dog bites.
- Eliminated by day vote.

**Dead players:**
- Cannot vote.
- Cannot use abilities.
- Cannot speak.

---

## 🔄 6. Resolution Priority (Important)
At the end of each night, events are resolved sequentially:
1. Mafia kill is resolved.
2. Rabid Dog bite progress is updated.
3. Deaths are applied.
4. Doctor saves are applied (**only vs Mafia kills**).
5. Detective result is generated.

---

## ☀️ 7. Morning Phase (Narration System)
After night resolution, the narrator announces results.

📢 **Morning Announcement Includes:**

### 🔫 1. Gunshot Report (Mafia kill)
- Narrator announces: *"The town was woken by X gunshot(s). [Name] was found dead."*

### 🩸 2. Rabid Dog Deaths
- If any player reaches 2 bites total, narrator announces: *"[Name] succumbed to rabies after being bitten."*

### ❌ 3. Survival/No Death Outcome
- If no one dies, narrator announces: *"The night was quiet. No one died."*

---

## 🧠 8. Key Design Intent
This system balances the game by creating specific roles with countering strengths:
- **🔪 Mafia** = fast, coordinated kills.
- **🩺 Doctor** = single-target protection (limited scope).
- **🕵️ Detective** = information gathering, but partially unreliable (due to Godfather).
- **🐕 Rabid Dog** = slow, unavoidable pressure threat.
- **🟢 Village** = relies on majority-based coordination and deduction to secure the win condition.
