"""Package a source-bound current installer and its four SQL profiles; never publish."""
from pathlib import Path, PurePosixPath
import argparse
import importlib.util
import json
import posixpath
import re
import subprocess
import zipfile

ROOT=Path(__file__).resolve().parents[2]
_spec=importlib.util.spec_from_file_location('install_payload',Path(__file__).with_name('New-InstallPayload.py'))
payload=importlib.util.module_from_spec(_spec);_spec.loader.exec_module(payload)
CLIENT=(
    'Deployment/Install-Toolbelt.ps1','Deployment/Toolbelt.CurrentInstall.ps1',
    'Deployment/Toolbelt.Package.ps1','Deployment/Toolbelt.SqlTransport.ps1',
    'Deployment/Toolbelt.Provisioning.ps1',
)
DOCS=('INSTALL.md','Deployment/ONE-CALL-INSTALL.md','Deployment/PROVISIONING.md')


def documentation(data,path,commit):
    """Keep packaged instructions usable without copying the entire historical repo."""
    text=data.decode('utf-8-sig')
    def link(match):
        target=match[2]
        if re.match(r'^[A-Za-z][A-Za-z0-9+.-]*:',target) or target.startswith('#'):
            return match[0]
        relative=posixpath.normpath(posixpath.join(posixpath.dirname(path),target))
        payload.require(not relative.startswith('../'),'documentation link outside repository')
        return match[1]+'https://github.com/gecompat/SQL_Server_Toolbelt/blob/'+commit+'/'+relative+')'
    return re.sub(r'(\[[^\]]*\]\()([^)]+)\)',link,text).encode('utf-8')


def install_set(payload_path,source_commit):
    commit=payload.git('rev-parse','--verify','--end-of-options',source_commit+'^{commit}').decode().strip()
    raw=Path(payload_path).read_bytes()
    with zipfile.ZipFile(payload_path) as archive:
        names=archive.namelist()
        payload.require(len(names)==len(set(names)) and len(names)==5,'exact inner inventory')
        manifest=json.loads(archive.read('PACKAGE.json'))
        payload.require(manifest['schema']=='toolbelt-install-package/v2' and
                        manifest['source_commit']==commit and manifest['lifecycle']=='create-only',
                        'source-bound payload contract')
        expected={'Sql/Install-'+p+'-'+m+'.sql' for p in ('Windows','Portable') for m in ('local','central')}
        payload.require(set(manifest['files'])==expected and set(names)==expected|{'PACKAGE.json'},'four SQL profiles')
        files={'Package/Toolbelt-Install-Payload.zip':raw}
        for name in sorted(expected):
            data=archive.read(name)
            payload.require(payload.sha(data)==manifest['files'][name],'inner SQL hash')
            files[name]=data
    for path in (*CLIENT,*DOCS,'LICENSE.md'):
        data=payload.source_file(commit,path)
        payload.require((ROOT/path).read_bytes().replace(b'\r\n',b'\n')==data.replace(b'\r\n',b'\n'),
                        'commit current client/docs before packaging: '+path)
        files[path]=documentation(data,path,commit) if path in DOCS else data
    files['START-HERE.txt']=(
        'Toolbelt '+manifest['release']+' - built development installation set; not published.\n'
        'Source commit: '+commit+'\n'
        'PowerShell 7.4+ and ODBC-sqlcmd: run from this extracted directory.\n'
        'Local: pwsh -File Deployment/Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoApp -DeploymentMode local\n'
        'Central: pwsh -File Deployment/Install-Toolbelt.ps1 -ServerInstance localhost -Database ContosoToolbelt -DeploymentMode central\n'
        'Optional administrative preparation: -CreateDatabase -EnableClr. See Deployment/PROVISIONING.md.\n'
        'Alternatively open Sql/Install-<platform>-<mode>.sql in SSMS, change only the first USE, execute normally without SQLCMD mode.\n'
        'The default auto trust mode uses existing TRUSTWORTHY ON or exact assembly hashes; no error fallback.\n'
        'Create-only: existing objects are not upgraded or uninstalled. Exact package native qualification is not claimed.\n'
        'Read INSTALL.md and Deployment/ONE-CALL-INSTALL.md before execution. SQL authentication: -Credential (Get-Credential).\n'
        'PackageZip denotes Package/Toolbelt-Install-Payload.zip, not this outer installation ZIP.\n'
    ).encode('utf-8')
    record={'schema':'toolbelt-install-set/v1','release':manifest['release'],'source_commit':commit,
            'runtime_qualification':manifest['runtime_qualification'],
            'files':{name:payload.sha(data) for name,data in sorted(files.items())}}
    files['INSTALL-SET.json']=(json.dumps(record,indent=2)+'\n').encode()
    return files,record


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--payload',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--source-commit',default='HEAD')
    args=parser.parse_args()
    files,record=install_set(args.payload,args.source_commit)
    payload.write_zip(args.output,files)
    print('INSTALL_SET_BUILT source='+record['source_commit']+'; no SQL executed; not published')
