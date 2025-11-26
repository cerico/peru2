# Peru

Lima VM

## TLDR

```bash
make          # Show VM status and available commands
make info     # Show VM status
make setup    # Create VM and install dependencies
make ssh      # Connect to VM
```

## Commands

| Command | Description |
|---------|-------------|
| `make info` | Show VM status |
| `make start` | Start the VM |
| `make stop` | Stop the VM |
| `make ssh` | SSH into the VM |
| `make setup` | Create VM and install all dependencies |
| `make destroy` | Delete the VM |

## Prerequisites

- macOS with Homebrew
- GitHub SSH key configured (`~/.ssh/id_ed25519` or `~/.ssh/id_rsa`)

## What Setup Installs

The `make setup` command provisions the VM with:

- Git, curl, make, OpenSSL
- PostgreSQL 16
- Node.js 22
- pnpm

## Configuration

The VM is configured via `lima.yaml`. Default VM name is `peru`.
