"""Explicit original lifecycle assertions plus current component equivalence.

Retired SQL lifecycle is checked at its immutable source, never installed by the
current builder. Unchanged files retain exact equivalence. Declared functional
deltas are checked separately and never inherit the old suite's runtime scope.
Current markerless lifecycle and client checks are separate mandatory gates.
"""
from pathlib import Path
import importlib.util
import os
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
BASELINE='2fbe8e3e86f370b22ad2ce9f9716d971072a052b'


def load(name):
    spec=importlib.util.spec_from_file_location(name.replace('-','_'),Path(__file__).with_name(name+'.py'))
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    return module


def run(module_id):
    available=subprocess.run(['git','cat-file','-e',BASELINE+'^{commit}'],cwd=ROOT,
                             stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=30)
    if available.returncode:
        if os.environ.get('GITHUB_ACTIONS')!='true':
            raise ValueError('Original source commit missing; fetch '+BASELINE+' explicitly')
        # Exact public predecessor required by these historical CI assertions.
        # No branch fallback and no checkout of mutable remote state.
        subprocess.run(['git','fetch','--no-tags','--depth=1','origin',BASELINE],cwd=ROOT,check=True,timeout=120)
    common=load('New-SimpleCommonInstall')
    selected=[m['id'] for m in common.modules('Windows','local',[module_id])]
    count=load('Verify-ComponentReuse').verify(module_ids=selected,allow_current_deltas=True)
    sys.path.insert(0,str(ROOT/'Tests/Release'))
    from ssis_historical_context import historical_root
    frozen=historical_root(ROOT,BASELINE)
    path=frozen/'Modules'/module_id/'Tests/Static/validate_contract.py'
    env=os.environ.copy();env['PYTHONDONTWRITEBYTECODE']='1';env['PYTHONIOENCODING']='utf-8'
    result=subprocess.run([sys.executable,'-B',str(path)],cwd=frozen,env=env,timeout=120)
    print('STATIC_SCOPE module='+module_id+'; unchanged component files='+str(count)+
          '; declared deltas source-checked, not runtime-qualified; lifecycle assertions at '+BASELINE+
          '; current help/deployment/native acceptance separate',flush=True)
    return result.returncode
