"""Markerfreier Buildvertrag; keine SQL-Verbindung oder Infrastrukturaktion."""
from pathlib import Path
import importlib.util
import re
import sys
import unittest
import tempfile
import subprocess
from unittest.mock import patch

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
    def test_current_module_lifecycle_has_one_markerless_builder(self):
        paths=list((ROOT/'Modules').glob('*/module.yaml'))
        self.assertEqual(len(paths),45)
        for path in paths:
            text=path.read_text(encoding='utf-8-sig')
            lifecycle=manifest.section(text,'lifecycle')
            self.assertEqual(manifest.scalar(lifecycle,'  module_selector'),path.parent.name)
            self.assertEqual(manifest.scalar(lifecycle,'  execution_mode'),'TSQL')
            self.assertEqual(manifest.scalar(lifecycle,'  installation'),'create-only')
            builder=path.parent/manifest.scalar(lifecycle,'  install_builder')
            self.assertEqual(builder.resolve(),(ROOT/'Deployment/Build-Install.ps1').resolve())
            self.assertTrue(builder.is_file())
            self.assertEqual(manifest.scalar(manifest.section(text,'contracts'),'  deployment'),'2.0')
            self.assertFalse((path.parent/'Deployment/Deploy.sql').exists())
            self.assertFalse((path.parent/'Deployment/Uninstall.sql').exists())

    def test_current_binary_builders_emit_no_retired_sql_payload(self):
        builders=list((ROOT/'Modules').glob('*/Scripts/New-ClrReleaseArtifacts.ps1'))
        builders.append(ROOT/'Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1')
        for path in builders:
            text=path.read_text(encoding='utf-8-sig')
            self.assertNotIn('Deploy.WithAssembly.sql',text,path)
            self.assertNotIn('Uninstall.Expanded.sql',text,path)
            self.assertNotIn('Deployment/Deploy.sql',text,path)

    def test_canonical_manifests_already_use_prefixed_assembly_names(self):
        names=set()
        for path in (ROOT/'Modules').glob('*/module.yaml'):
            text=path.read_text(encoding='utf-8-sig')
            own={obj['name'] for obj in manifest.objects(text) if obj['type']=='ASSEMBLY'}
            clr=manifest.section(text,'clr')
            if clr and manifest.scalar(clr,'  used')=='true':
                own.add(manifest.scalar(clr,'  assembly_sql_name'))
            for name in own:
                self.assertTrue(name.startswith('tlblt'),path)
                self.assertNotIn(name,names)
                names.add(name)
        self.assertEqual(len(names),12)

    def test_canonical_sources_need_no_legacy_name_translation(self):
        selected=installer.modules('Windows','local')
        sources,_=installer.source_files(selected)
        names={obj['name'] for module in selected for obj in manifest.objects(module['text'])
               if obj['type']=='ASSEMBLY'}
        names.update(manifest.scalar(manifest.section(module['text'],'clr'),'  assembly_sql_name')
                     for module in selected if manifest.section(module['text'],'clr')
                     and manifest.scalar(manifest.section(module['text'],'clr'),'  used')=='true')
        references={name for source in sources for name in re.findall(
            r'(?i)\bEXTERNAL\s+NAME\s+\[([^\]]+)\]',source['sql'])}
        self.assertTrue(references)
        self.assertTrue(references<=names,references-names)
        self.assertTrue(all(name.startswith('tlblt') for name in references))

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

    def test_module_selection_adds_only_transitive_dependencies(self):
        selected=installer.modules('Windows','local',['toolbelt.tsql.ssis-debug'])
        ids=[m['id'] for m in selected]
        self.assertIn('toolbelt.tsql.ssis-debug',ids)
        self.assertIn('toolbelt.tsql.script-parser',ids)
        self.assertNotIn('toolbelt.file.xlsx-memory',ids)
        for index,module in enumerate(selected):
            for dependency in module['dependencies']:
                self.assertIn(dependency,ids[:index])

    def test_module_selection_does_not_silently_drop_unsupported_requests(self):
        for platform,mode,ids in (
            ('Portable','local',['toolbelt.tsql.ssis-debug']),
            ('Windows','central',['toolbelt.filesystem.windows']),
            ('Windows','local',['toolbelt.not-present']),
            ('Windows','local',[]),
            ('Windows','local',['toolbelt.json.core','toolbelt.json.core'])):
            with self.subTest(platform=platform,mode=mode,ids=ids):
                with self.assertRaises(ValueError): installer.modules(platform,mode,ids)

    def test_portable_clone_subset_preserves_conditional_parser_boundary(self):
        ids=[m['id'] for m in installer.modules('Portable','central',['toolbelt.metadata.table-clone'])]
        self.assertIn('toolbelt.metadata.table-clone',ids)
        self.assertNotIn('toolbelt.tsql.script-parser',ids)

    def test_unrelated_modules_do_not_require_ssis_or_parser_release_inputs(self):
        with tempfile.TemporaryDirectory() as directory:
            for ids in ({'toolbelt.string.regex'},{'toolbelt.core.result-table'}):
                artifacts,binaries=installer.binary_inputs(Path(directory),ids)
                selected=[a for a in artifacts if a['module_id'] in ids]
                self.assertTrue(all(a['file'] in binaries for a in selected))
                self.assertEqual(len(selected),int('toolbelt.string.regex' in ids))

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

    def test_embedded_and_template_deployments_include_canonical_entries(self):
        sources,pins=installer.source_files(installer.modules('Windows','local'))
        by_path={source['path']:source['sql'] for source in sources}
        for module,names in {
            'toolbelt.conversion.safe-cast':('TVF_TryCastBigInt','TVF_TryCastDecimal',
                'TVF_TryCastDate','TVF_TryCastDateTime2','TVF_TryCastBit','TVF_TryCastUniqueIdentifier'),
            'toolbelt.json.pointer':('TVF_ResolveJsonPointer',),
            'toolbelt.tsql.ssis-debug':('USP_ExplainSsisDataFlow','USP_ExplainSsisDataFlowInternal'),
        }.items():
            for name in names:
                path='Modules/'+module+'/Source/'+name+'.sql'
                self.assertIn(path,by_path)
                self.assertIn(path,pins)
                self.assertEqual(by_path[path],(ROOT/path).read_text(encoding='utf-8-sig'))
        self.assertEqual(len(by_path),len(sources))

    def test_module_without_source_or_clr_is_rejected(self):
        module={'id':'toolbelt.conversion.safe-cast','text':'objects: []\nclr:\n  used: false\n'}
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            inventory=root/'Scripts/Install/module_sources.json'
            inventory.parent.mkdir(parents=True)
            inventory.write_text('{"schema":"toolbelt-install-sources/v1","modules":{"toolbelt.conversion.safe-cast":[]}}',encoding='utf-8')
            with patch.object(installer,'ROOT',root):
                with self.assertRaisesRegex(ValueError,'module without executable source'):
                    installer.source_files([module])

    def test_functional_inventory_is_independent_of_legacy_deployments(self):
        selected=installer.modules('Windows','local')
        sources,pins=installer.source_files(selected)
        self.assertEqual(len(sources),193)
        self.assertIn('Scripts/Install/module_sources.json',pins)
        self.assertFalse(any('/Deployment/' in path for path in pins))

    def test_source_inventory_rejects_cross_module_paths(self):
        module={'id':'toolbelt.conversion.safe-cast','text':'objects: []\nclr:\n  used: false\n'}
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            inventory=root/'Scripts/Install/module_sources.json'
            inventory.parent.mkdir(parents=True)
            inventory.write_text('{"schema":"toolbelt-install-sources/v1","modules":{"toolbelt.conversion.safe-cast":["Modules/other/Source/Other.sql"]}}',encoding='utf-8')
            with patch.object(installer,'ROOT',root):
                with self.assertRaisesRegex(ValueError,'functional source path'):
                    installer.source_files([module])

    def test_every_profile_has_create_text_for_all_declared_sql_objects(self):
        # Unabhängiger Sollbestand aus den öffentlichen Objektdeklarationen.
        # Dies ist statische Vollständigkeit, kein Beweis nativer Ausführbarkeit.
        for platform,mode in (('Windows','local'),('Windows','central'),
                              ('Portable','local'),('Portable','central')):
            selected=installer.modules(platform,mode)
            sources,_=installer.source_files(selected)
            text='\n'.join(source['sql'] for source in sources)
            names={schema+'.'+name for schema,name in re.findall(
                r'(?i)\bCREATE\s+(?:OR\s+ALTER\s+)?(?:FUNCTION|PROCEDURE|VIEW|TABLE|AGGREGATE)'
                r'\s+\[?(toolbelt_[A-Za-z]+)\]?\s*\.\s*\[?([A-Za-z][A-Za-z0-9_]*)\]?',text)}
            for module in selected:
                for obj in manifest.objects(module['text']):
                    if obj['type']!='ASSEMBLY':
                        self.assertIn(obj['schema']+'.'+obj['name'],names,
                                      (platform,mode,module['id']))

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
        legacy=subprocess.check_output(['git','show',
            '2fbe8e3e86f370b22ad2ce9f9716d971072a052b:Modules/toolbelt.filesystem.windows/Deployment/Deploy.sql'],
            cwd=ROOT).decode('utf-8-sig')
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
