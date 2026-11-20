"""Leitet sichtbare Schnittstellenkandidaten aus den Modulmanifesten ab."""
from pathlib import Path
import argparse
from markerless_manifest import objects, scalar, section

ROOT=Path(__file__).resolve().parents[2]
TARGET='Modules/toolbelt.metadata.capability-catalog/Source/VW_ModuleCapabilities.sql'
TYPES={'USP':'P,PC','CLR_USP':'PC','TVF':'IF,TF,FT','CLR_TVF':'FT','SVF':'FN,FS',
       'CLR_SVF':'FS','CLR_AGGREGATE':'AF','VIEW':'V','VW':'V','TABLE':'U'}


def assembly_name(name):
    if name.startswith('tlblt'): return name
    if name.startswith('Toolbelt_'): return 'tlblt_'+name[len('Toolbelt_'):]
    if name=='Microsoft.SqlServer.TransactSql.ScriptDom': return 'tlblt.'+name
    raise ValueError('MARKERLESS_ASSEMBLY_NAME')


def render(root=ROOT):
    rows=[]
    for manifest in sorted((root/'Modules').glob('*/module.yaml')):
        text=manifest.read_text(encoding='utf-8-sig')
        module=scalar(text,'module_id')
        found=[]
        for obj in objects(text):
            if obj['type']=='ASSEMBLY':
                found.append((module,assembly_name(obj['name']),'ASSEMBLY'))
            elif obj['type'] in TYPES:
                found.append((module,obj['schema']+'.'+obj['name'],TYPES[obj['type']]))
            else: raise ValueError('MARKERLESS_CAPABILITY_OBJECT_TYPE')
        if not found:
            found.append((module,assembly_name(scalar(section(text,'clr'),'  assembly_sql_name')),'ASSEMBLY'))
        rows.extend(found)
    values=',\n    '.join("(N'%s',N'%s',N'%s')"%row for row in rows)
    return '''-- ============================================================================
-- Objekt: toolbelt_metadata.VW_ModuleCapabilities; Typ: View
-- Zweck: Sichtbare bekannte Toolbelt-Schnittstellenkandidaten anzeigen.
-- Vertrag: Documentation/Architecture/CAPABILITY_CATALOG_MODULE_DESIGN.md
-- Resultset: ModuleId sysname, ModuleVersion/DeploymentMode nvarchar(4000),
-- MetadataStatus varchar(16). Keine Parameter oder Seiteneffekte.
-- Dependencies: sys.objects und sys.assemblies; keine Registry oder Marker.
-- Rechte: SELECT auf der View; unveränderte Metadata Visibility.
-- Versionen: SQL Server 2019/2022/2025; Windows und Linux.
-- Fehlerverhalten: Read-only; nicht sichtbare Kandidaten erscheinen nicht.
-- Performance: Feste Manifestprojektion mit Katalog-Existenzprüfungen.
-- Einschränkungen: Namen beweisen weder Herkunft noch vollständige Installation,
-- Version, Deploymentmodus oder Qualifikation. Daher beide Werte NULL und
-- MetadataStatus=incomplete. Nicht als Autorisierungs-/Deploymentgate verwenden.
-- Generiert: Scripts/Install/New-MarkerlessCapabilities.py --check
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW toolbelt_metadata.VW_ModuleCapabilities AS
WITH Candidates AS
(
    SELECT v.ModuleId,v.ObjectName,v.ObjectTypes FROM (VALUES
    '''+values+'''
    ) v(ModuleId,ObjectName,ObjectTypes)
), Visible AS
(
    SELECT DISTINCT ModuleId FROM Candidates c
    WHERE (ObjectTypes=N'ASSEMBLY' AND EXISTS(SELECT 1 FROM sys.assemblies a
        WHERE CONVERT(varbinary(256),a.name)=CONVERT(varbinary(256),c.ObjectName)))
    OR (ObjectTypes<>N'ASSEMBLY' AND EXISTS(SELECT 1 FROM sys.objects o
        WHERE o.object_id=OBJECT_ID(c.ObjectName)
        AND CHARINDEX(N','+RTRIM(o.type)+N',',N','+c.ObjectTypes+N',')>0))
)
SELECT CONVERT(sysname,ModuleId) ModuleId,CONVERT(nvarchar(4000),NULL) ModuleVersion,
    CONVERT(nvarchar(4000),NULL) DeploymentMode,CONVERT(varchar(16),'incomplete') MetadataStatus
FROM Visible;
GO
'''


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    content=render()
    path=ROOT/TARGET
    if args.check:
        if path.read_text(encoding='utf-8-sig')!=content: raise SystemExit('MARKERLESS_CAPABILITY_DRIFT')
    else: path.write_text(content,encoding='utf-8',newline='\n')
