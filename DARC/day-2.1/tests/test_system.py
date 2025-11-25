import pytest
from darc_installer import system


def test_detect_package_manager():
    pm = system.detect_package_manager()
    # detection may return None on exotic systems; assert it does not raise
    assert pm is None or isinstance(pm, str)


def test_run_cmd_dry_run():
    res = system.run_cmd(["echo", "hello"], dry_run=True)
    assert res is None
