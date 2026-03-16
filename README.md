# ng_event - Extreme Multi-Level Event for QBox

![FiveM](https://img.shields.io/badge/FiveM-QBox-blue)
![Lua](https://img.shields.io/badge/Language-Lua-green)

An advanced, multi-level event script designed specifically for the **QBox** framework on FiveM. Take your server's events to the next level with a structured, staged experience, complete with UI, varying levels of difficulty, and interactive elements.

## Features
- **Multi-Level Progression**: Features up to 6 distinct levels, dynamically managed server-side.
- **Custom UI Integration**: Built-in React/Vue (NUI) based user interface for event information and interactions.
- **Vehicle integration**: Custom vehicle restrictor, podium placement, and event-specific vehicles.
- **State Synchronization**: Keeps players in sync with the event progression and bucket management.
- **Optimized**: Follows best practices using `ox_lib` and `qbx_core`.

## Dependencies
Ensure you have the following dependencies installed and started before this resource:
- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)

## Installation
1. Clone or download this repository into your `resources` directory (e.g. `[qbox]/ng_event`).
2. Add `ensure ng_event` to your `server.cfg` after the dependencies.

```cfg
# Dependencies
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_target

# Add the event script
ensure ng_event
```

3. Configure your settings in `shared/config.lua` if needed.
4. Restart your server or type `refresh` followed by `ensure ng_event` in your server console.
