# Alias

A macOS menu bar app for storing and managing command snippets and notes.

## Features

- **Menu Bar App**: Lives in your macOS menu bar for quick access
- **Command Storage**: Store frequently used shell commands and copy to clipboard with one click
- **Notes**: Keep quick notes and scratchpads
- **Tabbed Interface**: Organize commands and notes into multiple tabs
- **Persistent**: Your data is automatically saved

## Installation

### Build from Source

```bash
cd alias
make
```

The built app will be at `Alias.app`.

### Running

Double-click `Alias.app` or run:
```bash
open Alias.app
```

The app will appear in your menu bar with a terminal icon.

## Usage

1. Click the terminal icon in the menu bar
2. Use the **+** button to add new tabs (Command or Note type)
3. For **Command** tabs: click to copy the command, or click "Edit" to modify
4. For **Note** tabs: type and your notes auto-save
5. Right-click a tab to rename or delete

## Controls

- **Left click** on a tab to select it
- **Right click** on a tab to rename or delete
- **Click "Copy Command"** to copy command to clipboard

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9 or later (for building from source)

## License

MIT License - see LICENSE file
