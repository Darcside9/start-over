"""System abstraction helpers: command runner, distro detection, package manager wrappers."""
import logging
import os
import shutil
import subprocess
from typing import List, Optional

logger = logging.getLogger(__name__)


class CmdResult:
    def __init__(self, returncode: int, stdout: str = "", stderr: str = ""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


def run_cmd(args: List[str], dry_run: bool = False, capture: bool = False, check: bool = True) -> Optional[CmdResult]:
    logger.debug("run_cmd: %s", args)
    if dry_run:
        logger.info("[dry-run] %s", " ".join(args))
        return None

    try:
        completed = subprocess.run(args, stdout=subprocess.PIPE if capture else None, stderr=subprocess.PIPE if capture else None, text=True)
        stdout = completed.stdout if capture else ""
        stderr = completed.stderr if capture else ""
        if check and completed.returncode != 0:
            logger.error("Command failed (%s): %s", completed.returncode, stderr)
            raise subprocess.CalledProcessError(completed.returncode, args, output=stdout, stderr=stderr)
        return CmdResult(completed.returncode, stdout, stderr)
    except FileNotFoundError as e:
        logger.error("Command not found: %s", args[0])
        raise


def which(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def detect_package_manager() -> Optional[str]:
    # Basic detection by files/commands
    if os.path.exists("/etc/debian_version") or which("apt-get"):
        return "apt"
    if which("dnf") or which("yum") or os.path.exists("/etc/redhat-release"):
        return "dnf"
    if which("pacman"):
        return "pacman"
    if which("zypper"):
        return "zypper"
    return None


def get_sys_info() -> dict:
    info = {
        "os_release": None,
        "kernel": None,
        "python": shutil.which("python3") or "",
    }
    try:
        if os.path.exists("/etc/os-release"):
            with open("/etc/os-release") as fh:
                info["os_release"] = fh.read().strip().splitlines()
    except Exception:
        logger.exception("Failed reading /etc/os-release")

    try:
        uname = run_cmd(["uname", "-sr"], capture=True, check=False)
        info["kernel"] = uname.stdout.strip() if uname else ""
    except Exception:
        info["kernel"] = ""

    return info


# Package operations (idempotent checks)

def is_package_installed_apt(pkg: str) -> bool:
    try:
        res = subprocess.run(["dpkg", "-s", pkg], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return res.returncode == 0
    except Exception:
        return False


def install_packages(packages: List[str], dry_run: bool = False) -> None:
    pm = detect_package_manager()
    logger.info("Detected package manager: %s", pm)
    if pm == "apt":
        # update and install
        run_cmd(["apt-get", "update"], dry_run=dry_run)
        cmd = ["apt-get", "install", "-y"] + packages
        run_cmd(cmd, dry_run=dry_run)
    elif pm == "dnf":
        cmd = ["dnf", "install", "-y"] + packages
        run_cmd(cmd, dry_run=dry_run)
    elif pm == "pacman":
        cmd = ["pacman", "-Syu", "--noconfirm"] + packages
        run_cmd(cmd, dry_run=dry_run)
    elif pm == "zypper":
        cmd = ["zypper", "--non-interactive", "install"] + packages
        run_cmd(cmd, dry_run=dry_run)
    else:
        raise RuntimeError("Unsupported or undetected package manager")


# service helpers

def systemctl_enable_start(service: str, dry_run: bool = False) -> None:
    run_cmd(["systemctl", "daemon-reload"], dry_run=dry_run)
    run_cmd(["systemctl", "enable", "--now", service], dry_run=dry_run)


def systemctl_status(service: str) -> bool:
    try:
        res = run_cmd(["systemctl", "is-active", "--quiet", service], dry_run=False, check=False)
        return res is not None and res.returncode == 0
    except Exception:
        return False
