"""High-level installer orchestration ported to Python."""
import json
import logging
import os
import shutil
import sys
import time
from datetime import datetime
from pathlib import Path
from .system import install_packages, run_cmd, systemctl_enable_start
from .ui import (
    print_banner,
    print_section,
    print_success,
    print_warning,
    print_error,
    print_info,
    select_models,
    select_components,
    show_installation_summary,
    calculate_total_size,
    MODELS,
    COMPONENTS,
)
from .ollama import install_ollama, pull_models

logger = logging.getLogger(__name__)

DEFAULT_AI_HOME = os.environ.get("AI_HOME", "/opt/darc-ai")


def setup_logging(ai_home: str = DEFAULT_AI_HOME):
    """Configure logging to both console and file."""
    logs_dir = Path(ai_home) / "logs"
    logs_dir.mkdir(parents=True, exist_ok=True)
    log_file = logs_dir / "installer.log"

    # Add file handler to root logger
    file_handler = logging.FileHandler(str(log_file), mode="a")
    file_handler.setFormatter(logging.Formatter("[%(levelname)s] %(message)s"))
    logging.getLogger().addHandler(file_handler)
    logger.info("Logging initialized to %s", log_file)
    return log_file


def preflight_checks():
    """Check system requirements: disk space, RAM, network."""
    print_section("System Requirements Check")

    logger.info("Running preflight checks")

    # Check disk space
    try:
        st = shutil.disk_usage("/")
        free_gb = st.free // (1024 ** 3)
        if free_gb < 15:
            raise RuntimeError(f"Insufficient disk space: {free_gb}GB (need 15GB)")
        logger.info("Disk free: %s GB", free_gb)
        print_success(f"Disk space: {free_gb}GB (sufficient)")
    except Exception as e:
        logger.exception("Disk check failed: %s", e)
        print_error(f"Disk check failed: {e}")
        raise

    # Check RAM
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    mem_kb = int(line.split()[1])
                    mem_gb = mem_kb / (1024 ** 2)
                    if mem_gb < 6:
                        raise RuntimeError(f"Insufficient RAM: {mem_gb:.1f}GB (need 6GB)")
                    logger.info("RAM: %.1f GB", mem_gb)
                    print_success(f"RAM: {mem_gb:.1f}GB (sufficient)")
                    break
    except Exception as e:
        logger.warning("RAM check failed (non-fatal): %s", e)
        print_warning(f"RAM check failed (non-fatal): {e}")

    # Check network
    try:
        res = run_cmd(["ping", "-c", "1", "8.8.8.8"], dry_run=False, check=False)
        if res is None or res.returncode != 0:
            raise RuntimeError("No network connectivity")
        logger.info("Network connectivity OK")
        print_success("Internet connection available")
    except Exception as e:
        logger.error("Network check failed: %s", e)
        print_error(f"Network check failed: {e}")
        raise

    print()


def create_directories(ai_home: str = DEFAULT_AI_HOME):
    """Create directory structure under AI_HOME."""
    print_section("Creating Directory Structure")
    logger.info("Creating directories under %s", ai_home)

    p = Path(ai_home)
    dirs = [
        p,
        p / "logs",
        p / "models",
        p / "scripts",
        p / "config",
        p / "data",
        p / "temp",
    ]
    for d in dirs:
        d.mkdir(parents=True, exist_ok=True)
        logger.debug("Created directory: %s", d)

    logger.info("Directories created")
    print_success("Directory structure created")
    print()


def install_system_dependencies(dry_run: bool = False):
    """Install system packages required by D∆RC."""
    print_section("Installing System Dependencies")

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
    logger.info("Installing packages: %s", pkgs)
    print_info("Updating package lists and installing dependencies...")

    try:
        install_packages(pkgs, dry_run=dry_run)
        print_success("System dependencies installed")
    except Exception as e:
        logger.exception("Failed to install dependencies: %s", e)
        print_error(f"Failed to install dependencies: {e}")
        raise

    print()


def setup_python_venv(ai_home: str = DEFAULT_AI_HOME, dry_run: bool = False):
    """Create and configure Python virtual environment."""
    print_section("Setting Up Python Environment")

    venv_path = Path(ai_home) / "venv"
    if venv_path.exists():
        logger.info("Virtualenv already exists at %s", venv_path)
        print_success("Python virtualenv already exists")
        print()
        return str(venv_path)

    logger.info("Creating virtualenv at %s", venv_path)
    print_info("Creating Python virtual environment...")

    try:
        run_cmd([sys.executable, "-m", "venv", str(venv_path)], dry_run=dry_run)
        
        if not dry_run:
            # Upgrade pip and install core packages
            pip = str(venv_path / "bin" / "pip")
            print_info("Installing core Python packages...")
            run_cmd([pip, "install", "--upgrade", "pip", "setuptools", "wheel"], dry_run=dry_run)
            run_cmd(
                [
                    pip,
                    "install",
                    "fastapi[all]",
                    "uvicorn[standard]",
                    "requests",
                    "redis",
                    "python-dotenv",
                    "pydantic",
                    "rich",
                    "typer",
                ],
                dry_run=dry_run,
            )

        print_success("Python environment configured")
    except Exception as e:
        logger.exception("Failed to setup Python environment: %s", e)
        print_error(f"Failed to setup Python environment: {e}")
        raise

    print()
    return str(venv_path)


def write_ai_controller(scripts_dir: Path):
    """Write the FastAPI controller script."""
    controller_path = scripts_dir / "ai_controller.py"

    if controller_path.exists():
        logger.debug("ai_controller.py already exists")
        return

    controller_code = '''#!/usr/bin/env python3
"""
D∆RC AI System Controller
Modular AI framework for security and general tasks
"""

import asyncio
import logging
from datetime import datetime
from pathlib import Path
from typing import Optional

import requests
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# Configuration
CONFIG = {
    "ollama_url": "http://localhost:11434",
    "default_model": "mistral:7b-instruct",
    "max_tokens": 2000,
    "temperature": 0.7
}

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ChatRequest(BaseModel):
    message: str
    model: Optional[str] = None
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 2000

class DArcAI:
    def __init__(self):
        self.app = FastAPI(
            title="D∆RC AI Controller",
            description="Advanced AI Framework by D∆RC",
            version="1.0.0"
        )
        self.setup_cors()
        self.setup_routes()
    
    def setup_cors(self):
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )
    
    def setup_routes(self):
        @self.app.get("/")
        async def root():
            return {
                "message": "D∆RC AI Framework",
                "version": "1.0.0",
                "status": "operational",
                "timestamp": datetime.now().isoformat()
            }
        
        @self.app.get("/health")
        async def health():
            try:
                response = requests.get(f"{CONFIG['ollama_url']}/api/tags", timeout=5)
                if response.status_code == 200:
                    models = [m["name"] for m in response.json().get("models", [])]
                    return {
                        "status": "healthy",
                        "ollama": "connected",
                        "available_models": models,
                        "timestamp": datetime.now().isoformat()
                    }
                else:
                    return {"status": "degraded", "ollama": "disconnected"}
            except Exception as e:
                return {"status": "unhealthy", "error": str(e)}
        
        @self.app.post("/chat")
        async def chat(request: ChatRequest):
            try:
                model = request.model or CONFIG["default_model"]
                
                response = requests.post(
                    f"{CONFIG['ollama_url']}/api/generate",
                    json={
                        "model": model,
                        "prompt": request.message,
                        "stream": False,
                        "options": {
                            "temperature": request.temperature,
                            "num_predict": request.max_tokens
                        }
                    },
                    timeout=120
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return {
                        "response": result["response"],
                        "model": model,
                        "timestamp": datetime.now().isoformat()
                    }
                else:
                    raise HTTPException(status_code=500, detail="Ollama request failed")
            
            except Exception as e:
                logger.error(f"Chat error: {e}")
                raise HTTPException(status_code=500, detail=str(e))
    
    def run(self, host="127.0.0.1", port=8000):
        uvicorn.run(self.app, host=host, port=port, log_level="info")

if __name__ == "__main__":
    ai = DArcAI()
    ai.run(host="0.0.0.0", port=8000)
'''

    controller_path.write_text(controller_code)
    controller_path.chmod(0o755)
    logger.info("Wrote ai_controller.py")


def write_darc_cli(scripts_dir: Path, ai_home: str):
    """Write the darc-ai CLI wrapper script."""
    cli_path = scripts_dir / "darc-ai"

    if cli_path.exists():
        logger.debug("darc-ai CLI already exists")
        return

    cli_code = f'''#!/bin/bash
# D∆RC AI Command Line Interface

AI_HOME="{ai_home}"
source "$AI_HOME/venv/bin/activate"

OLLAMA_URL="http://localhost:11434"
API_URL="http://localhost:8000"

case "${{1:-}}" in
    "chat"|"c")
        if [ -z "$2" ]; then
            echo "Usage: darc-ai chat \\"your message\\""
            exit 1
        fi
        
        shift
        message="$*"
        
        curl -s -X POST "$API_URL/chat" \\
            -H "Content-Type: application/json" \\
            -d "{{\\"message\\": \\"$message\\"}}" | jq -r '.response'
        ;;
    
    "models"|"m")
        echo "Available models:"
        ollama list
        ;;
    
    "status"|"s")
        echo "D∆RC AI System Status"
        echo "===================="
        curl -s "$API_URL/health" | jq .
        ;;
    
    "start")
        echo "Starting D∆RC AI Controller..."
        python3 "$AI_HOME/scripts/ai_controller.py" &
        echo "AI Controller started on http://localhost:8000"
        ;;
    
    "stop")
        echo "Stopping D∆RC AI Controller..."
        pkill -f "ai_controller.py"
        echo "AI Controller stopped"
        ;;
    
    *)
        echo "D∆RC AI Framework - Command Line Interface"
        echo "Created by D∆RC"
        echo ""
        echo "Usage: darc-ai <command> [options]"
        echo ""
        echo "Commands:"
        echo "  chat, c <message>    - Chat with AI"
        echo "  models, m           - List available models"
        echo "  status, s           - Check system status"
        echo "  start               - Start AI controller"
        echo "  stop                - Stop AI controller"
        echo ""
        echo "Examples:"
        echo "  darc-ai chat \\"Hello, how are you?\\""
        echo "  darc-ai status"
        echo "  darc-ai models"
        ;;
esac
'''

    cli_path.write_text(cli_code)
    cli_path.chmod(0o755)
    logger.info("Wrote darc-ai CLI wrapper")


def write_core_scripts(ai_home: str = DEFAULT_AI_HOME):
    """Write ai_controller.py and darc-ai CLI."""
    print_section("Installing Core AI System")

    scripts_dir = Path(ai_home) / "scripts"
    scripts_dir.mkdir(parents=True, exist_ok=True)

    print_info("Writing AI controller and CLI...")
    write_ai_controller(scripts_dir)
    write_darc_cli(scripts_dir, ai_home)

    print_success("Core AI system installed")
    print()


def create_config_files(ai_home: str, models: list, components: list):
    """Create config.json and .env files."""
    print_section("Creating Configuration Files")

    config_dir = Path(ai_home) / "config"
    config_dir.mkdir(parents=True, exist_ok=True)

    # Create config.json
    config_data = {
        "version": "1.0.0",
        "created_by": "D∆RC",
        "installation_date": datetime.now().isoformat(),
        "ai_home": ai_home,
        "ollama_url": "http://localhost:11434",
        "api_port": 8000,
        "default_model": models[0] if models else "mistral:7b-instruct",
        "installed_models": models,
        "installed_components": components,
    }

    config_file = config_dir / "config.json"
    config_file.write_text(json.dumps(config_data, indent=2))
    logger.info("Created config.json")

    # Create .env
    env_content = f"""# D∆RC AI Framework Configuration
AI_HOME={ai_home}
OLLAMA_URL=http://localhost:11434
API_PORT=8000
DEFAULT_MODEL={models[0] if models else "mistral:7b-instruct"}
LOG_LEVEL=INFO
"""
    env_file = config_dir / ".env"
    env_file.write_text(env_content)
    logger.info("Created .env file")

    print_success("Configuration files created")
    print()


def create_systemd_service(ai_home: str, components: list, dry_run: bool = False):
    """Create systemd service for auto-start."""
    if "system" not in components:
        logger.info("System component not selected - skipping systemd service")
        print_info("System component not selected - no systemd service created")
        print()
        return

    print_section("Setting Up Startup Service")

    print_info("Creating systemd service for auto-start...")

    service_content = f"""[Unit]
Description=D∆RC AI Framework Controller
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory={ai_home}
Environment="PATH={ai_home}/venv/bin:$PATH"
Environment="VIRTUAL_ENV={ai_home}/venv"
ExecStart={ai_home}/venv/bin/python {ai_home}/scripts/ai_controller.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
"""

    try:
        if dry_run:
            logger.info("[dry-run] Would write systemd service at /etc/systemd/system/darc-ai.service")
            logger.debug("Service content: %s", service_content)
        else:
            service_file = Path("/etc/systemd/system/darc-ai.service")
            service_file.write_text(service_content)
            systemctl_enable_start("darc-ai", dry_run=False)
            logger.info("Systemd service created and enabled")

        print_success("System service created and enabled (auto-start on boot)")
        print(f"  • Use 'sudo systemctl start darc-ai' to start manually")
        print(f"  • Use 'sudo systemctl status darc-ai' to check status")
    except Exception as e:
        logger.warning("Failed to create systemd service: %s", e)
        print_warning(f"Failed to create systemd service: {e}")

    print()


def run_final_tests(dry_run: bool = False):
    """Run final system tests."""
    if dry_run:
        logger.info("[dry-run] Skipping final tests")
        return

    print_section("Running System Tests")

    # Test Ollama
    print_info("Testing Ollama connection...")
    try:
        res = run_cmd(["ollama", "list"], dry_run=False, capture=True, check=False)
        if res and res.returncode == 0:
            print_success("Ollama: Working")
            logger.info("Ollama test passed")
        else:
            print_warning("Ollama: Connection failed")
            logger.warning("Ollama test failed")
    except Exception:
        print_warning("Ollama: Not available")
        logger.warning("Ollama not available")

    print()


def run_install(dry_run: bool = False, assume_yes: bool = False):
    """Main installer orchestration."""
    ai_home = os.environ.get("AI_HOME", DEFAULT_AI_HOME)

    print_banner()

    # Setup logging
    log_file = setup_logging(ai_home)

    logger.info("=" * 60)
    logger.info("Starting D∆RC AI Framework installation (dry_run=%s)", dry_run)
    logger.info("AI_HOME: %s", ai_home)
    logger.info("=" * 60)

    try:
        # Pre-flight checks
        preflight_checks()

        # Interactive selections
        print_banner()
        selected_models = select_models(assume_yes=assume_yes)
        selected_components = select_components(assume_yes=assume_yes)

        # Installation summary
        print_banner()
        if not show_installation_summary(selected_models, selected_components, ai_home, assume_yes=assume_yes):
            logger.info("Installation cancelled by user")
            sys.exit(0)

        # Prepare installation environment
        create_directories(ai_home)
        install_system_dependencies(dry_run=dry_run)
        setup_python_venv(ai_home, dry_run=dry_run)

        # Install Ollama and models
        install_ollama(dry_run=dry_run)
        pull_models(selected_models, dry_run=dry_run)

        # Install core system and components
        write_core_scripts(ai_home)

        # Finalize
        create_config_files(ai_home, selected_models, selected_components)
        create_systemd_service(ai_home, selected_components, dry_run=dry_run)
        run_final_tests(dry_run=dry_run)

        # Success message
        print_section("Installation Complete!")
        print_success("D∆RC AI Framework successfully installed!")
        print()
        print(f"Installation directory: {ai_home}")
        print(f"Models installed: {len(selected_models)}")
        print(f"Components installed: {len(selected_components)}")
        print(f"Total size: {calculate_total_size(selected_models)}")
        print()
        print("Quick start commands:")
        print(f"  darc-ai chat \"Hello AI\"")
        print(f"  darc-ai status")
        print(f"  darc-ai models")
        print()

        logger.info("Installation completed successfully (dry_run=%s)", dry_run)

    except KeyboardInterrupt:
        logger.warning("Installation interrupted by user")
        print_warning("Installation interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.exception("Installation failed: %s", e)
        print_error(f"Installation failed: {e}")
        print_info(f"Check logs for details: {log_file}")
        sys.exit(1)
