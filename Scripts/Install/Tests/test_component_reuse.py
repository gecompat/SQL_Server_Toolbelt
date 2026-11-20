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
    def test_current_full_component_inventory_matches_declared_reuse_scope(self):
        self.assertGreater(module.verify(),0)

    def test_only_sql_assembly_binding_and_comment_alias_are_permitted(self):
        old=b'-- Toolbelt_String_Regex\nAS EXTERNAL NAME [Toolbelt_String_Regex].[Contoso.Provider].[Invoke];'
        new=old.replace(b'Toolbelt_String_Regex',b'tlblt_String_Regex')
        module.compare(old,new,'Modules/Contoso/Source/Contoso.sql')

    def test_business_sql_change_is_rejected(self):
        with self.assertRaises(ValueError):
            module.compare(b'SELECT 1;',b'SELECT 2;','Modules/Contoso/Source/Contoso.sql')

    def test_non_binding_string_or_class_alias_is_rejected(self):
        for old in (b"SELECT N'Toolbelt_String_Regex';",b'AS EXTERNAL NAME [Contoso].[Toolbelt_String_Regex].[Invoke];'):
            with self.subTest(old=old),self.assertRaises(ValueError):
                module.compare(old,old.replace(b'Toolbelt_String_Regex',b'tlblt_String_Regex'),'Modules/Contoso/Source/Contoso.sql')

    def test_clr_changes_are_never_normalized(self):
        with self.assertRaises(ValueError):
            module.compare(b'Toolbelt_String_Regex',b'tlblt_String_Regex','Modules/Contoso/Clr/Provider.cs')

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
