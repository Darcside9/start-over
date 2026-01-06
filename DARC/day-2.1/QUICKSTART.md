# D∆RC AI Framework Installer - Quick Start Guide

## For a Fresh Linux System

### Prerequisites

- **OS**: Ubuntu, Debian, Fedora, Arch, or openSUSE
- **Privileges**: Root access (for `sudo`)
- **Network**: Internet connection for downloads
- **Disk**: 15GB free space
- **RAM**: 6GB minimum (8GB+ recommended)

---

## Installation Steps

### Step 1: Clone or Download the Installer

```bash
# If you have the files locally, navigate to the directory:
cd /path/to/DARC/day-2.1

# Or clone from Git (if available):
git clone <repo-url>
cd DARC/day-2.1
```

### Step 2: Make the Bootstrap Script Executable

```bash
chmod +x bin/bootstrap.sh
```

### Step 3: Run the Installer

#### Option A: Interactive Mode (Recommended for First-Time Users)

```bash
sudo bin/bootstrap.sh
```

You'll be prompted to:

- Select which AI models to install
- Choose which components to install
- Review the installation summary and confirm

#### Option B: Non-Interactive Mode (For Automation / CI/CD)

```bash
sudo bin/bootstrap.sh --yes
```

Auto-accepts all defaults:

- Installs recommended AI models (llama2:7b, mistral:7b-instruct)
- Installs core component only
- No prompts or user input required

#### Option C: Dry-Run Mode (Test Without Installing)

```bash
sudo bin/bootstrap.sh --dry-run --verbose
```

Prints all intended commands without executing them. Safe for:

- Testing on unfamiliar systems
- Validating that your system meets requirements
- CI/CD pipelines for validation

#### Option D: Diagnostic Mode (Troubleshooting)

```bash
sudo bin/bootstrap.sh --diagnose
```

Shows system information and exits:

- OS and distribution
- Available disk space and RAM
- Network connectivity
- Package manager detected

### Step 4: Monitor Installation Progress

The installer displays:

- ✓ Green checkmarks for successful steps
- ✗ Red errors if anything fails
- ℹ️ Blue info messages for current activity
- ⚠️ Yellow warnings for non-critical issues

Installation typically takes **15-60 minutes** depending on:

- Your internet speed (model downloads are large: 3.5-7GB+)
- System performance
- Number of models selected

### Step 5: After Installation Completes

Once the installer finishes, test your installation:

```bash
# Check installed models
darc-ai models

# Test the AI
darc-ai chat "Hello, what's your name?"

# Check system status
darc-ai status

# Start the FastAPI controller
darc-ai start

# Stop the controller
darc-ai stop
```

---

## What Gets Installed

After running the installer, you'll have:

```
/opt/darc-ai/
├── config/
│   ├── config.json              # Installation metadata
│   └── .env                     # Environment variables
├── logs/
│   └── installer.log            # Complete installation log
├── scripts/
│   ├── ai_controller.py         # FastAPI server
│   └── darc-ai                  # CLI command
├── venv/                        # Python virtual environment
├── models/                      # Ollama models
├── data/                        # Application data
└── temp/                        # Temporary files
```

Plus:

- **`/etc/systemd/system/darc-ai.service`** — Auto-starts AI controller on boot
- **`darc-ai`** command available system-wide via CLI

---

## Usage After Installation

### 1. Chat with AI

```bash
darc-ai chat "What is machine learning?"
```

### 2. Check Available Models

```bash
darc-ai models
```

### 3. View System Status

```bash
darc-ai status
```

Shows:

- Ollama connection status
- Available models
- API health

### 4. Use REST API Directly

```bash
# Get health status
curl http://localhost:8000/health

# Send a message to AI
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello, AI!"}'
```

### 5. View Installation Log

```bash
tail -f /opt/darc-ai/logs/installer.log
```

---

## Custom Installation Path

By default, everything installs to `/opt/darc-ai`. To use a different path:

```bash
export AI_HOME=/custom/path
sudo -E bin/bootstrap.sh
```

All files will be created under `/custom/path` instead.

---

## Troubleshooting

### Installation Fails with "Permission Denied"

Make sure you're using `sudo`:

```bash
sudo bin/bootstrap.sh
```

### "Python3 Not Found"

Install Python 3:

```bash
# Ubuntu/Debian
sudo apt-get install python3 python3-pip

# Fedora
sudo dnf install python3 python3-pip

# Arch
sudo pacman -S python

# openSUSE
sudo zypper install python3
```

### Network Issues During Download

Some models are large (3.5GB+). If the download times out:

```bash
# Re-run the installer to resume
sudo bin/bootstrap.sh

# Or check Ollama status directly
ollama list
```

### Ollama Fails to Start

Check if Ollama is running:

```bash
sudo systemctl status ollama
sudo systemctl start ollama
```

### Not Enough Disk Space

Check available disk:

```bash
df -h
```

You need at least 15GB free. Clear space and re-run:

```bash
sudo bin/bootstrap.sh
```

---

## Uninstall

To remove the installation:

```bash
# Stop the service
sudo systemctl stop darc-ai

# Remove the service
sudo rm /etc/systemd/system/darc-ai.service
sudo systemctl daemon-reload

# Remove the installation directory
sudo rm -rf /opt/darc-ai
```

---

## Advanced Options

### Verbose Logging

```bash
sudo bin/bootstrap.sh --verbose
```

Prints detailed logs to console for debugging.

### Debug Mode

```bash
sudo bin/bootstrap.sh --debug
```

Enables debug-level logging (very verbose).

### Combine Options

```bash
# Dry-run with verbose output
sudo bin/bootstrap.sh --dry-run --verbose

# Non-interactive with debug logging
sudo bin/bootstrap.sh --yes --debug

# Non-interactive dry-run
sudo bin/bootstrap.sh --dry-run --yes
```

---

## System Requirements Checklist

Before running the installer, verify:

- [ ] Linux OS (Ubuntu, Debian, Fedora, Arch, or openSUSE)
- [ ] Internet connection available
- [ ] 15GB+ free disk space (`df -h`)
- [ ] 6GB+ RAM (`free -h`)
- [ ] Root/sudo access
- [ ] Python 3.8+ installed (`python3 --version`)

Check all? Run the installer!

---

## Performance Tips

### Faster Downloads

- Use a wired connection (not WiFi) if possible
- Run during off-peak hours when ISP bandwidth is less congested
- Consider selecting fewer models on first install

### Faster Model Pulling

Models are downloaded in parallel when possible. Large models take time:

- llama2:7b — ~4GB (5-10 min on fast connection)
- mistral:7b-instruct — ~3.5GB (5-10 min on fast connection)

### Running on Low-RAM Systems

If you have less than 8GB RAM:

1. Install with fewer models in interactive mode
2. Don't run other applications during installation
3. Increase swap if available:
   ```bash
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

---

## Next Steps

After installation:

1. **Explore the AI**: Try different prompts with `darc-ai chat`
2. **Check the logs**: `cat /opt/darc-ai/logs/installer.log`
3. **Read full docs**: See `INSTALLER_DOCUMENTATION.md` for advanced features
4. **Integrate with your app**: Use the REST API at `http://localhost:8000`

---

## Support

If you encounter issues:

1. Run the diagnostic mode:

   ```bash
   python3 -m darc_installer.cli --diagnose
   ```

2. Check the installation log:

   ```bash
   tail -100 /opt/darc-ai/logs/installer.log
   ```

3. Review the full documentation:
   - `README.md` — Feature overview
   - `INSTALLER_DOCUMENTATION.md` — Technical reference
   - `COMPLETION_REPORT.md` — Project details

---

**Version**: 1.0.0  
**Created by**: D∆RC AI Framework Team  
**Last Updated**: November 25, 2025
