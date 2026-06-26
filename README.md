🚧 Under Development 🚧

This project is shaping up to be a rhythm-based shooting game where timing is everything. The goal is to blend fast-paced shooting with music-driven mechanics across a variety of themes such as zombies, aliens, and nightclub shootouts. Weapons and playstyles will evolve with difficulty, ranging from simple directional inputs to full keyboard mastery.

Each mode is designed to push players further, starting with basic controls, then expanding into more complex key patterns, and eventually combining letters and numbers for a true test of rhythm and precision. Levels will ramp up over time, introducing increasing intensity as players progress.

Players can shoot targets out of order, but there is a catch, every target has its own timing window. Miss the rhythm, and you will score less while falling out of sync with the beat.

Right now, the focus is on refining the core systems, keyboard input and target timing, to really understand what feels responsive, challenging, and fun. More to come as the mechanics evolve.
## Updates 
### 5/14/2026

Progress update on Rhythm Revolvers:

This week I expanded the core gameplay system by introducing simultaneous on-screen targets, creating a more engaging and reactive player experience. I also implemented scalable difficulty levels, allowing gameplay intensity and pacing to adjust dynamically based on player progression.

Additionally, each target now operates with its own independent timer, directly influencing score calculation. Faster reactions yield higher point values, adding a stronger emphasis on precision, timing, and consistency.

The next stage of development focuses on integrating music sheet data into gameplay logic. Rather than determining target placement or required player input automatically, the system will use note timing intervals from the music sheets to control when targets appear on screen. This will allow gameplay to synchronize more naturally with rhythm structures while preserving player-driven interaction mechanics.

Looking forward to continuing refinement of the gameplay loop and rhythm synchronization systems.
### 06/25/2026

This update focused on expanding the threat system and making the game feel more reactive. A new enemy type called the Biter was introduced as a separate class from regular targets. If the player fails to eliminate a Biter before its 6-second timer runs out, it expands to take over most of the screen and forces the player to correctly press a randomly generated key sequence. Players now have 3 attempts to complete the sequence before a game over is triggered, with the sequence resetting on each wrong press.

A dynamic spawn pacing system was also added. Target spawn speed now adjusts in real time based on recent performance. Consistent hits push the spawn rate faster while too many misses slow it back down, keeping the challenge proportional to how the player is performing.

Additional polish this update includes switching to the Consolas font across the game for clearer number and letter distinction, fixing the leaderboard layout so all entries fit between the title and the footer instructions, and separating internal concerns into dedicated files for easier future development.

---

## Code Reference

### main.lua
The entry point and game loop. Owns the top-level game state, the active target list, the score, the round timer, and the single active biter. All LÖVE2D callbacks live here and delegate to the other modules.

**Key variables**

| Variable | What it holds |
|---|---|
| `targets` | List of all active Target objects currently on screen. |
| `activeBiter` | The single Biter that is currently alive, or nil if none. Only one biter can exist at a time. |
| `pacer` | The Pacing object that controls how fast new targets spawn based on player performance. |
| `isGameOver` | True when the player exhausted all biter attempts. Triggers the game over message and blocks normal input until the player retries or quits. |
| `score` | Points accumulated this round. |
| `elapsed` | Seconds that have passed in the current round. Frozen while a biter sequence is active. |
| `nextSpawnDelay` | The interval until the next target spawns. Supplied by `pacer:getDelay()` rather than a fixed random range. |

**Functions**

| Function | What it does |
|---|---|
| `resetGame()` | Zeroes the score, elapsed time, and spawn timer, clears all targets and the active biter, resets the game over flag, calls `pacer:reset()`, and marks the round as active. Called at the start of every new round. |
| `startRound()` | Reads the difficulty the player picked, applies it to the player object and the spawn direction pool, then calls `resetGame()` and switches the game state to playing. |
| `endRound()` | Stops the round, clears all remaining targets, and submits the final score to the leaderboard. |
| `love.load()` | LÖVE callback that runs once at startup. Sets the window size and title, loads the Consolas font, creates the Menu, Player, and Pacing objects, and seeds the random number generator. |
| `love.update(dt)` | LÖVE callback called every frame. If a biter sequence is active the entire update is skipped (round frozen). Otherwise advances the round timer, handles target and biter spawning using `pacer:getDelay()`, ticks every target (recording a miss with `pacer:recordMiss()` when one expires), and ticks the active biter. Triggers biter expansion when its timer hits zero. |
| `love.draw()` | LÖVE callback called every frame. Draws all targets, then the biter in its warning state, then the HUD (score, timer, legend). If a biter sequence is active, draws the full-screen expanded overlay on top of everything. Shows pause, round-end, or game over messages as appropriate. |
| `love.mousepressed(x, y, button)` | LÖVE callback for mouse clicks. Forwards clicks to the menu and acts on whatever selection the menu returns (Play, Switch Player, Start Game, Leaderboard, Quit). |
| `love.keypressed(key)` | LÖVE callback for key presses. Priority order: menu input → biter sequence input → pause controls → target shooting → escape/restart. Calls `pacer:recordHit()` on every successful target kill or early biter kill. When a biter sequence is active all other input is blocked. |
| `love.textinput(text)` | LÖVE callback for typed characters. Passes the character to the menu's name-entry field when the player is typing their name. |

---

### menu.lua
Manages all screens that are not active gameplay: the main menu, player name entry, difficulty selection, and the leaderboard. Also handles reading and writing scores to disk.

| Function | What it does |
|---|---|
| `Menu.new(width, height)` | Creates a new Menu object. Initializes fonts, button layout, the current player name, and loads the saved leaderboard from disk. |
| `Menu:loadLeaderboard()` | Reads `leaderboard.txt`, parses each `name\|score` line, keeps only the personal best per player name, sorts by score descending, and returns the list. |
| `Menu:saveLeaderboard()` | Serializes the current leaderboard list back to `leaderboard.txt` in `name\|score` format. |
| `Menu:addScore(score, name)` | Adds a new score for a player. If that player already has an entry, only replaces it if the new score is higher. Keeps the list trimmed to the top 10 and saves to disk. |
| `Menu:clearLeaderboard()` | Empties the in-memory leaderboard and deletes `leaderboard.txt` from disk. |
| `Menu:update(dt)` | Per-frame update hook. Currently unused but reserved for future menu animations. |
| `Menu:draw()` | Draws whichever menu screen is currently active: main menu buttons, name input box, difficulty selection buttons, or the ranked leaderboard. |
| `Menu:keypressed(key)` | Handles keyboard navigation inside the menu. Arrow keys move the selection, Enter confirms, Escape cancels or quits, and C clears the leaderboard on the leaderboard screen. Returns a string action that `main.lua` acts on. |
| `Menu:textinput(text)` | Appends a typed character to the name input field, filtered to letters, numbers, spaces, hyphens, and underscores. Capped at 20 characters. |
| `Menu:resetNameEntry()` | Clears the name input field and switches the menu to the name-entry screen. |
| `Menu:mousepressed(x, y, button)` | Hit-tests mouse clicks against the visible buttons on the main menu and difficulty screens. Returns a string action when a button is clicked. |

---

### target.lua
Defines the Target class. A target is a circle that appears on screen with a direction label. The player scores points by pressing the matching key before the target expires.

| Function | What it does |
|---|---|
| `Target.getColor(direction)` | Returns the RGB color for a direction. The four cardinal directions have fixed colors; any other key gets a deterministic color generated from a hash of the key name. |
| `Target.new(x, y, radius, directionType, targetType)` | Creates a target at the given position. Sets up lifetime, hit counters for quicktime targets, and picks a random movement pattern and speed for moving targets. |
| `Target:update(dt)` | Advances the elapsed timer and counts down the lifetime. Kills the target when time runs out. For moving targets, repositions the target each frame according to its pattern (horizontal bounce, vertical bounce, or sine wave). |
| `Target:draw()` | Draws the filled circle in the direction color, adds a colored ring border for quicktime (pink) and moving (cyan) types, draws the direction arrow or key label on top, and shows a hit counter below quicktime targets. |
| `Target:drawArrow(x, y, size, direction)` | Draws a filled triangle arrow centered on the target pointing in the given cardinal direction. |
| `Target:drawKeyLabel(x, y, keyLabel)` | Draws the key name as uppercase text centered on the target. Used for non-arrow directions like letter or number keys. |
| `Target:getPointValue()` | Returns how many points the target is worth based on reaction speed: 200 if hit within 2 seconds, 100 within 4 seconds, 50 after that. |
| `Target.spawnRandom(screenW, screenH, directionType, targetType)` | Picks a random position within the screen (with padding to avoid edges) and returns a new Target at that position. |

---

### biter.lua
Defines the Biter class — a high-stakes threat target that is separate from the normal target pool. Only one biter can exist at a time. It has two phases:

- **Warning phase** — the biter sits on screen like a regular target with a pulsing gold border that speeds up as time runs low. The player has **6 seconds** to eliminate it early by pressing its direction key for a flat **+300 point bonus**, which skips the sequence entirely.
- **Expanded phase** — if the biter is not killed in time, it takes over 80 % of the screen and forces the player to press a randomly generated sequence of 4–6 keys in order. The player gets **3 attempts**: a wrong key costs one attempt and resets the sequence back to step 1. Running out of all attempts triggers game over. Completing the sequence destroys the biter and resumes the round. While the overlay is visible, the round timer and all other target updates are frozen.

**Key fields set in `Biter.new`**

| Field | Purpose |
|---|---|
| `lifeTime` | Countdown in seconds before the biter expands. Starts at 6. |
| `maxAttempts` | Total allowed wrong-key presses before game over. Fixed at 3. |
| `attemptsLeft` | Remaining attempts. Decrements on each wrong key press; game over when it hits 0. |
| `sequence` | The generated list of direction strings the player must press in order. |
| `sequenceIndex` | Which step of the sequence the player is currently on. Resets to 1 after a wrong key. |

**Functions**

| Function | What it does |
|---|---|
| `Biter.new(x, y, directionType, sequencePool, screenW, screenH)` | Creates a biter at the given position. Stores the direction pool used to generate the sequence later, and the screen dimensions needed to draw the expanded overlay. |
| `Biter:expand()` | Transitions the biter from warning to expanded phase. Generates a random 4–6 step sequence drawn from the active difficulty's direction pool and resets `sequenceIndex` to 1. |
| `Biter:update(dt)` | Counts down the biter's lifetime. When the timer hits zero in the warning phase, sets `needsExpansion = true` so `main.lua` can call `expand()` on the next frame. |
| `Biter:handleSequenceInput(direction)` | Called by `main.lua` on each key press during the expanded phase. Correct key advances `sequenceIndex`; returns `"success"` when the final step is cleared. Wrong key decrements `attemptsLeft` and resets `sequenceIndex` to 1; returns `"miss"` if attempts remain, or `"fail"` when all attempts are gone. |
| `Biter:draw()` | Draws the biter in warning phase: a purple filled circle, a gold pulsing border (pulse speed increases as time runs low), a direction arrow or key label, and a `!` warning above the circle. Does nothing in expanded phase — `drawExpanded` handles that. |
| `Biter:drawArrow(x, y, size, direction)` | Draws a filled triangle arrow on the biter pointing in the given cardinal direction. |
| `Biter:drawKeyLabel(x, y, keyLabel)` | Draws the key name as uppercase text centered on the biter. Used for non-arrow direction types (letters, numbers). |
| `Biter:drawExpanded()` | Draws the full-screen sequence overlay: dark screen dim, 80 % panel, attempt dots (green = remaining, dark red = lost), sequence boxes (green = pressed, orange/pulsing = current step, dark = upcoming), a step counter, and instructions. |
| `Biter.spawnRandom(screenW, screenH, directionType, sequencePool)` | Picks a random on-screen position with edge padding and returns a new Biter. Called by `main.lua` during the spawn tick when the 8 % biter roll triggers and no biter is already active. |

---

### pacing.lua
Controls how quickly new targets spawn by watching the player's recent hit/miss performance. `main.lua` holds one `Pacing` object (`pacer`) and calls it every time a target is hit or expires. The delay returned by `getDelay()` replaces the old fixed-random spawn interval.

**How the algorithm works**

A sliding window tracks the last 10 events (hit = 1, miss = 0). After at least 4 events have been recorded, the hit rate is recalculated after every new event:

| Hit rate | Effect |
|---|---|
| ≥ 65 % | Decrease `currentDelay` by 0.1 s (spawns get faster) |
| ≤ 35 % | Increase `currentDelay` by 0.15 s (spawns get slower) |
| Between | No change |

`currentDelay` is clamped between **0.3 s** (fastest) and **2.5 s** (slowest), starting at **1.2 s** at the beginning of each round. A ±0.25 s jitter is added on each `getDelay()` call so spawns never feel perfectly metronomic.

**Functions**

| Function | What it does |
|---|---|
| `Pacing.new()` | Creates a new Pacing object with default thresholds, step sizes, and a 1.2 s base delay. |
| `Pacing:recordHit()` | Pushes a hit event into the sliding window and triggers an adjustment. Called by `main.lua` whenever the player kills a target or eliminates a biter early. |
| `Pacing:recordMiss()` | Pushes a miss event into the sliding window and triggers an adjustment. Called by `main.lua` whenever a target expires without being hit. |
| `Pacing:_push(value)` | Internal. Adds a 1 (hit) or 0 (miss) to the ring buffer, evicting the oldest event when the window is full, and keeps `hitCount` in sync. |
| `Pacing:_adjust()` | Internal. Reads the current hit rate and steps `currentDelay` up or down if the rate has crossed a threshold. Does nothing until at least 4 events have been recorded. |
| `Pacing:getDelay()` | Returns `currentDelay` plus a random jitter (0–0.25 s), clamped to `minDelay`. Used by `main.lua` to set the next spawn countdown. |
| `Pacing:reset()` | Clears the event window and restores `currentDelay` to the base value. Called by `resetGame()` at the start of every round. |

---

### player.lua
Tracks player input and maps keyboard keys to directions based on the active difficulty.

| Function | What it does |
|---|---|
| `Player.new(difficulty)` | Creates a Player object and loads the key bindings for the given difficulty. Defaults to easy if none is provided. |
| `Player:setDifficulty(difficulty)` | Swaps the player's key bindings to match a new difficulty level, called when a round starts. |
| `Player:handleKeyPress(key)` | Checks the pressed key against all bound directions. Returns the matching direction string if found, or nil if the key is not bound. |
| `Player:clearInput()` | Resets the last recorded direction to nil after the input has been processed. |
| `Player:getLastDirection()` | Returns the direction of the most recent key press, or nil if input has been cleared. |

---

### states.lua
A simple constants table with no functions. Provides named string values for every game state and menu screen so the rest of the codebase never uses raw strings like `"playing"` directly.

| Constant group | Values |
|---|---|
| `States.game` | `menu`, `playing`, `paused` |
| `States.menu` | `main`, `nameInput`, `difficultySelect`, `leaderboard` |

---

### difficulty.lua
Stores the configuration for each difficulty level and provides helpers to retrieve it.

| Function | What it does |
|---|---|
| `Difficulty.getConfig(level)` | Returns the full config table for the given difficulty level (name, key list, direction list, key bindings). Falls back to easy if the level is not recognized. |
| `Difficulty.getRandomDirection(level)` | Picks and returns a random direction string from the given difficulty's available directions. |

Each difficulty level controls which keys the player must press and how many distinct target directions can appear:

| Difficulty | Directions | Key bindings |
|---|---|---|
| Easy | Up, Down, Left, Right | Arrow keys and WASD |
| Medium | a s d f g h j k l | One key per direction |
| Hard | All 26 letters | One key per direction |
| Extreme | All 26 letters plus 0–9 | One key per direction |