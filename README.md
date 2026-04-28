# Alias

A macOS menu bar app for storing and managing command snippets, notes, and secrets.

## Features

- **Menu Bar App**: Lives in your macOS menu bar for quick access.
- **Command Storage**: Store frequently used shell commands.
- **Background Execution**: Run commands directly in the background with visual feedback.
- **Terminal Integration**: Option to run specific commands (like `ssh`) directly in the macOS Terminal app.
- **Notes**: Keep quick notes and scratchpads with auto-save.
- **Password Vault**: Store secrets or passwords, optionally encrypted with a master password.
- **Tabbed Organization**: Group your items into custom tabs with support for reordering via drag-and-drop.
- **Security**: Lock individual tabs with a password to protect sensitive information.
- **Customizable UI**: Adjust window size to fit your needs, with transparency support (`.ultraThinMaterial`).
- **Keyboard Shortcuts**: Power-user shortcuts for quick navigation and actions.

## Keyboard Shortcuts

- `⌘ +` / `⌘ -`: Increase/Decrease window size
- `⌘ 1-9`: Switch to tab 1-9
- `⌘ 0`: Toggle Settings
- `⌘ ⌫`: Delete current tab
- `⌘ N`: Create a new tab
- `⌘ ⇧ N`: Add a new item (Command or Password) to the current tab

## Installation

### Build from Source

You can build the application using the provided Makefile:

```bash
cd alias
make
```

The built app will be created as `Alias.app` in the root directory.

### Running

To build and run the app in one command:
```bash
make run
```

Alternatively, double-click `Alias.app` or run:
```bash
open Alias.app
```

The app will appear in your menu bar with a terminal icon.

## Makefile Commands

- `make`: Build the app bundle
- `make run`: Build and launch the app
- `make clean`: Remove build artifacts and temporary files
- `make help`: Show all available commands

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9 or later (for building from source)

## Versioning

This project uses a `VERSION` file in the root directory to manage the application version. 

To bump the version:
1. Update the version string in the `VERSION` file (e.g., `0.1.1`).
2. When your PR is merged to `main`, a new GitHub Release will be automatically created with the built binary.

The CI workflow will fail if a PR does not increment the version in the `VERSION` file.

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines.

## License

MIT License - see [LICENSE](LICENSE) file
