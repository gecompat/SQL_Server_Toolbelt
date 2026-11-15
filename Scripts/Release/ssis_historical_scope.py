"""Explicit archived context for the pre-Copy-Column SSIS receipts.

This context validates original bytes; it grants no current-build acceptance.
Current product validators keep rejecting old receipts against changed sources.
"""
from contextlib import contextmanager
from importlib import import_module
from pathlib import Path
import sys

BASELINE='6e1985aee3e0ded746d1a32c6d494b370049872b'
COPY_COLUMN_BASELINE='985d1a424c6900d30a95ee5e1ef591f77d3ce971'


@contextmanager
def copy_column_v1_scope(root):
    """C7-Originale prüfen, ohne den ANSI-korrigierten Build zu qualifizieren."""
    root=Path(root).resolve()
    sys.path.insert(0,str(root/'Tests/Release'))
    from ssis_historical_context import historical_root
    snapshot=historical_root(root,COPY_COLUMN_BASELINE)
    names=('new_ssis_current_package','validate_ssis_current_package',
           'validate_ssis_copy_column','validate_ssis_copy_column_host',
           'validate_ssis_copy_column_delivery','validate_ssis_copy_column_ssms',
           'validate_ssis_copy_column_functional')
    modules=[import_module(name) for name in names]
    previous=[module.ROOT for module in modules]
    try:
        for module in modules: module.ROOT=snapshot
        yield snapshot
    finally:
        for module,original in zip(modules,previous): module.ROOT=original


@contextmanager
def pre_copy_column_scope(root):
    root=Path(root).resolve()
    sys.path.insert(0,str(root/'Tests/Release'))
    from ssis_historical_context import historical_root
    snapshot=historical_root(root,BASELINE)
    # These receipt validators run sequentially; globals are restored even on
    # rejection. Original report/package immutability is checked by the helper.
    names=('new_ssis_current_package','validate_ssis_current_package',
           'validate_ssis_current_qualified_package','validate_ssis_current_build',
           'validate_ssis_fresh_build')
    modules=[import_module(name) for name in names]
    previous=[module.ROOT for module in modules]
    try:
        for module in modules: module.ROOT=snapshot
        yield snapshot
    finally:
        for module,original in zip(modules,previous): module.ROOT=original
