"""CLI entrypoint for the D∆RC hybrid installer."""
import argparse
import logging
import sys
from .installer import run_install


def parse_args(argv=None):
    p = argparse.ArgumentParser(prog="darc-install")
    p.add_argument("--dry-run", action="store_true", help="Show actions without executing them")
    p.add_argument("--yes", "-y", action="store_true", help="Assume yes to prompts")
    p.add_argument("--verbose", "-v", action="count", default=0, help="Increase verbosity")
    p.add_argument("--debug", action="store_true", help="Enable debug logging")
    p.add_argument("--diagnose", action="store_true", help="Show system detection and exit")
    return p.parse_args(argv)


def configure_logging(verbosity: int, debug: bool):
    if debug:
        level = logging.DEBUG
    elif verbosity >= 2:
        level = logging.DEBUG
    elif verbosity == 1:
        level = logging.INFO
    else:
        level = logging.WARNING

    logging.basicConfig(level=level, format="[%(levelname)s] %(message)s")


def main(argv=None):
    args = parse_args(argv)
    configure_logging(args.verbose, args.debug)
    log = logging.getLogger("darc_installer.cli")

    if args.diagnose:
        # Run lightweight detection and exit
        from .system import detect_package_manager, get_sys_info

        info = get_sys_info()
        pm = detect_package_manager()
        print("System diagnosis:")
        for k, v in info.items():
            print(f"  {k}: {v}")
        print(f"Detected package manager: {pm}")
        return 0

    try:
        run_install(dry_run=args.dry_run, assume_yes=args.yes)
    except KeyboardInterrupt:
        log.warning("Interrupted by user")
        return 130
    except Exception:
        log.exception("Installer failed")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
