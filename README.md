# Racing Game (Godot 4.7)

Multi-track arcade racing game built with Kenney asset packs.

## Play

1. Open the project in **Godot 4.7** (or run from terminal below).
2. Press **F5** to start at the track select screen.
3. Pick a circuit and race.

```powershell
& "c:\Users\Oit-student\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64.exe" --path "c:\Users\Oit-student\racing game"
```

## Controls

| Key | Action |
|-----|--------|
| W / Up | Accelerate |
| S / Down | Brake / reverse |
| A / D | Steer |
| R | Reset car to start |
| Esc | Back to track select |

## Tracks

| Track | Assets used |
|-------|-------------|
| **Racing Circuit** | `racing-kit` road pieces, grandstands, flags |
| **City Streets** | `city-kit-roads` + `city-kit-commercial` buildings |
| **Forest Trail** | `nature-kit` grass, paths, trees, rocks |

## Car

The player car uses the **`race.obj`** model from `car-kit` with `wheel-racing.obj` wheels.

## Re-import assets

If you add new files, run:

```powershell
& "c:\Users\Oit-student\Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path "c:\Users\Oit-student\racing game" --import
```

## Asset packs (`res://assets/`)

Kenney packs: `car-kit`, `city-kit-commercial`, `city-kit-roads`, `nature-kit`, `racing-kit`, and more.
