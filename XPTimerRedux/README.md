# XPTimerRedux

<img width="348" height="237" alt="image" src="https://github.com/user-attachments/assets/4db22c2c-2a7b-4b33-a6f8-6a067c906709" />


A lightweight World of Warcraft XP session tracker for **Retail** and **TBC Classic**.

## Features

- Compact movable window titled **XP Tracker**
- Rows for:
  - Level
  - XP (current / max and %)
  - Session XP
  - XP/hour
  - Time to level
  - Time elapsed
- Session controls:
  - **Start** tracking
  - **Stop** tracking (pauses timer and XP/session calculations)
  - **Reset** session (clears session XP and elapsed time)
- Minimize/expand toggle
- Saved account-wide position, scale, and minimized state

## Installation

1. Copy the `XPTimerRedux` folder into your WoW `Interface/AddOns/` directory.
2. Choose the matching TOC filename for your client:
   - Retail: `XPTimerRedux.toc`
   - TBC Classic: `XPTimerRedux_TBC.toc`
3. Ensure only the appropriate TOC is used by your packaging/deployment flow.

## Slash Commands

- `/xpt show` - show tracker window
- `/xpt hide` - hide tracker window
- `/xpt reset` - reset session XP + timer
- `/xpt start` - start/resume tracking
- `/xpt stop` - pause tracking
- `/xpt scale <number>` - set UI scale (clamped to 0.5 - 2.0)

## Saved Variables

`XPTimerReduxDB` (account-wide):

```lua
XPTimerReduxDB = {
  pos = { point="CENTER", relPoint="CENTER", x=0, y=0 },
  scale = 1.0,
  minimized = false
}
```

## Notes

- XP/hour and Time to level display `—` until enough data is available.
- Time format is `HH:MM:SS`.
- Session XP handles level-ups without breaking calculations.
