# Racing Game — Design Brief

> Produced via Superpowers **brainstorming** workflow.  
> Goal: lock scope and architecture before any implementation code.

## Workspace snapshot

- **Status:** Greenfield (no source files yet)
- **Folder:** `racing game`
- **Implication:** Every early decision (stack, camera, controls) compounds. Brainstorm first.

## Problem statement

Build a browser-playable racing game that is fun within one session, easy to extend later, and runnable without a heavy toolchain.

## Target player experience

| Moment | What the player feels |
|--------|------------------------|
| Launch | Instant play — no login, no long load |
| First lap | Clear track boundaries, responsive steering |
| Mid-race | Speed + position feedback (lap time, rank) |
| Finish | Satisfying result screen with retry |

## Recommended MVP scope (v0.1)

**In scope**

- Single track (oval or simple circuit)
- One player car + 2–3 AI opponents
- Keyboard controls (arrow keys or WASD)
- Lap counter + finish detection
- Basic HUD: speed, lap, position
- Start / restart flow

**Out of scope (defer)**

- Multiplayer networking
- Car customization / garage
- Multiple tracks
- Mobile touch controls
- Sound/music (add in v0.2)

## Architecture options

### Option A — HTML5 Canvas + vanilla JS *(recommended for this workspace)*

| Pros | Cons |
|------|------|
| Zero build step; open `index.html` | Manual structure as project grows |
| Full control over game loop | No component model out of the box |
| Easy to add images/sprites | Physics is hand-rolled or small lib |

**Best when:** You want the fastest path to something playable in the browser.

### Option B — Phaser 3

| Pros | Cons |
|------|------|
| Built-in scenes, sprites, physics | npm + bundler setup |
| Large community / examples | Heavier than needed for a tiny MVP |

**Best when:** You expect many entities, particles, and scenes soon.

### Option C — Three.js (3D)

| Pros | Cons |
|------|------|
| 3D visuals | Steeper learning curve |
| Immersive feel | Longer MVP timeline |

**Best when:** 3D look is a hard requirement from day one.

## Recommendation

**Option A** for v0.1: `index.html` + `css/style.css` + `js/game.js` with a fixed-timestep game loop, AABB collision for track walls, and simple AI that follows waypoints.

Upgrade path: extract modules → add Phaser or a physics lib only when complexity demands it.

## Core systems (implementation order)

1. **Game loop** — `requestAnimationFrame`, delta time, pause on tab blur
2. **Track** — boundary polygons or tile map; off-track slowdown
3. **Player car** — acceleration, steering, friction
4. **AI cars** — waypoint following + rudimentary avoidance
5. **Race logic** — checkpoints, lap counting, finish order
6. **UI** — HUD + start/finish overlays
7. **Polish** — car/track images, screen shake, best lap time (`localStorage`)

## Success criteria (verification checklist)

- [ ] Game loads from `index.html` with no build step
- [ ] Player completes 3 laps without soft-locking
- [ ] AI finishes race; positions update on HUD
- [ ] Restart returns to start screen in &lt; 1 s
- [ ] Works in latest Chrome/Edge at 60 fps on a typical laptop

## Next step

Run Superpowers **writing-plans** (`/write-plan`) to turn this brief into a step-by-step implementation plan with TDD hooks, then **test-driven-development** for each system.
