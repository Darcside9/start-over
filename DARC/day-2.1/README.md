# D∆RC AI Framework Installer

**A production-grade hybrid Bash + Python system-level installer for modular AI on Linux**

## Quick Start

```bash
# Make bootstrap script executable
chmod +x bin/bootstrap.sh

# Run installer (interactive)
sudo bin/bootstrap.sh

# Or run non-interactive
sudo bin/bootstrap.sh --yes

# Or test with dry-run
sudo bin/bootstrap.sh --dry-run --verbose
```

## What Is This?

The D∆RC AI Framework Installer is a complete system installation tool that:

- ✅ **Detects your Linux distribution** (Ubuntu, Debian, Fedora, Arch, openSUSE)
- ✅ **Manages system dependencies** automatically
- ✅ **Installs Ollama** with adaptive wait logic
- ✅ **Downloads AI models** you select
- ✅ **Generates a FastAPI controller** for REST API access
- ✅ **Creates a CLI wrapper** (`darc-ai`) for easy interaction
- ✅ **Sets up auto-start service** via systemd
- ✅ **Logs everything** to file for auditing and debugging
- ✅ **Supports dry-run mode** for testing without making changes
- ✅ **Idempotent operations** safe to re-run

## Architecture

```
Bash Wrapper (32 lines)
    ↓
Python CLI (60 lines)
    ├── System Abstraction (119 lines)
    ├── UI & Menus (301 lines)
    ├── Ollama Integration (111 lines)
    └── Main Orchestrator (620 lines)
    
Total: 1,246 lines of production-grade code
```

## Installation Modes

| Mode | Command | Use Case |
|------|---------|----------|
| **Interactive** | `sudo bin/bootstrap.sh` | Manual installation with full control |
| **Non-Interactive** | `sudo bin/bootstrap.sh --yes` | Automated installs (CI/CD, scripts) |
| **Dry-Run** | `sudo bin/bootstrap.sh --dry-run --verbose` | Test without making changes |
| **Diagnostic** | `sudo bin/bootstrap.sh --diagnose` | Check system compatibility |

## File Structure

```
DARC/day-2.1/
├── bin/
│   └── bootstrap.sh                      # Bash entry point (root check, Python delegation)
├── darc_installer/
│   ├── __init__.py                       # Package initialization
│   ├── cli.py                            # Argument parsing & logging setup
│   ├── system.py                         # Linux distro detection & package management
│   ├── ui.py                             # User prompts, colored output, menus
│   ├── ollama.py                         # Ollama install & model management
│   └── installer.py                      # Main orchestration logic
├── D∆RC Modular AI Installation Script.sh  # Original bash reference (~1000 lines)
├── INSTALLER_DOCUMENTATION.md            # Detailed technical documentation
└── README.md                             # This file
```

## Key Components

### 1. **Bash Wrapper** (`bootstrap.sh`)
- Minimal, auditable entry point
- Checks root privileges and Python availability
- Delegates to Python CLI

### 2. **System Abstraction** (`system.py`)
- Detects Linux distribution automatically
- Abstracts package managers (apt, dnf, pacman, zypper)
- Provides safe subprocess execution with dry-run support

### 3. **User Interface** (`ui.py`)
- Interactive model and component selection menus
- Colored console output (green/red/yellow/blue)
- Installation summary display
- Over 40 predefined AI models and components

### 4. **Ollama Integration** (`ollama.py`)
- Detects if Ollama is already installed
- Automatic download and installation
- Model pulling with adaptive retry logic
- Status checks via HTTP API

### 5. **Main Orchestrator** (`installer.py`)
- Preflight system checks (disk, RAM, network)
- Environment setup (directories, Python venv)
- Installation of system dependencies
- Ollama and model installation
- AI controller and CLI wrapper generation
- Systemd service creation
- Final verification tests

## Environment Variables

```bash
# Custom installation directory (default: /opt/darc-ai)
export AI_HOME=/custom/path

# Then run installer with -E flag to preserve environment
sudo -E bin/bootstrap.sh
```

## After Installation

Once installation completes, you'll have:

```bash
# Use the CLI
darc-ai chat "What is 2+2?"
darc-ai status
darc-ai models
darc-ai start   # Start AI controller
darc-ai stop    # Stop AI controller

# Or use the REST API directly
curl http://localhost:8000/health
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello AI"}'

# Check installation logs
tail -f /opt/darc-ai/logs/installer.log
```

## Command Reference

### Bootstrap Script

```bash
sudo bin/bootstrap.sh [OPTIONS]

Options:
  --dry-run      Don't make changes; print intended commands
  --yes          Auto-accept all prompts (non-interactive)
  --verbose      Increase logging verbosity
  --debug        Enable debug-level logging
  --diagnose     Show system info and exit
```

### Python CLI (direct)

```bash
# Same options as bootstrap.sh
python3 -m darc_installer.cli [OPTIONS]

# Example: diagnose your system
python3 -m darc_installer.cli --diagnose

# Example: non-interactive installation
python3 -m darc_installer.cli --yes --verbose
```

## Features

### ✅ Dry-Run Mode
All operations are printed but not executed. Perfect for:
- Testing on a new system
- CI/CD validation
- Documentation
- Understanding what the installer will do

```bash
sudo bin/bootstrap.sh --dry-run --verbose
```

### ✅ Non-Interactive Mode
Auto-accept all prompts. Perfect for:
- Automated deployments
- Container builds
- Cloud infrastructure
- Scripting

```bash
sudo bin/bootstrap.sh --yes
```

### ✅ Comprehensive Logging
Every action is logged to both:
- **Console**: Color-coded real-time feedback
- **File**: `/opt/darc-ai/logs/installer.log` for auditing

### ✅ Idempotent Operations
Safe to re-run at any time:
- Skips already-installed packages
- Skips already-created directories
- Updates existing configuration cleanly

### ✅ Multi-Distro Support
Automatically detects and adapts to:
- Debian/Ubuntu (apt)
- Fedora/RHEL (dnf)
- Arch Linux (pacman)
- openSUSE (zypper)

## Troubleshooting

### Check System Compatibility
```bash
python3 -m darc_installer.cli --diagnose
```

### View Installation Log
```bash
tail -f /opt/darc-ai/logs/installer.log
```

### Test Ollama Installation
```bash
ollama list
ollama status
```

### Restart AI Controller
```bash
sudo systemctl restart darc-ai
sudo systemctl status darc-ai
```

## System Requirements

- **OS**: Linux (Ubuntu, Debian, Fedora, Arch, openSUSE)
- **Disk Space**: 15GB minimum
- **RAM**: 6GB minimum (8GB+ recommended)
- **Network**: Required for downloads
- **Privileges**: Root/sudo required

## Generated Files

After installation, you'll find:

- **`/opt/darc-ai/config/config.json`** — Installation metadata
- **`/opt/darc-ai/config/.env`** — Environment variables
- **`/opt/darc-ai/scripts/ai_controller.py`** — FastAPI server
- **`/opt/darc-ai/scripts/darc-ai`** — CLI wrapper
- **`/opt/darc-ai/venv/`** — Python virtual environment
- **`/opt/darc-ai/models/`** — Ollama models directory
- **`/opt/darc-ai/logs/installer.log`** — Installation log

## Systemd Service

The installer creates a systemd service for auto-start:

```bash
# Start manually
sudo systemctl start darc-ai

# Check status
sudo systemctl status darc-ai

# View logs
sudo journalctl -u darc-ai -f

# Enable/disable auto-start
sudo systemctl enable darc-ai
sudo systemctl disable darc-ai
```

## Development

### Running Tests Locally

```bash
# Set custom AI_HOME to avoid permission issues
export AI_HOME=/tmp/darc-test

# Run dry-run
python3 -m darc_installer.cli --dry-run --yes

# Run actual installation (to /tmp/darc-test)
python3 -m darc_installer.cli --yes

# Check what was created
ls -la /tmp/darc-test/
cat /tmp/darc-test/config/config.json
```

### Extending with New Models

Edit `darc_installer/ui.py` and add to `MODELS` dict:

```python
MODELS = {
    "your-model:tag": {
        "size": 7.3,  # GB
        "description": "Your model description"
    },
}
```

### Extending with New Components

Edit `darc_installer/ui.py` and add to `COMPONENTS` dict, then update `installer.py` handlers.

## Documentation

- **`INSTALLER_DOCUMENTATION.md`** — Complete technical reference with API details
- **`D∆RC Modular AI Installation Script.sh`** — Original bash reference (~1000 lines)

## License & Attribution

Created by D∆RC  
Advanced Modular AI Framework

## Support

For issues or questions:
1. Check the diagnostic output: `python3 -m darc_installer.cli --diagnose`
2. Review the installation log: `/opt/darc-ai/logs/installer.log`
3. Consult `INSTALLER_DOCUMENTATION.md` for detailed information

---

**Version:** 1.0.0  
**Status:** Production Ready  
**Last Updated:** November 2025
