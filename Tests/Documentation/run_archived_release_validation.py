"""Run intact historical evidence checks, without accepting current deployment."""
from pathlib import Path
import os
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
BASELINE='2fbe8e3e86f370b22ad2ce9f9716d971072a052b'


def command():
    sys.path.insert(0,str(ROOT/'Tests/Release'))
    from ssis_historical_context import historical_root
    frozen=historical_root(ROOT,BASELINE)
    changed=subprocess.check_output(['git','diff','--name-only','--diff-filter=MD',BASELINE,'--',
        'Releases',':(glob)Modules/**/Tests/Qualification/**',':(glob)Modules/**/InstallPackages/**'],cwd=ROOT,text=True)
    protected=[p for p in changed.splitlines() if p.endswith(('.json','.zip','.sha256','.sha512'))]
    if protected:raise ValueError('HISTORICAL_EVIDENCE_CHANGED: '+', '.join(protected))
    print('HISTORICAL_RELEASE_SUITE source='+BASELINE+'; no current deployment qualification',flush=True)
    return [sys.executable,'-B',str(frozen/'Tests/Documentation/run_release_validation.py')]


def run_owned(args, **kwargs):
    """Bound the real suite tree; captured output uses files, never inherited pipes."""
    import tempfile
    timeout=kwargs.pop('timeout')
    capture=kwargs.pop('capture_output',False)
    text=kwargs.get('text',False)
    encoding=kwargs.get('encoding') or 'utf-8'
    if os.name!='nt':kwargs['start_new_session']=True
    with tempfile.TemporaryFile() as stdout_file, tempfile.TemporaryFile() as stderr_file:
        if capture:kwargs.update(stdout=stdout_file,stderr=stderr_file)
        process=subprocess.Popen(args,**kwargs)
        expired=False
        try:
            process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            expired=True
            # The live Popen handle belongs to this invocation. Never discover
            # or terminate an unrelated process by name or a historical PID.
            if process.poll() is None:
                if os.name=='nt':
                    subprocess.run(['pwsh','-NoProfile','-NonInteractive','-Command',
                        '[Diagnostics.Process]::GetProcessById('+str(process.pid)+').Kill($true)'],
                        stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,
                        creationflags=subprocess.CREATE_NO_WINDOW,timeout=15,check=False)
                else:
                    import signal
                    try:os.killpg(process.pid,signal.SIGKILL)
                    except ProcessLookupError:pass
                if process.poll() is None:process.kill()
            process.wait(timeout=10)
        def captured(stream):
            if not capture:return None
            stream.seek(0)
            data=stream.read(8*1024*1024+1)
            if len(data)>8*1024*1024:raise ValueError('HISTORICAL_SUITE_OUTPUT_LIMIT')
            return data.decode(encoding) if text else data
        stdout,stderr=captured(stdout_file),captured(stderr_file)
        if expired:raise subprocess.TimeoutExpired(args,timeout,output=stdout,stderr=stderr)
        return subprocess.CompletedProcess(args,process.returncode,stdout,stderr)


def main():
    env=os.environ.copy();env['PYTHONIOENCODING']='utf-8';env['PYTHONDONTWRITEBYTECODE']='1'
    return run_owned(command(),cwd=ROOT,env=env,timeout=1800).returncode


if __name__=='__main__':raise SystemExit(main())
