"""High-level installer orchestration ported to Python."""
import logging
import os
import shutil
import sys
from pathlib import Path
from .system import install_packages, run_cmd

logger = logging.getLogger(__name__)

DEFAULT_AI_HOME = os.environ.get("AI_HOME", "/opt/darc-ai")


def preflight_checks():
    logger.info("Running preflight checks")
    # Simple checks: disk space, internet
    try:
        st = shutil.disk_usage("/")
        free_gb = st.free // (1024 ** 3)
        if free_gb < 15:
            raise RuntimeError(f"Insufficient disk space: {free_gb}GB")
        logger.info("Disk free: %s GB", free_gb)
    except Exception:
        logger.exception("Disk check failed")
        raise

    # Check internet
    try:
        res = run_cmd(["ping", "-c", "1", "8.8.8.8"], dry_run=False, check=False)
        if res is None or res.returncode != 0:
            raise RuntimeError("No network connectivity (ping failed)")
        logger.info("Network connectivity OK")
    except Exception:
        logger.exception("Network check failed")
        raise


def create_directories(ai_home: str = DEFAULT_AI_HOME):
    logger.info("Creating directories under %s", ai_home)
    p = Path(ai_home)
    dirs = [p, p / "logs", p / "models", p / "scripts", p / "data", p / "temp"]
    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)
    logger.info("Directories created")
    return p


def setup_python_venv(ai_home: str = DEFAULT_AI_HOME, dry_run: bool = False):
    venv_path = Path(ai_home) / "venv"
    if venv_path.exists():
        logger.info("Virtualenv already exists at %s", venv_path)
        return str(venv_path)
    logger.info("Creating virtualenv at %s", venv_path)
    run_cmd([sys.executable, "-m", "venv", str(venv_path)], dry_run=dry_run)
    # Upgrade pip and install a minimal set
    pip = str(venv_path / "bin" / "pip")
    run_cmd([pip, "install", "--upgrade", "pip", "setuptools", "wheel"], dry_run=dry_run)
    run_cmd([pip, "install", "fastapi", "uvicorn", "requests"], dry_run=dry_run)
    return str(venv_path)


def install_system_dependencies(dry_run: bool = False):
    pkgs = [
        "curl",
        "wget",
        "git",
        "python3",
        "python3-pip",
        "python3-venv",
        "redis-server",
        "jq",
        "pkg-config",
        "build-essential",
        "bc",
    ]
    install_packages(pkgs, dry_run=dry_run)


def write_example_scripts(ai_home: str = DEFAULT_AI_HOME):
    scripts_dir = Path(ai_home) / "scripts"
    scripts_dir.mkdir(parents=True, exist_ok=True)
    ai_controller = scripts_dir / "ai_controller.py"
    darc_cli = scripts_dir / "darc-ai"

    if not ai_controller.exists():
        ai_controller.write_text('#!/usr/bin/env python3\nprint("Darc AI controller placeholder")\n')
        ai_controller.chmod(0o755)
        logger.info("Wrote ai_controller.py")

    if not darc_cli.exists():
        darc_cli.write_text('#!/usr/bin/env bash\necho "darc-ai placeholder"\n')
        darc_cli.chmod(0o755)
        logger.info("Wrote darc-ai wrapper")


def run_install(dry_run: bool = False, assume_yes: bool = False):
    logger.info("Starting installation (dry_run=%s)" % dry_run)
    ai_home = os.environ.get("AI_HOME", DEFAULT_AI_HOME)

    preflight_checks()
    create_directories(ai_home)
    install_system_dependencies(dry_run=dry_run)
    setup_python_venv(ai_home, dry_run=dry_run)
    write_example_scripts(ai_home)

    logger.info("Installation complete (simulated in dry-run mode)" if dry_run else "Installation complete")
