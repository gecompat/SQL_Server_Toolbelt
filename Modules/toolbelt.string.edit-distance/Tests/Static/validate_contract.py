"""Current component equivalence and explicitly frozen original lifecycle checks."""
from pathlib import Path
import importlib.util
import sys

ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT/'Scripts/Install'))
spec=importlib.util.spec_from_file_location('legacy_static_scope',ROOT/'Scripts/Install/Legacy-StaticScope.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)

if __name__=='__main__':
    raise SystemExit(module.run('toolbelt.string.edit-distance'))
