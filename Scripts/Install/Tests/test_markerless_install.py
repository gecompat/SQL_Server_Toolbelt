"""Markerfreier Buildvertrag; keine SQL-Verbindung oder Infrastrukturaktion."""
from pathlib import Path
import importlib.util
import sys
import unittest

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'Scripts/Install'))
import markerless_manifest as manifest


def load(name):
    spec=importlib.util.spec_from_file_location(name,ROOT/'Scripts/Install'/name)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    return module


installer=load('New-SimpleCommonInstall.py')
capabilities=load('New-MarkerlessCapabilities.py')


class MarkerlessContractTests(unittest.TestCase):
    def test_inline_and_multiline_objects_and_lists_have_same_contract(self):
        expected=[{'type':'USP','schema':'toolbelt_core','name':'Contoso','visibility':'public'}]
        inline='objects:\n  - { type: USP, schema: "toolbelt_core", name: Contoso, visibility: public }\nnext: 1\n'
        multiline='objects:\n  - type: USP\n    schema: toolbelt_core\n    name: Contoso\n    visibility: public\nnext: 1\n'
        self.assertEqual(manifest.objects(inline),expected)
        self.assertEqual(manifest.objects(multiline),expected)
        self.assertEqual(manifest.list_values('schemas: [toolbelt_core]\n','schemas'),['toolbelt_core'])
        self.assertEqual(manifest.list_values('schemas:\n  - "toolbelt_core"\n','schemas'),['toolbelt_core'])

    def test_malformed_manifest_is_not_silently_ignored(self):
        for text in ('objects:\n  - name: Contoso\nnext: 1\n','objects:\n  - type: USP\nnext: 1\n'):
            with self.assertRaises(ValueError): manifest.objects(text)
        with self.assertRaises(ValueError): manifest.dependencies('dependencies: [unexpected]\n')
        with self.assertRaises(ValueError): manifest.dependencies('dependencies:\n  - reason: none\nnext: 1\n')
        with self.assertRaises(ValueError): manifest.list_values('schemas: unknown\n','schemas')

    def test_profile_sets_keep_platform_and_central_boundaries(self):
        counts={('Windows','local'):45,('Windows','central'):43,('Portable','local'):41,('Portable','central'):41}
        for profile,count in counts.items():
            with self.subTest(profile=profile):
                selected=installer.modules(*profile)
                ids=[m['id'] for m in selected]
                self.assertEqual(len(ids),count)
                self.assertEqual(len(ids),len(set(ids)))
                positions={name:i for i,name in enumerate(ids)}
                for module in selected:
                    for dependency in module['dependencies']:
                        self.assertLess(positions[dependency],positions[module['id']])
                if profile[0]=='Portable': self.assertTrue(installer.WINDOWS_ONLY.isdisjoint(ids))
                if profile[1]=='central': self.assertTrue(installer.LOCAL_ONLY.isdisjoint(ids))

    def test_actual_source_closure_expands_fragments_without_running_deployment(self):
        sources,pins=installer.source_files(installer.modules('Windows','local'))
        names={source['path'] for source in sources}
        self.assertTrue(installer.SKIP.isdisjoint(names))
        binary=next(s['sql'] for s in sources if s['path'].endswith('/USP_LoadBinaryFile.sql'))
        self.assertNotIn(':r ',binary)
        self.assertIn('DirectoryPrefix',binary)
        self.assertIn('Modules/toolbelt.file.content/Source/FileContentRootPredicate.sql',pins)

    def test_create_only_procedure_and_unknown_statement_barrier(self):
        source={'path':'Modules/toolbelt.core.result-table/Source/Contoso.sql','statements':[
            {'kind':'CreateOrAlterProcedureStatement','name':'toolbelt_core.Contoso',
             'sql':'CREATE OR ALTER PROCEDURE toolbelt_core.Contoso AS SELECT 1;'}]}
        result=installer.emit_sources([source],{})
        self.assertIn("IF OBJECT_ID(N'toolbelt_core.Contoso') IS NULL",result)
        self.assertNotIn('CREATE OR ALTER',result)
        source['statements'][0]['kind']='DropProcedureStatement'
        source['statements'][0]['name']=None
        with self.assertRaisesRegex(ValueError,'unhandled source statement'): installer.emit_sources([source],{})

    def test_embedded_legacy_deployments_include_every_canonical_tvf(self):
        sources,pins=installer.source_files(installer.modules('Windows','local'))
        by_path={source['path']:source['sql'] for source in sources}
        for module,names in {
            'toolbelt.conversion.safe-cast':('TVF_TryCastBigInt','TVF_TryCastDecimal',
                'TVF_TryCastDate','TVF_TryCastDateTime2','TVF_TryCastBit','TVF_TryCastUniqueIdentifier'),
            'toolbelt.json.pointer':('TVF_ResolveJsonPointer',),
        }.items():
            for name in names:
                path='Modules/'+module+'/Source/'+name+'.sql'
                self.assertIn(path,by_path)
                self.assertIn(path,pins)
                self.assertEqual(by_path[path],(ROOT/path).read_text(encoding='utf-8-sig'))
        self.assertEqual(len(by_path),len(sources))

    def test_module_without_source_or_clr_is_rejected(self):
        module={'id':'toolbelt.conversion.safe-cast','text':'objects: []\nclr:\n  used: false\n'}
        with self.assertRaisesRegex(ValueError,'module without executable source'):
            installer.source_files([module])

    def test_table_migrations_have_fresh_group_guard_and_partial_group_stop(self):
        source={'path':'Modules/toolbelt.core.work-queue/Source/WorkItem.sql','statements':[
            {'kind':'IfStatement','name':None,'sql':"IF OBJECT_ID(N'toolbelt_core.WorkItem') IS NULL CREATE TABLE toolbelt_core.WorkItem(n int);"},
            {'kind':'AlterTableAddTableElementStatement','name':None,'sql':'ALTER TABLE toolbelt_core.WorkItem ADD m int;'},
            {'kind':'IfStatement','name':None,'sql':"IF OBJECT_ID(N'toolbelt_core.WorkQueueScheduler') IS NULL CREATE TABLE toolbelt_core.WorkQueueScheduler(n int);"}]}
        result=installer.emit_sources([source],{})
        self.assertIn('NOT IN(0,2) THROW',result)
        self.assertLess(result.index(')=0\nBEGIN'),result.index('ALTER TABLE'))

    def test_capability_projection_does_not_invent_version_or_ownership(self):
        sql=capabilities.render()
        self.assertEqual((ROOT/capabilities.TARGET).read_text(encoding='utf-8-sig'),sql)
        self.assertNotIn('extended_properties',sql)
        self.assertIn("CONVERT(nvarchar(4000),NULL) ModuleVersion",sql)
        self.assertIn("CONVERT(varchar(16),'incomplete')",sql)
        for path in (ROOT/'Modules').glob('*/module.yaml'):
            self.assertIn("N'"+path.parent.name+"'",sql)

    def test_permission_contract_is_preserved_and_unknown_declarations_fail(self):
        text=(ROOT/'Modules/toolbelt.filesystem.windows/module.yaml').read_text(encoding='utf-8')
        self.assertEqual(installer.assembly_permission(text),'UNSAFE')
        legacy=(ROOT/'Modules/toolbelt.filesystem.windows/Deployment/Deploy.sql').read_text(encoding='utf-8')
        self.assertIn('WITH PERMISSION_SET = '+installer.assembly_permission(text),legacy)
        for value in ('SAFE','EXTERNAL_ACCESS','UNSAFE'):
            self.assertEqual(installer.assembly_permission('clr:\n  permission_set: "'+value+'"\n'),value)
        for declaration in ('','  permission_set: null\n','  permission_set: unknown\n',
                            '  permission_set: SAFE\n  permission_set: UNSAFE\n'):
            with self.assertRaises(ValueError): installer.assembly_permission('clr:\n'+declaration)

    def test_sql_alias_does_not_rewrite_clr_class_identity(self):
        source={'path':'Modules/toolbelt.file.csv-memory/Source/Contoso.sql','statements':[
            {'kind':'CreateFunctionStatement','name':'toolbelt_file.Contoso',
             'sql':'CREATE FUNCTION toolbelt_file.Contoso() RETURNS int AS EXTERNAL NAME [Toolbelt_File_CsvMemory].[Toolbelt.Csv.Provider].[Contoso];'}]}
        result=installer.emit_sources([source],{'Toolbelt_File_CsvMemory':'tlblt_File_CsvMemory'})
        self.assertIn('[tlblt_File_CsvMemory].[Toolbelt.Csv.Provider].[Contoso]',result)


if __name__=='__main__': unittest.main()
