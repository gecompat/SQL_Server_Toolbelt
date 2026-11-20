"""Eng begrenzter Leser der tatsächlich verwendeten Modulmanifest-Teilformen."""
import re


def unquote(value):
    value=value.strip()
    if len(value)>1 and value[0]==value[-1] and value[0] in "\"'":
        return value[1:-1]
    return value


def section(text, key):
    match=re.search(r'^'+re.escape(key)+r':\s*\n([\s\S]*?)(?=^\S|\Z)',text,re.M)
    return match[1] if match else ''


def scalar(text, key):
    match=re.search(r'^'+re.escape(key)+r':\s*([^\n]+)',text,re.M)
    if not match: raise ValueError('MARKERLESS_MANIFEST_FIELD: '+key)
    return unquote(match[1])


def list_values(text, key):
    raw=re.search(r'^'+re.escape(key)+r':([^\n]*)$',text,re.M)
    if not raw: raise ValueError('MARKERLESS_MANIFEST_LIST: '+key)
    inline=raw[1].strip()
    if inline:
        if not inline.startswith('[') or not inline.endswith(']'): raise ValueError('MARKERLESS_MANIFEST_LIST_FORM')
        return [unquote(v) for v in inline[1:-1].split(',') if v.strip()]
    block=section(text,key)
    return [unquote(v) for v in re.findall(r'^  - (.+)$',block,re.M)]


def objects(text):
    block=section(text,'objects')
    def inline(match):
        pairs=[item.strip().split(':',1) for item in match[1].split(',')]
        if pairs[0][0]!='type': raise ValueError('MARKERLESS_MANIFEST_OBJECT')
        return '  - '+pairs[0][0]+':'+pairs[0][1]+'\n'+'\n'.join('    '+k+':'+v for k,v in pairs[1:])
    block=re.sub(r'(?m)^  - \{\s*(type:[^\n}]+)\}\s*$',inline,block)
    result=[]
    for chunk in re.split(r'(?m)^  - type:',block)[1:]:
        value={'type':unquote(chunk.splitlines()[0])}
        for key,field in re.findall(r'^    (\w+):\s*([^\n]+)',chunk,re.M):
            value[key]=unquote(field)
        if 'name' not in value: raise ValueError('MARKERLESS_MANIFEST_OBJECT_NAME')
        result.append(value)
    expected=len(re.findall(r'^  - ',block,re.M))
    if expected!=len(result): raise ValueError('MARKERLESS_MANIFEST_OBJECT_FORM')
    return result


def dependencies(text):
    raw=re.search(r'^dependencies:([^\n]*)$',text,re.M)
    if not raw: raise ValueError('MARKERLESS_MANIFEST_DEPENDENCIES')
    if raw[1].strip() not in ('','[]'):
        inline=raw[1].strip()
        result=re.findall(r'module_id:\s*["\']?([a-z0-9.-]+)',inline)
        if not inline.startswith('[') or not inline.endswith(']') or not result or len(result)!=inline.count('module_id:'):
            raise ValueError('MARKERLESS_MANIFEST_DEPENDENCY_FORM')
        return result
    block=section(text,'dependencies')
    result=re.findall(r'(?:module_id:\s*["\']?)([a-z0-9.-]+)',block)
    if len(result)!=len(re.findall(r'^  - ',block,re.M)):
        raise ValueError('MARKERLESS_MANIFEST_DEPENDENCY_FORM')
    return result
