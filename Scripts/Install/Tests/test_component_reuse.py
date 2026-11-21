"""Reject invalid reuse instead of upgrading historical deployment proof."""
from pathlib import Path
import importlib.util
import unittest
import sys

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'Scripts/Metadata'))
import usage_skills

spec=importlib.util.spec_from_file_location('component_reuse',ROOT/'Scripts/Install/Verify-ComponentReuse.py')
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)


class ComponentReuseTests(unittest.TestCase):
    def test_reviewed_standard_help_restore_exposes_guard_and_business_changes(self):
        sys.path.insert(0,str(ROOT/'Scripts/Documentation'))
        from generate_parameter_help import help_span
        item={'name':'USP_Contoso'}
        file='Modules/toolbelt.test/Source/USP_Contoso.sql'
        original="CREATE PROCEDURE x.USP_Contoso @Hilfe bit=0 AS BEGIN IF @Hilfe=1 BEGIN SELECT N'old'; RETURN 0; END; SELECT 17; END;"
        projected=original.replace("N'old'","N'current'")
        expected=projected[slice(*help_span(projected,item))]
        def restore(text):
            return module.restore_reviewed_standard_help(original.encode(),text,file,[(item,expected)],help_span)
        self.assertEqual(restore(projected),original)
        with self.assertRaisesRegex(ValueError,'STANDARD_HELP_DRIFT'):
            restore(projected.replace("N'current'","N'unknown'"))
        for old,new in (('IF @Hilfe=1','IF @Hilfe=0'),('SELECT 17','SELECT 18')):
            with self.subTest(old=old),self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                module.compare(original.encode(),restore(projected.replace(old,new)).encode(),file)

    def test_current_full_inventory_separates_unchanged_files_from_declared_deltas(self):
        self.assertGreater(module.verify(allow_current_deltas=True),0)

    def test_strict_reuse_still_rejects_a_functionally_changed_module(self):
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.verify(module_ids=['toolbelt.json.path-exists'])

    def test_only_sql_assembly_binding_and_comment_alias_are_permitted(self):
        old=b'-- Toolbelt_String_Regex\nAS EXTERNAL NAME [Toolbelt_String_Regex].[Contoso.Provider].[Invoke];'
        new=old.replace(b'Toolbelt_String_Regex',b'tlblt_String_Regex')
        module.compare(old,new,'Modules/Contoso/Source/Contoso.sql')

    def test_business_sql_change_is_rejected(self):
        with self.assertRaises(ValueError):
            module.compare(b'SELECT 1;',b'SELECT 2;','Modules/Contoso/Source/Contoso.sql')

    def test_identifier_scalar_rights_comment_repair_keeps_every_business_byte_bound(self):
        old=module.IDENTIFIER_SCALAR_RIGHTS_OLD+b'\nRETURN 1;'
        current=module.IDENTIFIER_SCALAR_RIGHTS_NEW+b'\nRETURN 1;'
        module.compare(old,current,module.IDENTIFIER_SCALAR_PATH)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(old,current.replace(b'RETURN 1;',b'RETURN 2;'),module.IDENTIFIER_SCALAR_PATH)

    def test_exact_event_help_example_repair_never_admits_business_changes(self):
        old=(b'    IF ISNULL(@Hilfe, 0) = 1\n    BEGIN\nSELECT '
             +module.EVENT_HELP_OLD+b';\n        RETURN 0;\n    END;\nINSERT Contoso VALUES(1);')
        current=old.replace(module.EVENT_HELP_OLD,module.EVENT_HELP_NEW)
        module.compare(old,current,module.EVENT_HELP_PATH)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(old,current.replace(b'VALUES(1)',b'VALUES(2)'),module.EVENT_HELP_PATH)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(old,current,'Modules/Contoso/Source/Example.sql')
        outside=b'SELECT '+module.EVENT_HELP_OLD+b';'
        with self.assertRaisesRegex(ValueError,'NONCANONICAL_EVENT_HELP_EXAMPLE'):
            module.compare(outside,outside.replace(module.EVENT_HELP_OLD,module.EVENT_HELP_NEW),module.EVENT_HELP_PATH)

    def test_non_binding_string_or_class_alias_is_rejected(self):
        for old in (b"SELECT N'Toolbelt_String_Regex';",b'AS EXTERNAL NAME [Contoso].[Toolbelt_String_Regex].[Invoke];'):
            with self.subTest(old=old),self.assertRaises(ValueError):
                module.compare(old,old.replace(b'Toolbelt_String_Regex',b'tlblt_String_Regex'),'Modules/Contoso/Source/Contoso.sql')

    def test_schema_help_description_repair_is_confined_to_original_early_branch(self):
        old=(b' IF @Hilfe=1\n BEGIN\nSELECT N\''+module.SCHEMA_HELP_OLD+
             b"';\n        RETURN 0;\n END;\nSELECT 7;")
        current=old.replace(module.SCHEMA_HELP_OLD,module.SCHEMA_HELP_NEW)
        module.compare(old,current,module.SCHEMA_HELP_PATH)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),module.SCHEMA_HELP_PATH)
        with self.assertRaises(ValueError):
            module.compare(old,current,'Modules/Contoso/Source/Example.sql')
        outside=b"SELECT N'"+module.SCHEMA_HELP_OLD+b"';"
        with self.assertRaisesRegex(ValueError,'NONCANONICAL_SCHEMA_HELP_DESCRIPTION'):
            module.compare(outside,outside.replace(module.SCHEMA_HELP_OLD,module.SCHEMA_HELP_NEW),module.SCHEMA_HELP_PATH)

    def test_queue_help_repairs_are_confined_to_exact_public_positive_branch(self):
        for path,start in module.QUEUE_HELP_STARTS.items():
            old=start+b"SELECT N'"+module.SCHEMA_HELP_OLD+b"';\n        RETURN 0;\n END;\nUPDATE Contoso SET Value=7;"
            current=old.replace(module.SCHEMA_HELP_OLD,module.QUEUE_HELP_NEW)
            module.compare(old,current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                module.compare(old,current.replace(b'Value=7',b'Value=8'),path)
            with self.assertRaisesRegex(ValueError,'NONCANONICAL_QUEUE_HELP_DESCRIPTION'):
                module.compare(old.replace(b'@Hilfe',b'@ContosoHilfe',1),current,path)
            with self.assertRaises(ValueError):module.compare(old,current,'Modules/Contoso/Source/Other.sql')

    def test_retry_status_description_repair_stays_inside_original_help(self):
        path='Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetry.sql';start=module.QUEUE_HELP_STARTS[path]
        old=start+b'SELECT '+module.RETRY_HELP_STATUS_OLD+b",N'"+module.SCHEMA_HELP_OLD+b"';\n        RETURN 0;\n END;\nSELECT 7;"
        current=old.replace(module.SCHEMA_HELP_OLD,module.QUEUE_HELP_NEW).replace(module.RETRY_HELP_STATUS_OLD,module.RETRY_HELP_STATUS_NEW)
        module.compare(old,current,path)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),path)
        outside=start+b"SELECT N'"+module.SCHEMA_HELP_OLD+b"';\n        RETURN 0;\n END;\nSELECT "+module.RETRY_HELP_STATUS_OLD+b';'
        with self.assertRaisesRegex(ValueError,'NONCANONICAL_RETRY_HELP_STATUS'):
            module.compare(outside,outside.replace(module.RETRY_HELP_STATUS_OLD,module.RETRY_HELP_STATUS_NEW),path)

    def test_clone_help_repairs_cannot_change_executor_hash_or_business_code(self):
        for path in module.CLONE_HELP_PATHS:
            old=(b'    IF @Hilfe=1\n    BEGIN\nSELECT N\''+module.SCHEMA_HELP_OLD+
                 (module.CLONE_HASH_NOTE_OLD if path.endswith('/USP_ExecuteTableClone.sql') else b'')+
                 b"';\n        RETURN 0;\n END;\nSET @Text=N'4.1.1';")
            current=old.replace(module.SCHEMA_HELP_OLD,module.QUEUE_HELP_NEW).replace(module.CLONE_HASH_NOTE_OLD,module.CLONE_HASH_NOTE_NEW)
            module.compare(old,current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                module.compare(old,current.replace(b"SET @Text=N'4.1.1'",b"SET @Text=N'4.1.0'"),path)
            with self.assertRaisesRegex(ValueError,'NONCANONICAL_CLONE_HELP'):
                module.compare(old.replace(b'@Hilfe',b'@Other'),current,path)
            with self.assertRaises(ValueError):module.compare(old,current,'Modules/Contoso/Source/Other.sql')

    def test_ssis_help_repairs_stay_in_the_generated_help_batch(self):
        for path,start,end in ((module.SSIS_PUBLIC_PATH,b'    IF @Hilfe=1\n    BEGIN\n',b'        RETURN;'),
                               (module.SSIS_HELP_PATH,b'        internal const string Sql = @"',b'        internal const string Columns = ')):
            old=start+b"SELECT N'"+module.SCHEMA_HELP_OLD+b"';\n"+end+b'\nSELECT 7;'
            current=old.replace(module.SCHEMA_HELP_OLD,module.SSIS_HELP_NEW)
            module.compare(old,current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),path)
            with self.assertRaisesRegex(ValueError,'NONCANONICAL_SSIS_HELP'):
                module.compare(old.replace(start,b'Contoso'),current,path)
            with self.assertRaises(ValueError):module.compare(old,current,'Modules/Contoso/Source/Other.sql')

    def test_xlsx_help_repair_never_admits_business_or_guard_changes(self):
        for path in module.XLSX_HELP_PATHS:
            old=(b'    IF @Hilfe=1\n    BEGIN\nSELECT N\''+module.SCHEMA_HELP_OLD+
                 b"';\n        RETURN 0;\n END;\nSELECT 7;")
            current=old.replace(module.SCHEMA_HELP_OLD,module.QUEUE_HELP_NEW)
            module.compare(old,current,path)
            with self.assertRaisesRegex(ValueError,'NONCANONICAL_XLSX_HELP'):
                module.compare(old.replace(b'@Hilfe',b'@Other'),current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),path)
            with self.assertRaises(ValueError):module.compare(old,current,'Modules/Contoso/Source/Other.sql')

    def test_archive_help_repairs_are_scoped_to_original_positive_help_branches(self):
        for path,start in module.ARCHIVE_HELP_STARTS.items():
            old=start+b"SELECT N'"+module.SCHEMA_HELP_OLD+b"';\n        RETURN 0;\n END;\nSELECT 7;"
            current=old.replace(module.SCHEMA_HELP_OLD,module.QUEUE_HELP_NEW)
            module.compare(old,current,path)
            with self.assertRaisesRegex(ValueError,'NONCANONICAL_ARCHIVE_HELP'):
                module.compare(old.replace(b'@Hilfe',b'@Other'),current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),path)
            with self.assertRaises(ValueError):
                module.compare(old,current,'Modules/Contoso/Source/Other.sql')

    def test_constructor_help_repairs_do_not_admit_business_or_other_path_changes(self):
        start=b' IF @Hilfe=1\n BEGIN\n'
        old=start+b"SELECT N'"+module.SCHEMA_HELP_OLD+b"';\n        RETURN 0;\n END;\nSELECT 7;"
        current=old.replace(module.SCHEMA_HELP_OLD,module.QUEUE_HELP_NEW)
        for path in module.JSON_CONSTRUCTOR_HELP_PATHS:
            module.compare(old,current,path)
            with self.assertRaisesRegex(ValueError,'NONCANONICAL_JSON_CONSTRUCTOR_HELP'):
                module.compare(old.replace(b'@Hilfe',b'@Other'),current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),path)
        with self.assertRaises(ValueError):
            module.compare(old,current,'Modules/Contoso/Source/Other.sql')

    def test_lookup_help_and_header_repairs_do_not_admit_business_changes(self):
        start=b'    IF @Hilfe = 1\n    BEGIN\n'
        old=start+b"SELECT N'"+module.SCHEMA_HELP_OLD+b"';\n        RETURN 0;\n END;\nSELECT 7;"
        current=old.replace(module.SCHEMA_HELP_OLD,module.QUEUE_HELP_NEW)
        module.compare(old,current,module.PSEUDONYM_HELP_PATH)
        with self.assertRaisesRegex(ValueError,'NONCANONICAL_LOOKUP_HELP_DESCRIPTION'):
            module.compare(old.replace(b'@Hilfe',b'@Other'),current,module.PSEUDONYM_HELP_PATH)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),module.PSEUDONYM_HELP_PATH)
        old=module.PSEUDONYM_CORE_HEADER_OLD+b'\nSELECT 7;'
        current=module.PSEUDONYM_CORE_HEADER_NEW+b'\nSELECT 7;'
        module.compare(old,current,module.PSEUDONYM_CORE_PATH)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),module.PSEUDONYM_CORE_PATH)
        with self.assertRaises(ValueError):
            module.compare(old,current,'Modules/Contoso/Source/Other.sql')

    def test_get_status_seven_state_help_repair_is_not_business_normalization(self):
        path='Modules/toolbelt.core.work-queue/Source/USP_GetWorkStatus.sql';start=module.QUEUE_HELP_STARTS[path]
        old=start+b'SELECT '+module.RETRY_HELP_STATUS_OLD+b",N'"+module.SCHEMA_HELP_OLD+b"';\n        RETURN 0;\n END;\nSELECT 7;"
        current=old.replace(module.SCHEMA_HELP_OLD,module.QUEUE_HELP_NEW).replace(module.RETRY_HELP_STATUS_OLD,module.GET_HELP_STATUS_NEW)
        module.compare(old,current,path)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(old,current.replace(b'SELECT 7;',b'SELECT 8;'),path)
        outside=start+b"SELECT N'"+module.SCHEMA_HELP_OLD+b"';\n        RETURN 0;\n END;\nSELECT "+module.RETRY_HELP_STATUS_OLD+b';'
        with self.assertRaisesRegex(ValueError,'NONCANONICAL_GET_STATUS_HELP'):
            module.compare(outside,outside.replace(module.RETRY_HELP_STATUS_OLD,module.GET_HELP_STATUS_NEW),path)

    def test_worker_config_help_description_repairs_never_admit_nonhelp_sql(self):
        old=(b' IF ISNULL(@Hilfe,0)=1 BEGIN\nSELECT N\''+module.SCHEMA_HELP_OLD+
             b"';\n        RETURN 0;\n END;\nUPDATE Contoso SET Value=7;")
        current=old.replace(module.SCHEMA_HELP_OLD,module.WORKER_CONFIG_HELP_NEW)
        for path in module.WORKER_CONFIG_HELP_PATHS:
            module.compare(old,current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                module.compare(old,current.replace(b'Value=7',b'Value=8'),path)
            with self.assertRaisesRegex(ValueError,'NONCANONICAL_WORKER_CONFIG_HELP_DESCRIPTION'):
                module.compare(old.replace(b'=1 BEGIN',b'=0 BEGIN'),current,path)
        with self.assertRaises(ValueError):module.compare(old,current,'Modules/Contoso/Source/Example.sql')

    def test_arbitrary_clr_changes_are_never_normalized(self):
        with self.assertRaises(ValueError):
            module.compare(b'Toolbelt_String_Regex',b'tlblt_String_Regex','Modules/Contoso/Clr/Provider.cs')

    def test_exact_new_clr_help_does_not_hide_changed_business_validation(self):
        import clr_usage_skills
        records=clr_usage_skills.module_records(ROOT,'toolbelt.filesystem.windows')
        path='Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs'
        records=[record for record in records if record.metadata['source_paths'][1]==path]
        current=(ROOT/path).read_text(encoding='utf-8')
        original=clr_usage_skills.strip_provider_help(current,records)
        changed=current.replace('if (byteOffset < 0 ||','if (byteOffset < 1 ||',1)
        self.assertNotEqual(changed,current)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(original.encode(),clr_usage_skills.strip_provider_help(changed,records).encode(),path)

    def test_canonical_skill_comment_does_not_hide_changed_function_logic(self):
        source=usage_skills.read(ROOT/'Metadata/UsageSkills/toolbelt_binary/TVF_GetBitBigInt.md')
        path=source.metadata['source_paths'][0]
        current=(ROOT/path).read_text(encoding='utf-8-sig')
        original=usage_skills.strip_ddl_projection(ROOT,path,current)
        self.assertIn(usage_skills.DDL_BEGIN,current)
        # A real statement change outside the admitted comment remains visible.
        changed=current.replace('RETURN\n(', 'RETURN\n(SELECT 2 AS Changed UNION ALL ',1)
        self.assertNotEqual(changed,current)
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(original.encode(),usage_skills.strip_ddl_projection(ROOT,path,changed).encode(),path)

    def test_arbitrary_comment_addition_does_not_gain_reuse_authority(self):
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(b'SELECT 1;',b'-- undocumented exception\nSELECT 1;','Modules/Contoso/Source/Contoso.sql')

    def test_added_skill_help_cannot_hide_changed_output_assignments(self):
        source=usage_skills.read(ROOT/'Metadata/UsageSkills/toolbelt_core/USP_SecondSessionProbe.md')
        path=source.metadata['source_paths'][0]
        current=(ROOT/path).read_text(encoding='utf-8-sig')
        original=usage_skills.strip_ddl_projection(ROOT,path,usage_skills.strip_help_projection(ROOT,path,current))
        changed=current.replace('SET @RemoteSessionId = @@SPID;', 'SET @RemoteSessionId = @@SPID + 1;',1)
        self.assertNotEqual(changed,current)
        remainder=usage_skills.strip_ddl_projection(ROOT,path,usage_skills.strip_help_projection(ROOT,path,changed))
        with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
            module.compare(original.encode(),remainder.encode(),path)


if __name__=='__main__':unittest.main()
