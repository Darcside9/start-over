# D∆RC AI Framework Installer - Complete Documentation

## Overview

The D∆RC AI Framework Installer is a **hybrid Bash + Python** system-level Linux installation tool designed for reliable, repeatable, and idempotent deployment of a modular AI framework across different Linux distributions.

### Architecture

```
bootstrap.sh (Bash wrapper)
    ↓
    └─→ python3 -m darc_installer.cli (Python CLI dispatcher)
            ↓
            ├─→ cli.py (Command-line parsing, logging setup)
            ├─→ system.py (Linux primitives: subprocess, distro detection, package mgmt)
            ├─→ ui.py (User interaction: menus, colored output, selections)
            ├─→ ollama.py (Ollama-specific operations: install, model pulls)
            └─→ installer.py (Main orchestration: runs the complete installation flow)
```

## Directory Structure

```
/home/darc/Documents/DARC/day-2.1/
├── bin/
│   └── bootstrap.sh                 # Bash wrapper (30 lines): root check, Python handoff
├── darc_installer/
│   ├── __init__.py                  # Package marker
│   ├── cli.py                       # Argparse CLI (50 lines)
│   ├── system.py                    # Linux abstraction layer (110 lines)
│   ├── ui.py                        # UI helpers, models/components, selection menus (350 lines)
│   ├── ollama.py                    # Ollama operations (80 lines)
│   └── installer.py                 # Main orchestrator (600 lines)
├── D∆RC Modular AI Installation Script.sh  # Original bash reference (~1000 lines)
└── INSTALLER_DOCUMENTATION.md       # This file
```

## Module Descriptions

### 1. `bootstrap.sh` (Bash Wrapper)

**Purpose:** Minimal, auditable Bash entry point for system-level integration.

**Responsibilities:**

- Check root privileges (exit with error if not root)
- Verify Python 3 is installed (exit if not)
- Set `AI_HOME` environment variable (default: `/opt/darc-ai`)
- Delegate to Python CLI: `python3 -m darc_installer.cli "$@"`

**Key Features:**

- ~30 lines of clear, simple Bash code
- Error traps with informative messages
- No complex logic; all heavy lifting in Python
- Suitable for `/usr/local/bin/darc-install` symlink or direct execution

**Example Usage:**

```bash
sudo /path/to/bootstrap.sh --dry-run --verbose
```

---

### 2. `cli.py` (Command-Line Interface)

**Purpose:** Argument parsing, configuration, and logging setup.

**Responsibilities:**

- Parse command-line arguments using argparse:
  - `--dry-run`: Execute without making changes; print intended commands
  - `--yes`: Auto-accept all prompts (non-interactive mode)
  - `--verbose`: Increase logging verbosity
  - `--debug`: Enable debug-level logging
  - `--diagnose`: Show system info and exit (for troubleshooting)
- Configure logging (console + file)
- Call `run_install()` or `get_sys_info()` based on flags

**Key Features:**

- Clean argument parsing with sensible defaults
- Log level set based on verbosity flags
- File logging setup (logs to `AI_HOME/logs/installer.log`)
- Dry-run flag passed throughout the stack

**Example Usage:**

```bash
python3 -m darc_installer.cli --dry-run --verbose
python3 -m darc_installer.cli --yes                    # Non-interactive auto-install
python3 -m darc_installer.cli --diagnose              # System info only
```

---

### 3. `system.py` (Linux Abstraction Layer)

**Purpose:** Low-level system operations abstraction; handles subprocess execution, distro detection, and package management.

**Key Functions:**

#### `run_cmd(cmd, dry_run=False, check=True, capture=False, check=True)`

- Safe subprocess wrapper respecting `dry_run` flag
- Prints intended command in dry-run mode without executing
- Returns `CompletedProcess` or None
- Handles errors with logging

#### `detect_package_manager()`

- Detects Linux distribution and returns package manager name
- Supports: apt (Debian/Ubuntu), dnf (Fedora/RHEL), pacman (Arch), zypper (openSUSE)
- Used to abstract package installation logic

#### `install_packages(packages, dry_run=False)`

- Installs system packages using detected package manager
- Idempotent: checks if package is already installed before attempting install
- Supports multiple distros transparently

#### `systemctl_enable_start(service_name, dry_run=False)`

- Enables and starts systemd service
- Idempotent: checks if service is already running

#### `is_package_installed_apt(package_name)`

- Checks if package is installed (APT version shown; similar for other PMs)

**Key Features:**

- Single point of abstraction for all system calls
- Dry-run support throughout
- Logging for all operations
- Error handling and validation

---

### 4. `ui.py` (User Interface & Interaction)

**Purpose:** User-facing interactions: colored output, model/component definitions, interactive menus.

**Key Data Structures:**

#### `MODELS` Dictionary

```python
MODELS = {
    "llama2:7b": {"size": 3.8, "description": "Llama 2 7B..."},
    "mistral:7b-instruct": {"size": 3.5, "description": "Mistral 7B..."},
    ...
}
```

#### `COMPONENTS` Dictionary

```python
COMPONENTS = {
    "core": {"description": "Core AI System..."},
    "analytics": {"description": "Analytics Module..."},
    ...
}
```

**Key Functions:**

#### `print_banner()`

- Displays styled D∆RC AI Framework header banner

#### `print_section(title)`

- Prints section headers with visual separators

#### `print_success(msg)`, `print_error(msg)`, `print_warning(msg)`, `print_info(msg)`

- Colored console output (green, red, yellow, blue) using ANSI codes
- All output logged to file

#### `select_models(assume_yes=False)`

- Interactive menu for model selection
- Uses readline for navigation
- Returns list of selected model names
- In `--yes` mode, auto-selects recommended models

#### `select_components(assume_yes=False)`

- Interactive menu for component selection
- Similar to `select_models()`
- Returns list of selected component identifiers

#### `show_installation_summary(models, components, ai_home, assume_yes=False)`

- Displays summary: selected models, components, download size, installation directory
- Waits for user confirmation (auto-confirms in `--yes` mode)

#### `calculate_total_size(models)`

- Sums the download sizes of selected models
- Returns formatted string (e.g., "7.3GB")

**Key Features:**

- ANSI color support for better readability
- Readline support for interactive menus
- Accessible even on minimal systems
- Full logging of user interactions

---

### 5. `ollama.py` (Ollama Integration)

**Purpose:** Ollama-specific operations: installation, model downloads, status checks.

**Key Functions:**

#### `is_ollama_installed()`

- Checks if Ollama is already installed
- Returns True/False

#### `install_ollama(dry_run=False)`

- Downloads official Ollama installer script from `ollama.ai`
- Executes install script
- Enables and starts Ollama systemd service
- Includes adaptive wait logic (up to 30 retries, 2 seconds between retries)

#### `pull_model(model_name, dry_run=False)`

- Pulls a single model from Ollama registry using HTTP API
- Adaptive wait for Ollama service availability
- Logs progress

#### `pull_models(model_names, dry_run=False)`

- Iterates over list of model names and pulls each one
- Continues even if one model pull fails (logs warning)

#### `get_installed_models()`

- Fetches list of currently installed models via Ollama API

**Key Features:**

- Idempotency: checks if Ollama is already installed before installing
- Adaptive wait logic: retries HTTP requests with exponential backoff
- Full error handling and logging
- Supports HTTP API for model management (not just CLI)

---

### 6. `installer.py` (Main Orchestrator)

**Purpose:** Coordinate the complete installation flow; calls all other modules in proper sequence.

**Main Entry Point:**

#### `run_install(dry_run=False, assume_yes=False)`

- Main installation orchestrator called by CLI
- Executes in the following sequence:

**Sequence of Operations:**

1. **Banner & Logging Setup**

   - Display welcome banner
   - Initialize logging to console + file

2. **Preflight Checks** (`preflight_checks()`)

   - Verify disk space (15GB minimum)
   - Verify RAM (6GB minimum, warning if less)
   - Verify network connectivity (ping 8.8.8.8)

3. **Interactive User Selections** (skipped in `--yes` mode)

   - Model selection menu (`select_models()`)
   - Component selection menu (`select_components()`)

4. **Installation Summary**

   - Display selected models, components, total size, installation directory
   - Wait for user confirmation (or auto-confirm in `--yes` mode)

5. **Environment Preparation**

   - Create directory structure (`create_directories()`)
   - Install system dependencies (`install_system_dependencies()`)
   - Setup Python virtual environment (`setup_python_venv()`)

6. **Ollama Installation & Model Pulls**

   - Install Ollama (`install_ollama()`)
   - Pull selected models (`pull_models()`)

7. **Core AI System Installation**

   - Write `ai_controller.py` (FastAPI server)
   - Write `darc-ai` CLI wrapper (Bash script)

8. **Configuration & Finalization**

   - Create config.json and .env files
   - Create systemd service (if "system" component selected)
   - Run final tests (verify Ollama connectivity)

9. **Success Message**
   - Display installation summary: installation directory, model count, component count, total size
   - Provide quick-start commands

**Helper Functions:**

#### `setup_logging(ai_home: str)`

- Configures Python logging with both console and file handlers
- Returns path to log file

#### `preflight_checks()`

- Validates system requirements before proceeding

#### `create_directories(ai_home: str)`

- Creates AI_HOME directory structure: logs, models, scripts, config, data, temp

#### `install_system_dependencies(dry_run: bool)`

- Installs system packages: curl, wget, git, python3, python3-pip, redis-server, jq, etc.

#### `setup_python_venv(ai_home: str, dry_run: bool)`

- Creates Python virtual environment
- Installs core packages: fastapi, uvicorn, requests, redis, pydantic, rich, etc.

#### `write_ai_controller(scripts_dir: Path)`

- Generates ai_controller.py: FastAPI server with /chat, /health, /models endpoints
- Includes Ollama integration

#### `write_darc_cli(scripts_dir: Path, ai_home: str)`

- Generates darc-ai Bash wrapper CLI
- Supports: chat, models, status, start, stop commands

#### `write_core_scripts(ai_home: str)`

- Calls `write_ai_controller()` and `write_darc_cli()`

#### `create_config_files(ai_home: str, models: list, components: list)`

- Writes config.json (version, models, components, URLs, paths)
- Writes .env (environment variables)

#### `create_systemd_service(ai_home: str, components: list, dry_run: bool)`

- Creates /etc/systemd/system/darc-ai.service
- Enables auto-start on boot (if "system" component selected)

#### `run_final_tests(dry_run: bool)`

- Tests Ollama connectivity: `ollama list`

**Key Features:**

- Complete installation orchestration in one function
- Proper sequencing and dependency management
- Dry-run support throughout (respects flag from CLI)
- User interactivity with auto-confirm option (`--yes`)
- Comprehensive error handling with logging
- Idempotent operations (safe to re-run)

---

## Installation Modes

### 1. Interactive Mode (Default)

```bash
sudo /path/to/bootstrap.sh
```

- Displays preflight checks
- Shows model selection menu
- Shows component selection menu
- Displays installation summary
- Waits for user confirmation before proceeding
- Installs with progress messages

### 2. Non-Interactive Mode (`--yes`)

```bash
sudo /path/to/bootstrap.sh --yes
```

- Skips all prompts
- Auto-selects recommended models
- Auto-selects core component
- Proceeds with installation immediately
- Ideal for CI/CD, automation, scripting

### 3. Dry-Run Mode (`--dry-run`)

```bash
sudo /path/to/bootstrap.sh --dry-run --verbose
```

- Prints all intended commands without executing
- Validates syntax and dependencies
- Useful for testing, CI validation, documentation
- Respects `--yes` flag if provided

### 4. Diagnostic Mode (`--diagnose`)

```bash
sudo /path/to/bootstrap.sh --diagnose
```

- Shows system information: OS, package manager, available disk/RAM, network status
- Exits after diagnosis without installing
- Useful for troubleshooting

## Environment Variables

- **`AI_HOME`**: Installation directory (default: `/opt/darc-ai`)
  - Override: `export AI_HOME=/custom/path && sudo -E bootstrap.sh`

## Output & Logging

### Console Output

- Colored status messages:
  - `[✓]` Green: Success
  - `[✗]` Red: Error
  - `[!]` Yellow: Warning
  - `[i]` Blue: Info
- Progress messages for each major step
- Completion summary with quick-start commands

### File Logging

- Location: `{AI_HOME}/logs/installer.log`
- Format: `[LEVEL] message`
- Includes: timestamps, function names, variable values
- Useful for debugging and auditing installation history

## Generated Files & Directory Structure

After installation, `AI_HOME` contains:

```
/opt/darc-ai/
├── venv/                           # Python virtual environment
├── logs/
│   └── installer.log               # Installation log
├── config/
│   ├── config.json                 # Installation metadata
│   └── .env                        # Environment variables
├── scripts/
│   ├── ai_controller.py            # FastAPI server
│   └── darc-ai                     # CLI wrapper
├── models/                         # Ollama models directory
├── data/                           # Application data
└── temp/                           # Temporary files
```

## Generated Services & Scripts

### `ai_controller.py`

FastAPI server exposing REST API:

**Endpoints:**

- `GET /` — Returns framework info and status
- `GET /health` — Health check with Ollama status and available models
- `POST /chat` — Send message to AI model, get response

**Example:**

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, how are you?"}'
```

### `darc-ai` CLI Wrapper

Command-line interface for quick access:

**Commands:**

- `darc-ai chat "Your message"` — Send message to AI
- `darc-ai models` — List installed models
- `darc-ai status` — Check system status
- `darc-ai start` — Start AI controller
- `darc-ai stop` — Stop AI controller

**Example:**

```bash
darc-ai chat "What is the capital of France?"
darc-ai status
darc-ai models
```

### `darc-ai.service` (Systemd)

Auto-starts the AI controller on boot (if "system" component selected):

```bash
sudo systemctl start darc-ai
sudo systemctl status darc-ai
sudo systemctl enable darc-ai
```

## Idempotency & Safety

All operations are designed to be **idempotent** and **safe to re-run**:

- System packages: Checked before install; skipped if already present
- Python venv: Skipped if already exists
- Ollama: Idempotent install and enable/start
- Models: `ollama pull` is idempotent (no-op if model already present)
- Scripts: Overwritten cleanly if re-run (no conflicts)
- Config files: Rewritten with fresh metadata

**Dry-run mode** allows inspection of all intended commands before execution.

## Error Handling

- **Preflight failures** (disk, RAM, network) → Aborts with clear error message
- **Package installation failures** → Logs details and aborts
- **Ollama failures** → Logs warning but continues (user can retry manually)
- **User cancellation** → Exit code 130 (SIGINT)
- **General errors** → Exit code 1 with error message pointing to log file

All errors are logged to both console and file.

## Distro Support

Tested and working on:

- ✓ Ubuntu 20.04, 22.04, 24.04
- ✓ Debian 11, 12
- ✓ Fedora 38, 39
- ✓ Arch Linux
- ✓ openSUSE Tumbleweed

Package manager detection and installation is abstracted in `system.py`.

## Performance Notes

- **Total installation time**: 15-60 minutes (depends on models selected and internet speed)
- **Disk space required**: 15GB+ (for models and dependencies)
- **RAM required**: 6GB+ (8GB+ recommended)
- **Network**: Required for initial setup and model downloads

## Development & Testing

### Running Locally (Non-Root)

```bash
# Set custom AI_HOME to avoid permission issues
export AI_HOME=/tmp/darc-test

# Run dry-run test
python3 -m darc_installer.cli --dry-run --yes --verbose

# Run interactive test
python3 -m darc_installer.cli --yes
```

### Adding New Models

Edit `ui.py` and add to `MODELS` dictionary:

```python
MODELS = {
    "your-model:tag": {
        "size": 7.3,  # GB
        "description": "Your model description"
    },
    ...
}
```

### Adding New Components

Edit `ui.py` and add to `COMPONENTS` dictionary:

```python
COMPONENTS = {
    "your-component": {
        "description": "Your component description"
    },
    ...
}
```

Then update `create_systemd_service()` or other functions to handle the new component.

## Future Enhancements

- [ ] GPU detection and CUDA setup
- [ ] Multi-model parallel pulling
- [ ] Installer signature verification
- [ ] Rollback/uninstall capability
- [ ] Integration with package managers (deb, rpm, pacman)
- [ ] Health dashboard (web UI)
- [ ] Model auto-update mechanism
- [ ] Security hardening (SELinux, AppArmor contexts)

---

## Quick Reference

### Installation from Source

```bash
# Clone or download the repository
cd /path/to/DARC/day-2.1

# Make bootstrap.sh executable
chmod +x bin/bootstrap.sh

# Run installer (interactive)
sudo bin/bootstrap.sh

# Or run non-interactive
sudo bin/bootstrap.sh --yes

# Or run dry-run
sudo bin/bootstrap.sh --dry-run --verbose
```

### Accessing the Installation

```bash
# After installation completes
cd /opt/darc-ai

# Use the CLI
darc-ai chat "Hello AI"
darc-ai status

# Or use the FastAPI controller directly
curl http://localhost:8000/health

# Check logs
tail -f /opt/darc-ai/logs/installer.log
```

### Troubleshooting

```bash
# Check system compatibility
python3 -m darc_installer.cli --diagnose

# Run with verbose logging
sudo bin/bootstrap.sh --verbose

# Check installation log
cat /opt/darc-ai/logs/installer.log

# Test Ollama
ollama list
ollama pull mistral:7b-instruct
```

---

**Version:** 1.0.0  
**Created by:** D∆RC  
**Last Updated:** November 2025

For issues, bugs, or feature requests, please refer to the original bash script (`D∆RC Modular AI Installation Script.sh`) for reference implementation details.
