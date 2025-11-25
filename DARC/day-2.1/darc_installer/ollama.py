"""Ollama installation and model management."""
import logging
import time
from pathlib import Path
from .system import run_cmd, systemctl_enable_start
from .ui import print_info, print_success, print_warning, print_error

logger = logging.getLogger(__name__)


def is_ollama_installed() -> bool:
    """Check if Ollama is already installed."""
    try:
        result = run_cmd(["which", "ollama"], dry_run=False, capture=True, check=False)
        return result is not None and result.returncode == 0
    except Exception:
        return False


def install_ollama(dry_run: bool = False) -> None:
    """Download and install Ollama."""
    if is_ollama_installed():
        logger.info("Ollama already installed")
        print_success("Ollama already installed")
        return

    logger.info("Installing Ollama")
    print_info("Downloading and installing Ollama...")

    # Download and run Ollama install script
    cmd = [
        "sh",
        "-c",
        "curl -fsSL https://ollama.ai/install.sh | sh",
    ]
    try:
        run_cmd(cmd, dry_run=dry_run)
    except Exception as e:
        logger.exception("Ollama installation failed: %s", e)
        raise

    if not dry_run:
        # Enable and start service
        print_info("Starting Ollama service...")
        try:
            systemctl_enable_start("ollama", dry_run=dry_run)
        except Exception as e:
            logger.warning("Failed to enable/start ollama service: %s", e)
            raise

        # Wait for Ollama to be ready (adaptive wait up to 60 seconds)
        print_info("Waiting for Ollama to initialize...")
        max_retries = 30
        for attempt in range(max_retries):
            try:
                result = run_cmd(["ollama", "list"], dry_run=False, capture=True, check=False)
                if result and result.returncode == 0:
                    print_success("Ollama installed and running")
                    return
            except Exception:
                pass
            time.sleep(2)
            print_info(f"Ollama not ready yet... ({(attempt + 1) * 2}s elapsed)")

        logger.error("Ollama failed to start after 60 seconds")
        raise RuntimeError("Ollama failed to start properly after 60 seconds")


def pull_model(model: str, model_name: str = "", dry_run: bool = False) -> None:
    """Pull a single model from Ollama."""
    if not model_name:
        model_name = model

    logger.info("Pulling model: %s", model)
    print_info(f"Downloading {model_name}...")

    try:
        cmd = ["ollama", "pull", model]
        run_cmd(cmd, dry_run=dry_run)
        print_success(f"{model_name} installed")
    except Exception as e:
        logger.warning("Failed to pull model %s: %s", model, e)
        print_warning(f"Failed to install {model_name} - check connection and retry later")


def pull_models(models: list, dry_run: bool = False) -> None:
    """Pull all selected models."""
    for model_key in models:
        # For simplicity, use the model_key directly (it's the Ollama model name)
        pull_model(model_key, model_key, dry_run=dry_run)


def get_installed_models(dry_run: bool = False) -> list:
    """Get list of installed models."""
    if dry_run:
        return []
    try:
        result = run_cmd(["ollama", "list"], dry_run=False, capture=True, check=False)
        if result and result.returncode == 0:
            lines = result.stdout.strip().split("\n")
            # Skip header, extract model names
            models = []
            for line in lines[1:]:
                if line.strip():
                    parts = line.split()
                    if parts:
                        models.append(parts[0])
            return models
    except Exception:
        pass
    return []
