# NixOS Flake Configuration

Personal NixOS configuration using flakes and home-manager for a Hyprland-based desktop environment.

## Structure

```
.
├── flake.nix              # Main flake entry point
├── home.nix               # Home-manager configuration for user 'pi'
├── common/                # Shared configuration across all hosts
├── hosts/                 # Host-specific configurations
│   └── goldwasser/        # Desktop (AMD + NVIDIA)
├── modules/               # System-level feature modules
│   ├── development.nix    # Dev tools (Rust, Go, Node, Python, etc.)
│   ├── desktop-utils.nix  # Desktop apps & utilities
│   ├── audio.nix          # Audio configuration
│   ├── fonts.nix          # Font packages
│   ├── programs.nix       # System programs
│   └── users.nix          # User account definitions
├── packages/              # User-level application configs
│   ├── hyprland/          # Hyprland WM configuration
│   │   ├── system.nix     # System-level Hyprland setup
│   │   ├── bindings.nix   # Keybindings
│   │   ├── windows.nix    # Window rules
│   │   ├── autostart.nix  # Startup applications
│   │   ├── aesthetic.nix  # Visual settings (gaps, borders, etc.)
│   │   └── envs.nix       # Environment variables
│   ├── zed.nix            # Zed editor
│   ├── ghostty.nix        # Ghostty terminal
│   ├── waybar.nix         # Status bar
│   └── ...                # Other application configs
├── assets/                # Static resources (scripts, themes, wallpapers)
└── secrets/               # SOPS-encrypted secrets
```

## Key Features

- **Window Manager**: Hyprland with split-monitor-workspaces plugin
- **Terminal**: Ghostty
- **Editor**: Zed, Vim
- **Shell**: Fish with atuin, zoxide, fzf
- **Secrets**: Managed via sops-nix
- **Development**: Rust (nightly), Go, Node.js, Python toolchains

## Usage

### Build and switch
```bash
sudo nixos-rebuild switch --flake .#goldwasser
```

### Update flake inputs
```bash
nix flake update
```

### Check flake
```bash
nix flake check
```

## Organization Philosophy

- **modules/**: System-wide packages and configuration (requires sudo)
- **packages/**: User-space applications configured via home-manager
- **hosts/**: Hardware-specific and host-unique settings
- **common/**: Imports shared across all hosts

## Hyprland Setup

Configured with:
- Dual monitors (DP-2, DP-3) with persistent workspaces
- Split-monitor-workspaces for independent workspace sets per monitor
- Custom keybindings, window rules, and autostart applications
- GTK theme: Adwaita dark

## Notes

- State version locked at `22.11` - do not change
- Uses unstable nixpkgs channel
- XDG desktop portal enabled for file pickers and desktop integration
