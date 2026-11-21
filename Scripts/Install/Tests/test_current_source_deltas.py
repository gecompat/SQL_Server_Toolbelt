"""Focused source-change admission, explicitly not native SQL qualification."""
from pathlib import Path
import importlib.util
import io
import subprocess
import sys
import tarfile
import unittest

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'Scripts/Install'))
sys.path.insert(0,str(ROOT/'Scripts/Metadata'))
import current_source_deltas as deltas
import usage_skills
spec=importlib.util.spec_from_file_location('delta_component_gate',ROOT/'Scripts/Install/Verify-ComponentReuse.py')
gate=importlib.util.module_from_spec(spec);spec.loader.exec_module(gate)


class CurrentSourceDeltaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        raw=subprocess.check_output(['git','archive','--format=tar',gate.BASELINE,*sorted(deltas.PATHS)],cwd=ROOT,timeout=30)
        with tarfile.open(fileobj=io.BytesIO(raw),mode='r:') as archive:
            cls.originals={m.name:archive.extractfile(m).read() for m in archive if m.isfile()}

    def test_only_five_exact_functional_changes_are_admitted(self):
        self.assertEqual(set(self.originals),set(deltas.PATHS))
        for path,original in self.originals.items():
            current=usage_skills.strip_ddl_projection(ROOT,path,(ROOT/path).read_text(encoding='utf-8')).encode('utf-8')
            expected=deltas.apply(original,path)
            gate.compare(expected,current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                gate.compare(original,current,path)
            with self.assertRaisesRegex(ValueError,'COMPONENT_REUSE_NOT_PROVEN'):
                gate.compare(expected,current+b'\nSELECT 42;\n',path)

    def test_uri_guard_is_procedural_and_precedes_hex_conversion(self):
        fixed=deltas.apply(self.originals[deltas.URI],deltas.URI).decode('utf-8')
        self.assertLess(fixed.index('IF EXISTS'),fixed.index('    DECLARE @Output'))
        self.assertLess(fixed.index("VALUES(NULL,0,10,'INVALID'); RETURN;"),fixed.index('HexValue=STRING_AGG'))
        # Arithmetic counterexample only: not a SQL-CONVERT runtime assertion.
        digits='0123456789ABCDEF';code=256
        old=digits[code//16:code//16+1]+digits[code%16:code%16+1]
        self.assertEqual(len(old),1)

    def test_json_equality_has_length_and_identifier_reader_has_consistent_units(self):
        fixed=deltas.apply(self.originals[deltas.JSON_PATH],deltas.JSON_PATH).decode('utf-8')
        self.assertEqual(fixed.count('AND DATALENGTH(child.[key])=DATALENGTH(@Token)'),2)
        self.assertIn('@RawUnit COLLATE Latin1_General_100_BIN2=N\'"\'',fixed)
        identifier=deltas.apply(self.originals[deltas.IDENTIFIER],deltas.IDENTIFIER).decode('utf-8')
        self.assertEqual(identifier.count('SUBSTRING(@MultipartName COLLATE Latin1_General_100_BIN2,'),2)
        self.assertIn('DATALENGTH(@CurrentPart) / 2 > 128',identifier)
        self.assertIn('DATALENGTH(ISNULL(PartValue, N\'\'))=0',identifier)
        self.assertNotIn('NULLIF(@CurrentPart',identifier)
        for path in (deltas.TRIM_N,deltas.TRIM_V):
            text=deltas.apply(self.originals[path],path).decode('utf-8')
            self.assertNotIn('@Value COLLATE Latin1_General_100_BIN2',text)
            self.assertIn('VALUES (SUBSTRING(@Value, positions.Value, 1))',text)
            self.assertIn('CHARINDEX(character_at_position.CharacterValue, @Characters)',text)
            self.assertIn('WHEN DATALENGTH(character_at_position.CharacterValue) = 0 THEN 1',text)

    def test_unknown_or_drifted_original_is_rejected(self):
        with self.assertRaisesRegex(ValueError,'UNKNOWN_PATH'):deltas.apply(b'SELECT 1;','Contoso.sql')
        for path in deltas.PATHS:
            with self.assertRaisesRegex(ValueError,'ANCHOR'):deltas.apply(b'SELECT 1;',path)


if __name__=='__main__':unittest.main()
