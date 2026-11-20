"""Reject invalid reuse instead of upgrading historical deployment proof."""
from pathlib import Path
import importlib.util
import unittest

ROOT=Path(__file__).resolve().parents[3]
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


if __name__=='__main__':unittest.main()
