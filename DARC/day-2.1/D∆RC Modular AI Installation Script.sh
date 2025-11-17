#!/bin/bash
# D∆RC Modular AI Installation Script
# Created by D∆RC - Advanced AI Security Framework
# Version: 1.0.0

set -e

# Color definitions for UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

VERBOSE=false
TRACE=false

print_banner() {
	clear
	echo -e "${PURPLE}${BOLD}"
	echo "╔══════════════════════════════════════════════════════════════╗"
	echo "║            ${WHITE}D∆RC AI Framework${PURPLE}				 ║"
	echo "║      ${CYAN}Advanced Modular AI Installation${PURPLE}		 ║"
	echo "║                                                              ║"
	echo "║  			${WHITE}Created by D∆RC${PURPLE}				 ║"
	echo "║		${CYAN}Customizable AI Security Framework${PURPLE}		 ║"
	echo "╚══════════════════════════════════════════════════════════════╝"
	echo -e "${NC}"
	echo ""
}

print_section() {
	echo -e "${BLUE}${BOLD}▶ $1${NC}"
	echo -e "${BLUE}$(printf '=%.0s' {1..60})${NC}"
}

print_success() {
	echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
	echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
	echo -e "${RED}[✗]${NC} $1"
}

print_info() {
	echo -e "${CYAN}[i]${NC} $1"
}

check_system() {
	print_section "System Requirements Check"

	# Check OS
	if ! grep -q "Ubuntu" /etc/os-release; then
		print_warning "Non-Ubuntu system detected, proceeding anyway..."
	else
		print_success "Ubuntu system detected"
	fi

	# Check RAM
	RAM_GB=$(awk '/Mem:/ {printf "%.1f", $2/1024}' <(free -m))
	if (($(echo "$RAM_GB < 6" | bc -l))); then
		print_error "Minimum 6GB RAM required. Found: ${RAM_GB}GB"
		exit 1
	else
		print_success "RAM: ${RAM_GB}GB (sufficient)"
	fi

	# Check disk space
	DISK_FREE=$(df --output=avail -BG . | tail -1 | tr -d 'G ')
	if [ "$DISK_FREE" -lt 15 ]; then
		print_error "Minimum 15GB free space required. Found: ${DISK_FREE}GB"
		exit 1
	else
		print_success "Disk space: ${DISK_FREE}GB (sufficient)"
	fi

	# Check internet connection
	if ! ping -c 1 google.com &>/dev/null; then
		print_error "No internet connection available"
		exit 1
	else
		print_success "Internet connection available"
	fi

	echo ""
}

show_model_selection() {
	# CLI interactive selection
	print_section "AI Model Selection"
	print_info "Choose which AI models to install:"
	echo ""

	local selected_models=()
	local model_keys=($(printf '%s\n' "${!MODELS[@]}" | sort))

	# Show menu
	while true; do
		echo -e "${WHITE}Available Models:${NC}"
		echo ""

		local i=1
		for key in "${model_keys[@]}"; do
			IFS='|' read -ra info <<<"${MODELS[$key]}"
			local name="${info[0]}"
			local desc="${info[1]}"
			local size="${info[2]}"
			local tag="${info[3]}"

			# Color code by tag
			local color=$WHITE
			case $tag in
			"RECOMMENDED") color=$GREEN ;;
			"CODE") color=$CYAN ;;
			"FAST") color=$YELLOW ;;
			"AUDIO") color=$PURPLE ;;
			"VISION") color=$BLUE ;;
			esac

			# Check if selected
			local selected=""
			for sel in "${selected_models[@]}"; do
				if [[ "$sel" == "$key" ]]; then
					selected="[${GREEN}✓${NC}] "
					break
				fi
			done

			echo -e "  ${BOLD}$i)${NC} $selected${color}$name${NC}"
			echo -e "     $desc (${size}) ${BOLD}[$tag]${NC}"
			echo ""
			((i++))
		done

		echo -e "${WHITE}Selected models total size: $(calculate_total_size "${selected_models[@]}")${NC}"
		echo ""
		echo -e "${YELLOW}Options:${NC}"
		echo "  Enter number to toggle model"
		echo "  'r' - Auto-select recommended models"
		echo "  'c' - Clear all selections"
		echo "  'done' - Continue with selected models"
		echo "  'q' - Quit installer"
		echo ""

		read -p "Selection: " choice

		case $choice in
		'r' | 'R')
			selected_models=()
			for key in "${model_keys[@]}"; do
				IFS='|' read -ra info <<<"${MODELS[$key]}"
				if [[ "${info[3]}" == "RECOMMENDED" ]]; then
					selected_models+=("$key")
				fi
			done
			print_success "Recommended models selected"
			;;
		'c' | 'C')
			selected_models=()
			print_success "Selection cleared"
			;;
		'done' | 'DONE')
			if [[ ${#selected_models[@]} -eq 0 ]]; then
				print_warning "No models selected. At least one model is required."
				continue
			fi
			break
			;;
		'q' | 'Q')
			print_info "Installation cancelled"
			exit 0
			;;
		[0-9]*)
			if [[ $choice -ge 1 && $choice -le ${#model_keys[@]} ]]; then
				local selected_key="${model_keys[$((choice - 1))]}"

				# Toggle selection
				local found=false
				local new_selected=()
				for sel in "${selected_models[@]}"; do
					if [[ "$sel" == "$selected_key" ]]; then
						found=true
					else
						new_selected+=("$sel")
					fi
				done

				if [[ $found == false ]]; then
					new_selected+=("$selected_key")
				fi

				selected_models=("${new_selected[@]}")
			else
				print_error "Invalid selection"
			fi
			;;
		*)
			print_error "Invalid option"
			;;
		esac

		clear
		print_banner
	done

	# Store selected models globally
	SELECTED_MODELS=("${selected_models[@]}")
	echo ""
}

show_component_selection() {
	print_section "Component Selection"
	print_info "Choose which components to install:"
	echo ""

	local selected_components=()
	local component_keys=($(printf '%s\n' "${!COMPONENTS[@]}" | sort))

	# Core is always required
	selected_components+=("core")

	while true; do
		echo -e "${WHITE}Available Components:${NC}"
		echo ""

		local i=1
		for key in "${component_keys[@]}"; do
			IFS='|' read -ra info <<<"${COMPONENTS[$key]}"
			local name="${info[0]}"
			local desc="${info[1]}"
			local status="${info[2]}"

			# Check if selected
			local selected=""
			local color=$WHITE
			for sel in "${selected_components[@]}"; do
				if [[ "$sel" == "$key" ]]; then
					selected="[${GREEN}✓${NC}] "
					color=$GREEN
					break
				fi
			done

			if [[ "$status" == "REQUIRED" ]]; then
				selected="[${GREEN}✓${NC}] "
				color=$GREEN
			fi

			echo -e "  ${BOLD}$i)${NC} $selected${color}$name${NC}"
			echo -e "     $desc ${BOLD}[$status]${NC}"
			echo ""
			((i++))
		done

		echo -e "${YELLOW}Options:${NC}"
		echo "  Enter number to toggle component (except REQUIRED)"
		echo "  'a' - Select all components"
		echo "  'done' - Continue with selected components"
		echo "  'q' - Quit installer"
		echo ""

		read -p "Selection: " choice

		case $choice in
		'a' | 'A')
			selected_components=("${component_keys[@]}")
			print_success "All components selected"
			;;
		'done' | 'DONE')
			break
			;;
		'q' | 'Q')
			print_info "Installation cancelled"
			exit 0
			;;
		[0-9]*)
			if [[ $choice -ge 1 && $choice -le ${#component_keys[@]} ]]; then
				local selected_key="${component_keys[$((choice - 1))]}"

				# Skip if required
				IFS='|' read -ra info <<<"${COMPONENTS[$selected_key]}"
				if [[ "${info[2]}" == "REQUIRED" ]]; then
					print_warning "Core component is required and cannot be deselected"
					continue
				fi

				# Toggle selection
				local found=false
				local new_selected=()
				for sel in "${selected_components[@]}"; do
					if [[ "$sel" == "$selected_key" ]]; then
						found=true
					else
						new_selected+=("$sel")
					fi
				done

				if [[ $found == false ]]; then
					new_selected+=("$selected_key")
				fi

				selected_components=("${new_selected[@]}")
			else
				print_error "Invalid selection"
			fi
			;;
		*)
			print_error "Invalid option"
			;;
		esac

		clear
		print_banner
	done

	# Store selected components globally
	SELECTED_COMPONENTS=("${selected_components[@]}")
	echo ""
}

calculate_total_size() {
	local models=("$@")
	local total_mb=0

	for model in "${models[@]}"; do
		if [[ -n "${MODELS[$model]}" ]]; then
			IFS='|' read -ra info <<<"${MODELS[$model]}"
			local size="${info[2]}"

			if [[ $size == *"GB"* ]]; then
				local size_num=$(echo "$size" | sed 's/GB//')
				# Use bc for floating point multiplication, then round down
				local mb=$(echo "$size_num * 1024" | bc)
				total_mb=$(echo "$total_mb + $mb" | bc)
			elif [[ $size == *"MB"* ]]; then
				local size_num=$(echo "$size" | sed 's/MB//')
				total_mb=$(echo "$total_mb + $size_num" | bc)
			fi
		fi
	done

	# Convert to integer for display
	local total_mb_int=$(printf "%.0f" "$total_mb")
	if [[ $total_mb_int -gt 1024 ]]; then
		local total_gb=$(echo "scale=1; $total_mb/1024" | bc)
		echo "${total_gb}GB"
	else
		echo "${total_mb_int}MB"
	fi
}

show_installation_summary() {
	print_section "Installation Summary"

	echo -e "${WHITE}Selected Models:${NC}"
	for model in "${SELECTED_MODELS[@]}"; do
		if [[ -n "${MODELS[$model]}" ]]; then
			IFS='|' read -ra info <<<"${MODELS[$model]}"
			echo -e "  ${GREEN}•${NC} ${info[0]} (${info[2]})"
		fi
	done
	echo ""

	echo -e "${WHITE}Selected Components:${NC}"
	for component in "${SELECTED_COMPONENTS[@]}"; do
		if [[ -n "${COMPONENTS[$component]}" ]]; then
			IFS='|' read -ra info <<<"${COMPONENTS[$component]}"
			echo -e "  ${GREEN}•${NC} ${info[0]}"
		fi
	done
	echo ""

	echo -e "${WHITE}Total Download Size:${NC} $(calculate_total_size "${SELECTED_MODELS[@]}")"
	echo -e "${WHITE}Installation Directory:${NC} $AI_HOME"
	echo ""

	read -p "Proceed with installation? (y/N): " confirm
	if [[ ! $confirm =~ ^[Yy]$ ]]; then
		print_info "Installation cancelled"
		exit 0
	fi
	echo ""
}

create_directories() {
	print_section "Creating Directory Structure"

	mkdir -p "$AI_HOME"
	mkdir -p "$CONFIG_DIR"
	mkdir -p "$LOGS_DIR"
	mkdir -p "$MODELS_DIR"
	mkdir -p "$SCRIPTS_DIR"
	mkdir -p "$AI_HOME/data"
	mkdir -p "$AI_HOME/temp"

	print_success "Directory structure created"
	echo ""
}

install_system_dependencies() {
	print_section "Installing System Dependencies"

	print_info "Updating package lists..."
	if $VERBOSE; then
		sudo apt update
	else
		sudo apt update -qq 2>>"$LOGS_DIR/apt-update-error.log"
	fi

	print_info "Installing essential packages..."
	if $VERBOSE; then
		sudo apt install -y \
			curl wget git python3 python3-pip python3-venv redis-server jq pkg-config build-essential bc
	else
		sudo apt install -y \
			curl wget git python3 python3-pip python3-venv redis-server jq pkg-config build-essential bc >/dev/null 2>&1
	fi

	print_success "System dependencies installed"
	echo ""
}

install_python_environment() {
	print_section "Setting Up Python Environment"

	print_info "Creating Python virtual environment..."
	python3 -m venv "$AI_HOME/venv"

	print_info "Activating virtual environment..."
	source "$AI_HOME/venv/bin/activate"

	print_info "Installing core Python packages..."
	pip install --quiet --upgrade pip setuptools wheel
	pip install --quiet \
		fastapi[all] \
		uvicorn[standard] \
		requests \
		redis \
		python-dotenv \
		pydantic \
		rich \
		typer

	print_success "Python environment configured"
	echo ""
}

install_ollama() {
	print_section "Installing Ollama AI Runtime"

	print_info "Downloading and installing Ollama..."
	curl -fsSL https://ollama.ai/install.sh | sh >"$LOGS_DIR/ollama-install.log" 2>&1

	print_info "Starting Ollama service..."
	sudo systemctl enable ollama >/dev/null 2>&1
	sudo systemctl start ollama >/dev/null 2>&1

	# Wait for Ollama to be ready (adaptive wait up to 60 seconds)
	print_info "Waiting for Ollama to initialize..."
	local retries=0
	local max_retries=30
	while ! ollama list >/dev/null 2>&1 && [ $retries -lt $max_retries ]; do
		sleep 2
		((retries++))
		print_info "Ollama not ready yet... ($((retries * 2))s elapsed)"
	done

	if [ $retries -eq $max_retries ]; then
		print_error "Ollama failed to start properly after $((max_retries * 2)) seconds"
		exit 1
	fi

	print_success "Ollama installed and running"
	echo ""
}

install_selected_models() {
	print_section "Installing Selected AI Models"

	# CLI mode (no GUI)
	for model in "${SELECTED_MODELS[@]}"; do
		if [[ -n "${MODELS[$model]}" ]]; then
			IFS='|' read -ra info <<<"${MODELS[$model]}"
			local name="${info[0]}"
			local size="${info[2]}"

			print_info "Downloading $name ($size)..."

			# Show progress for large models
			if [[ $size == *"GB"* ]]; then
				ollama pull "$model" &
				local pid=$!

				# Simple progress indicator
				while kill -0 $pid 2>/dev/null; do
					echo -n "."
					sleep 2
				done
				echo ""
				wait $pid || print_warning "Model $name may have partial download - retry later"
			else
				if ollama pull "$model" >/dev/null 2>&1; then
					print_success "$name installed"
				else
					print_warning "Failed to install $name - check connection"
				fi
			fi
		fi
	done

	echo ""
}

install_core_component() {
	print_section "Installing Core AI System"

	# Create main AI controller script
	cat >"$SCRIPTS_DIR/ai_controller.py" <<'EOF'
#!/usr/bin/env python3
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
                # Test Ollama connection
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
                
                # Query Ollama
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
EOF

	chmod +x "$SCRIPTS_DIR/ai_controller.py"

	# Create command line interface
	cat >"$SCRIPTS_DIR/darc-ai" <<'EOF'
#!/bin/bash
# D∆RC AI Command Line Interface

AI_HOME="$HOME/.darc-ai"
source "$AI_HOME/venv/bin/activate"

OLLAMA_URL="http://localhost:11434"
API_URL="http://localhost:8000"

case "$1" in
    "chat"|"c")
        if [ -z "$2" ]; then
            echo "Usage: darc-ai chat \"your message\""
            exit 1
        fi
        
        # Shift to get the full message
        shift
        message="$*"
        
        curl -s -X POST "$API_URL/chat" \
            -H "Content-Type: application/json" \
            -d "{\"message\": \"$message\"}" | jq -r '.response'
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
        echo "  darc-ai chat \"Hello, how are you?\""
        echo "  darc-ai status"
        echo "  darc-ai models"
        ;;
esac
EOF

	chmod +x "$SCRIPTS_DIR/darc-ai"

	# Add to PATH
	# Add to PATH only if not already present
	if ! grep -q "export PATH=\"$SCRIPTS_DIR:\$PATH\"" ~/.bashrc; then
		echo "export PATH=\"$SCRIPTS_DIR:\$PATH\"" >>~/.bashrc
	fi
	print_success "Core AI system installed"
	echo ""
}

install_additional_components() {
	print_section "Installing Additional Components"

	for component in "${SELECTED_COMPONENTS[@]}"; do
		case $component in
		"security")
			print_info "Installing security framework..."
			source "$AI_HOME/venv/bin/activate"
			pip install --quiet transformers datasets torch
			mkdir -p "$AI_HOME/security-training"
			print_success "Security framework installed"
			;;
		"vision")
			print_info "Installing vision processing..."
			source "$AI_HOME/venv/bin/activate"
			pip install --quiet pillow opencv-python
			print_success "Vision processing installed"
			;;
		"audio")
			print_info "Installing audio processing..."
			source "$AI_HOME/venv/bin/activate"
			pip install --quiet soundfile
			print_success "Audio processing installed"
			;;
		"system")
			print_info "Installing system integration..."
			# Create desktop shortcut
			mkdir -p "$HOME/.local/share/applications"
			cat >"$HOME/.local/share/applications/darc-ai.desktop" <<EOF
[Desktop Entry]
Name=D∆RC AI
Comment=Advanced AI Framework by D∆RC
Exec=$AI_HOME/scripts/darc-ai chat
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Development;Utility;
EOF
			print_success "System integration installed (desktop shortcut created)"
			;;
		"training")
			print_info "Installing training tools..."
			source "$AI_HOME/venv/bin/activate"
			pip install --quiet transformers datasets torch peft
			print_success "Training tools installed"
			;;
		esac
		echo ""
	done
}

create_config_files() {
	print_section "Creating Configuration Files"

	# Main configuration
	local models_json=$(printf '%s\n' "${SELECTED_MODELS[@]}" | jq -R . | jq -s .)
	local components_json=$(printf '%s\n' "${SELECTED_COMPONENTS[@]}" | jq -R . | jq -s .)

	cat >"$CONFIG_DIR/config.json" <<EOF
{
    "version": "1.0.0",
    "created_by": "D∆RC",
    "installation_date": "$(date -I)",
    "ai_home": "$AI_HOME",
    "ollama_url": "http://localhost:11434",
    "api_port": 8000,
    "default_model": "${SELECTED_MODELS[0]}",
    "installed_models": $models_json,
    "installed_components": $components_json
}
EOF

	# Environment file
	cat >"$CONFIG_DIR/.env" <<EOF
# D∆RC AI Framework Configuration
AI_HOME=$AI_HOME
OLLAMA_URL=http://localhost:11434
API_PORT=8000
DEFAULT_MODEL=${SELECTED_MODELS[0]}
LOG_LEVEL=INFO
EOF

	print_success "Configuration files created"
	echo ""
}

create_startup_service() {
	print_section "Setting Up Startup Service"

	if [[ " ${SELECTED_COMPONENTS[*]} " == *" system "* ]]; then
		print_info "Creating systemd service for auto-start..."

		# Create systemd service
		sudo tee /etc/systemd/system/darc-ai.service >/dev/null <<EOF
[Unit]
Description=D∆RC AI Framework Controller
After=network.target ollama.service
Requires=ollama.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$AI_HOME
Environment="PATH=$AI_HOME/venv/bin:$PATH"
Environment="VIRTUAL_ENV=$AI_HOME/venv"
ExecStart=$AI_HOME/venv/bin/python $AI_HOME/scripts/ai_controller.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

		sudo systemctl daemon-reload
		sudo systemctl enable darc-ai >/dev/null 2>&1

		print_success "System service created and enabled (auto-start on boot)"
		echo -e "  • ${CYAN}sudo systemctl start darc-ai${NC} - Start service manually"
		echo -e "  • ${CYAN}sudo systemctl status darc-ai${NC} - Check status"
	else
		print_info "System component not selected - no systemd service created"
	fi
	echo ""
}

run_final_tests() {
	print_section "Running System Tests"

	# Test Ollama
	print_info "Testing Ollama connection..."
	if ollama list >/dev/null 2>&1; then
		print_success "Ollama: Working"
	else
		print_error "Ollama: Failed"
	fi

	print_info "Testing Python environment..."
	if source "$AI_HOME/venv/bin/activate" && python3 -c "import fastapi, requests, uvicorn, redis, python_dotenv, pydantic, rich, typer" 2>/dev/null; then
		print_success "Python environment: Working"
	else
		print_error "Python environment: Failed"
	fi

	# Test models
	if [[ ${#SELECTED_MODELS[@]} -gt 0 ]]; then
		print_info "Testing installed models..."
		local test_model="${SELECTED_MODELS[0]}"
		if ollama run "$test_model" "Hello" --verbose=false 2>/dev/null | grep -q "."; then
			print_success "Model $test_model: Working"
		else
			print_warning "Model $test_model: May need initialization"
		fi
	fi

	echo ""
}

show_completion_message() {
	print_section "Installation Complete!"

	echo -e "${GREEN}${BOLD}🎉 D∆RC AI Framework successfully installed!${NC}"
	echo ""

	echo -e "${WHITE}Installation Summary:${NC}"
	echo -e "  • Installation directory: ${CYAN}$AI_HOME${NC}"
	echo -e "  • Models installed: ${#SELECTED_MODELS[@]}"
	echo -e "  • Components installed: ${#SELECTED_COMPONENTS[@]}"
	echo -e "  • Total size: $(calculate_total_size "${SELECTED_MODELS[@]}")"
	echo ""

	echo -e "${WHITE}Quick Start Commands:${NC}"
	echo -e "  ${CYAN}darc-ai chat \"Hello AI\"${NC}     - Chat with AI"
	echo -e "  ${CYAN}darc-ai status${NC}              - Check system status"
	echo -e "  ${CYAN}darc-ai models${NC}              - List available models"
	echo -e "  ${CYAN}darc-ai start${NC}               - Start AI controller"
	echo ""

	echo -e "${WHITE}API Endpoints:${NC}"
	echo -e "  • Health check: ${CYAN}curl http://localhost:8000/health${NC}"
	echo -e "  • Chat API: ${CYAN}curl -X POST http://localhost:8000/chat -H \"Content-Type: application/json\" -d '{\"message\":\"Hello\"}' | jq .response${NC}"
	echo ""

	echo -e "${WHITE}Configuration:${NC}"
	echo -e "  • Config file: ${CYAN}$CONFIG_DIR/config.json${NC}"
	echo -e "  • Environment: ${CYAN}$CONFIG_DIR/.env${NC}"
	echo -e "  • Logs: ${CYAN}$LOGS_DIR/${NC}"
	echo ""

	echo -e "${YELLOW}Important Notes:${NC}"
	echo -e "  • Run ${CYAN}source ~/.bashrc${NC} or restart terminal to use darc-ai command"
	echo -e "  • First model usage may take a few seconds to initialize"

	if [[ " ${SELECTED_COMPONENTS[*]} " == *" system "* ]]; then
		echo -e "  • System service: ${CYAN}sudo systemctl start darc-ai${NC} (auto-starts on boot)"
	fi

	if [[ " ${SELECTED_COMPONENTS[*]} " == *" security "* ]]; then
		echo -e "  • Security framework available in ${CYAN}$AI_HOME/security-training/${NC}"
		echo -e "  • ${RED}Always ensure proper authorization before using security tools${NC}"
	fi

	echo ""
	echo -e "${PURPLE}${BOLD}Created by D∆RC - Advanced AI Framework${NC}"
	echo -e "${CYAN}Thank you for using D∆RC AI Framework!${NC}"
	echo ""

	# Offer to start the system
	read -p "Start D∆RC AI Controller now? (Y/n): " start_now
	if [[ ! $start_now =~ ^[Nn]$ ]]; then
		echo ""
		print_info "Starting D∆RC AI Controller..."
		source "$AI_HOME/venv/bin/activate"
		python3 "$AI_HOME/scripts/ai_controller.py" >"$LOGS_DIR/controller.log" 2>&1 &
		sleep 3

		if curl -s http://localhost:8000/health >/dev/null 2>&1; then
			print_success "D∆RC AI Controller started successfully!"
			echo -e "  • Web interface: ${CYAN}http://localhost:8000${NC}"
			echo -e "  • Try: ${CYAN}darc-ai chat \"Hello, are you working?\"${NC}"
		else
			print_warning "Controller may still be starting. Check logs: $LOGS_DIR/controller.log"
		fi
	fi

	echo ""
}

handle_error() {
	local exit_code=$1
	print_error "Installation failed with exit code $exit_code"
	print_info "Check logs for details: $LOGS_DIR/install.log"

	# Cleanup on failure
	read -p "Remove partial installation? (y/N): " cleanup
	if [[ $cleanup =~ ^[Yy]$ ]]; then
		echo -e "${RED}${BOLD}Warning:${NC} This will permanently delete all files in $AI_HOME, including any user data or models."
		read -p "Are you sure you want to proceed? (type 'DELETE' to confirm): " confirm_delete
		if [[ $confirm_delete == "DELETE" ]]; then
			print_info "Cleaning up..."
			rm -rf "$AI_HOME"
			print_success "Cleanup completed"
		else
			print_info "Cleanup aborted."
		fi
	fi

	exit $exit_code
}

main() {
	# Set up error handling
	trap 'handle_error $?' ERR

	# Create logs directory early
	mkdir -p "$LOGS_DIR"
	exec 1> >(tee -a "$LOGS_DIR/install.log")
	exec 2> >(tee -a "$LOGS_DIR/install.log" >&2)

	print_banner

	# Pre-flight checks
	check_system

	# Interactive selections
	show_model_selection
	show_component_selection
	show_installation_summary

	# Prepare installation environment
	create_directories
	install_system_dependencies
	install_python_environment
	install_ollama

	# Install models and components
	install_selected_models
	install_core_component
	install_additional_components

	# Finalize
	create_config_files
	create_startup_service
	run_final_tests
	show_completion_message
}

# Command line argument handling
case "${1:-}" in
--help | -h | help)
	show_help
	exit 0
	;;
--version | -v | version)
	echo "D∆RC AI Framework Installer v1.0.0"
	echo "Created by D∆RC"
	exit 0
	;;
--verbose)
	VERBOSE=true
	shift
	;;
--trace)
	TRACE=true
	shift
	;;
*) ;;
esac

main "$@"
