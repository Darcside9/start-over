D∆RC Hybrid Installer (Bash + Python)

This folder contains a hybrid installer skeleton designed for system-level integration on Linux.

Structure

- bin/bootstrap.sh - small Bash wrapper to ensure root and hand off to Python CLI
- darc_installer/ - Python package with CLI, system abstractions and installer orchestration
- requirements.txt - optional Python deps
- README_INSTALLER.md - this file

Quick start (development)

1. Make bootstrap executable:

```bash
chmod +x bin/bootstrap.sh
```

2. Run the bootstrap as root (it will call the Python CLI):

```bash
sudo ./bin/bootstrap.sh --dry-run
```

3. To run the installer for real, omit `--dry-run` and ensure you understand its actions.

Notes

- The Python code aims to be idempotent and provides `--dry-run` for safe verification.
- The initial implementation contains core helpers and a basic install flow; we will migrate more logic from the existing Bash script in iterative steps.

Next steps

- Add more system actions (ollama install, model pulls) into Python modules.
- Add tests and CI, add ShellCheck and flake8/black/mypy checks.
- Replace remaining bash functions with Python implementations incrementally.
