"""UI helpers: colored output, models/components definitions, interactive selection."""
import logging
import sys

logger = logging.getLogger(__name__)

# ANSI Color codes
COLORS = {
    "RED": "\033[0;31m",
    "GREEN": "\033[0;32m",
    "YELLOW": "\033[1;33m",
    "BLUE": "\033[0;34m",
    "PURPLE": "\033[0;35m",
    "CYAN": "\033[0;36m",
    "WHITE": "\033[1;37m",
    "NC": "\033[0m",
    "BOLD": "\033[1m",
}


def colored(text: str, color: str = "WHITE") -> str:
    """Return colored text using ANSI codes."""
    c = COLORS.get(color, COLORS["NC"])
    return f"{c}{text}{COLORS['NC']}"


def bold(text: str) -> str:
    """Return bold text."""
    return f"{COLORS['BOLD']}{text}{COLORS['NC']}"


def print_banner():
    """Print D∆RC banner."""
    print(colored("╔══════════════════════════════════════════════════════════════╗", "PURPLE") + COLORS["BOLD"])
    print(f"{colored('║', 'PURPLE')}{COLORS['BOLD']}            {colored('D∆RC AI Framework', 'WHITE')}{colored('', 'PURPLE')}{COLORS['BOLD']}\t\t\t ║")
    print(f"{colored('║', 'PURPLE')}{COLORS['BOLD']}      {colored('Advanced Modular AI Installation', 'CYAN')}{colored('', 'PURPLE')}{COLORS['BOLD']}\t ║")
    print(f"{colored('║', 'PURPLE')}{COLORS['BOLD']}                                                              ║")
    print(f"{colored('║', 'PURPLE')}{COLORS['BOLD']}  \t\t{colored('Created by D∆RC', 'WHITE')}{colored('', 'PURPLE')}{COLORS['BOLD']}\t\t\t ║")
    print(f"{colored('║', 'PURPLE')}{COLORS['BOLD']}\t\t{colored('Customizable AI Security Framework', 'CYAN')}{colored('', 'PURPLE')}{COLORS['BOLD']}\t\t ║")
    print(colored("╚══════════════════════════════════════════════════════════════╝", "PURPLE") + COLORS["BOLD"])
    print()


def print_section(title: str):
    """Print a section header."""
    print(colored(f"▶ {title}", "BLUE") + COLORS["BOLD"])
    print(colored("=" * 60, "BLUE"))


def print_success(msg: str):
    """Print success message."""
    print(colored("[✓]", "GREEN") + f" {msg}")


def print_warning(msg: str):
    """Print warning message."""
    print(colored("[!]", "YELLOW") + f" {msg}")


def print_error(msg: str):
    """Print error message."""
    print(colored("[✗]", "RED") + f" {msg}", file=sys.stderr)


def print_info(msg: str):
    """Print info message."""
    print(colored("[i]", "CYAN") + f" {msg}")


# Model definitions: key -> "name|description|size|tag"
MODELS = {
    "mistral:7b-instruct": "Mistral 7B Instruct|Fast, capable instruction-following model|3.5GB|RECOMMENDED",
    "llama2:7b": "Llama 2 7B|Meta's general-purpose 7B model|3.8GB|RECOMMENDED",
    "neural-chat:7b": "Neural Chat 7B|Optimized for conversations|4.1GB|FAST",
    "codeup:7b": "Code Llama 7B|Specialized for code generation|5.2GB|CODE",
    "llama2:13b": "Llama 2 13B|More capable, larger model|7.3GB|CODE",
    "neural-chat:13b": "Neural Chat 13B|Larger conversation model|7.9GB|CODE",
    "mistral:7b": "Mistral 7B|Base Mistral model|3.5GB|FAST",
    "openchat:7b": "OpenChat 7B|Community-optimized model|3.8GB|FAST",
    "dolphin-mixtral:8x7b": "Dolphin Mixtral 8x7B|Mixture of Experts model|26GB|AUDIO",
    "whisper:base": "Whisper Base|Audio transcription|140MB|AUDIO",
    "llava:7b": "LLaVA 7B|Vision-language model|4.5GB|VISION",
}

# Component definitions: key -> "name|description|status"
COMPONENTS = {
    "core": "Core AI System|Installs FastAPI controller and CLI|REQUIRED",
    "security": "Security Framework|Threat detection and analysis tools|OPTIONAL",
    "vision": "Vision Processing|Image analysis and computer vision|OPTIONAL",
    "audio": "Audio Processing|Speech-to-text and audio analysis|OPTIONAL",
    "system": "System Integration|Desktop shortcuts and systemd service|OPTIONAL",
    "training": "Training Tools|Fine-tuning and model training utilities|OPTIONAL",
}


def calculate_total_size(model_keys: list) -> str:
    """Calculate total download size for selected models."""
    total_mb = 0.0
    for key in model_keys:
        if key in MODELS:
            parts = MODELS[key].split("|")
            size_str = parts[2]
            if "GB" in size_str:
                size_num = float(size_str.replace("GB", ""))
                total_mb += size_num * 1024
            elif "MB" in size_str:
                size_num = float(size_str.replace("MB", ""))
                total_mb += size_num
    
    if total_mb > 1024:
        total_gb = total_mb / 1024
        return f"{total_gb:.1f}GB"
    return f"{int(total_mb)}MB"


def select_models(assume_yes: bool = False) -> list:
    """Interactive model selection. Returns list of selected model keys."""
    print_section("AI Model Selection")
    print_info("Choose which AI models to install:")
    print()

    model_keys = sorted(MODELS.keys())
    selected = []

    if assume_yes:
        # Auto-select RECOMMENDED models
        for key in model_keys:
            parts = MODELS[key].split("|")
            if parts[3] == "RECOMMENDED":
                selected.append(key)
        print_success(f"Auto-selected {len(selected)} recommended models (--yes mode)")
        return selected

    while True:
        print(colored("Available Models:", "WHITE"))
        print()
        for i, key in enumerate(model_keys, 1):
            parts = MODELS[key].split("|")
            name, desc, size, tag = parts
            color = "WHITE"
            if tag == "RECOMMENDED":
                color = "GREEN"
            elif tag == "CODE":
                color = "CYAN"
            elif tag == "FAST":
                color = "YELLOW"
            elif tag == "AUDIO":
                color = "PURPLE"
            elif tag == "VISION":
                color = "BLUE"

            sel = f"[{colored('✓', 'GREEN')}] " if key in selected else ""
            print(f"  {bold(str(i))}. {sel}{colored(name, color)}")
            print(f"     {desc} ({size}) {bold(f'[{tag}]')}")
            print()

        print(colored(f"Selected models total size: {calculate_total_size(selected)}", "WHITE"))
        print()
        print(colored("Options:", "YELLOW"))
        print("  Enter number to toggle model")
        print("  'r' - Auto-select recommended models")
        print("  'c' - Clear all selections")
        print("  'done' - Continue with selected models")
        print("  'q' - Quit installer")
        print()

        choice = input("Selection: ").strip().lower()

        if choice in ("r",):
            selected = [k for k in model_keys if MODELS[k].split("|")[3] == "RECOMMENDED"]
            print_success("Recommended models selected")
        elif choice in ("c",):
            selected = []
            print_success("Selection cleared")
        elif choice in ("done",):
            if not selected:
                print_warning("No models selected. At least one model is required.")
                continue
            break
        elif choice in ("q",):
            print_info("Installation cancelled")
            sys.exit(0)
        elif choice.isdigit():
            idx = int(choice) - 1
            if 0 <= idx < len(model_keys):
                key = model_keys[idx]
                if key in selected:
                    selected.remove(key)
                else:
                    selected.append(key)
            else:
                print_error("Invalid selection")
        else:
            print_error("Invalid option")

        print("\n" * 2)

    print()
    return selected


def select_components(assume_yes: bool = False) -> list:
    """Interactive component selection. Returns list of selected component keys."""
    print_section("Component Selection")
    print_info("Choose which components to install:")
    print()

    component_keys = sorted(COMPONENTS.keys())
    selected = ["core"]  # Core is always required

    if assume_yes:
        print_success("Auto-selected core component (--yes mode)")
        return selected

    while True:
        print(colored("Available Components:", "WHITE"))
        print()
        for i, key in enumerate(component_keys, 1):
            parts = COMPONENTS[key].split("|")
            name, desc, status = parts
            is_selected = key in selected
            color = "GREEN" if is_selected else "WHITE"
            sel = f"[{colored('✓', 'GREEN')}] " if is_selected else ""

            print(f"  {bold(str(i))}. {sel}{colored(name, color)}")
            print(f"     {desc} {bold(f'[{status}]')}")
            print()

        print(colored("Options:", "YELLOW"))
        print("  Enter number to toggle component (except REQUIRED)")
        print("  'a' - Select all components")
        print("  'done' - Continue with selected components")
        print("  'q' - Quit installer")
        print()

        choice = input("Selection: ").strip().lower()

        if choice in ("a",):
            selected = component_keys[:]
            print_success("All components selected")
        elif choice in ("done",):
            break
        elif choice in ("q",):
            print_info("Installation cancelled")
            sys.exit(0)
        elif choice.isdigit():
            idx = int(choice) - 1
            if 0 <= idx < len(component_keys):
                key = component_keys[idx]
                parts = COMPONENTS[key].split("|")
                if parts[2] == "REQUIRED":
                    print_warning("Core component is required and cannot be deselected")
                    continue
                if key in selected:
                    selected.remove(key)
                else:
                    selected.append(key)
            else:
                print_error("Invalid selection")
        else:
            print_error("Invalid option")

        print("\n" * 2)

    print()
    return selected


def show_installation_summary(models: list, components: list, ai_home: str, assume_yes: bool = False) -> bool:
    """Display installation summary and ask for confirmation."""
    print_section("Installation Summary")

    print(colored("Selected Models:", "WHITE"))
    for model_key in models:
        if model_key in MODELS:
            parts = MODELS[model_key].split("|")
            print(f"  {colored('•', 'GREEN')} {parts[0]} ({parts[2]})")
    print()

    print(colored("Selected Components:", "WHITE"))
    for comp_key in components:
        if comp_key in COMPONENTS:
            parts = COMPONENTS[comp_key].split("|")
            print(f"  {colored('•', 'GREEN')} {parts[0]}")
    print()

    print(colored(f"Total Download Size:", "WHITE") + f" {calculate_total_size(models)}")
    print(colored(f"Installation Directory:", "WHITE") + f" {ai_home}")
    print()

    if assume_yes:
        print_success("Auto-proceeding (--yes mode)")
        return True

    choice = input("Proceed with installation? (y/N): ").strip().lower()
    if choice in ("y", "yes"):
        print()
        return True
    else:
        print_info("Installation cancelled")
        return False
