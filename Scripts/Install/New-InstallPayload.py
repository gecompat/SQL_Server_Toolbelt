"""Bind four ordinary SQL profiles to an immutable source commit; no SQL execution."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import importlib.util
import json
import re
import subprocess
import zipfile

ROOT=Path(__file__).resolve().parents[2]
SPEC=importlib.util.spec_from_file_location('common_install',Path(__file__).with_name('New-SimpleCommonInstall.py'))
common=importlib.util.module_from_spec(SPEC);SPEC.loader.exec_module(common)


def require(value,message):
    if not value: raise ValueError('INSTALL_PAYLOAD: '+message)


def git(*args):
    return subprocess.run(['git',*args],cwd=ROOT,check=True,capture_output=True).stdout


def sha(data):
    return hashlib.sha256(data).hexdigest()


def source_file(commit,path):
    require(isinstance(path,str) and not PurePosixPath(path).is_absolute()
            and '..' not in PurePosixPath(path).parts and '\\' not in path,'relative source path')
    return git('show',commit+':'+path)


def objects(selected):
    return common.interface_objects(selected)


def payload(profiles_directory,source_commit,release):
    commit=git('rev-parse','--verify','--end-of-options',source_commit+'^{commit}').decode().strip()
    require(re.fullmatch('[0-9a-f]{40}',commit),'source commit')
    require(re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?',release),'release name')
    files={};profiles=[]
    for platform,mode in [('Windows','local'),('Windows','central'),('Portable','local'),('Portable','central')]:
        path=Path(profiles_directory)/f'Install-{platform}-{mode}.sql'
        data=path.read_bytes();record=json.loads(Path(str(path)+'.manifest.json').read_bytes())
        require(record['schema']=='toolbelt-markerless-install/v1' and record['platform']==platform
                and record['mode']==mode and record['trust']=='auto','profile contract')
        require(sha(data)==record['sql_sha256'],'SQL bytes changed')
        require(data.startswith(b'USE [ContosoToolbelt];\n') and
                len(re.findall(rb"(?m)^DECLARE @TrustMethod varchar\(24\)=N'auto';$",data))==1,'controlled SQL parameters')
        for name,digest in record['source_sha256'].items():
            require(sha(source_file(commit,name).replace(b'\r\n',b'\n'))==digest,
                    'profile does not bind declared source: '+name)
        selected=common.modules(platform,mode)
        require([m['id'] for m in selected]==record['modules'],'module closure')
        require(record['objects']==objects(selected),'interface inventory')
        assemblies=record['binary_sha512']
        require(assemblies and all(re.fullmatch(r'tlblt[A-Za-z0-9_.]*',name)
                and re.fullmatch('[0-9a-fA-F]{128}',digest) for name,digest in assemblies.items()),'assembly contract')
        name=f'Sql/Install-{platform}-{mode}.sql';files[name]=data
        profiles.append({'platform':platform,'mode':mode,'path':name,'modules':record['modules'],
                         'objects':objects(selected),'assemblies':assemblies})
    manifest={'schema':'toolbelt-install-package/v2','release':release,'source_commit':commit,
              'lifecycle':'create-only','runtime_qualification':'not executed for this exact package',
              'profiles':profiles,'files':{name:sha(data) for name,data in sorted(files.items())}}
    files['PACKAGE.json']=(json.dumps(manifest,indent=2,ensure_ascii=False)+'\n').encode('utf-8')
    return files,manifest


def write_zip(output,files):
    require(not output.exists(),'new output required')
    output.parent.mkdir(parents=True,exist_ok=True)
    with output.open('xb') as stream:
        with zipfile.ZipFile(stream,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
            for name,data in sorted(files.items()):
                info=zipfile.ZipInfo(name,date_time=(2026,1,1,0,0,0));info.compress_type=zipfile.ZIP_DEFLATED
                info.external_attr=0o100644<<16
                archive.writestr(info,data)
    output.with_suffix(output.suffix+'.sha256').write_text(sha(output.read_bytes())+'  '+output.name+'\n',encoding='ascii')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profiles',type=Path,required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--source-commit',default='HEAD')
    parser.add_argument('--release',default='v1.0.0-rc.5')
    args=parser.parse_args()
    files,manifest=payload(args.profiles,args.source_commit,args.release)
    write_zip(args.output,files)
    print('INSTALL_PAYLOAD_BUILT profiles=4; source='+manifest['source_commit']+'; no SQL executed')
