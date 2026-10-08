"""Source-only phonetic contract checks; no compiler/algorithm/SQL execution."""
from pathlib import Path
import hashlib
import re
import xml.etree.ElementTree as ET
ROOT = Path(__file__).resolve().parents[2]
def need(value, code):
    if not value: raise SystemExit(code)
def text(name): return (ROOT / name).read_text(encoding="utf-8-sig")
slots = {"TVF_ColognePhonetic": ("IF", "PhoneticCode"), "TVF_DoubleMetaphone": ("IF", "PrimaryCode"), "TVF_ColognePhoneticCore": ("FT", "EvaluateCologne"), "TVF_DoubleMetaphoneCore": ("FT", "EvaluateDoubleMetaphone")}
need({p.stem for p in (ROOT / "Source").glob("*.sql")} == set(slots), "PHONETIC_STATIC_SLOTS")
for name, (kind, marker) in slots.items():
    source = text("Source/" + name + ".sql")
    first = re.sub(r"/\*.*?\*/|--[^\n]*", "", source, flags=re.S).lstrip()
    need(first.upper().startswith("CREATE FUNCTION"), "PHONETIC_STATIC_FIRST_DDL")
    need("@Text nvarchar(max)" in source and marker in source, "PHONETIC_STATIC_SIGNATURE")
    need("TOP" not in first.upper() and "COALESCE" not in first.upper(), "PHONETIC_STATIC_ROW_SHAPE")
    need("Latin1_General_100_BIN2" in source if kind == "IF" else "Toolbelt_String_Phonetic" in source and "PhoneticBridge" in source, "PHONETIC_STATIC_BINDING")
    if kind == "FT":
        definition = source.split("RETURNS TABLE (", 1)[1].split(")\nAS EXTERNAL", 1)[0]
        need(not re.search(r"(?<!n)varchar\(", definition), "PHONETIC_STATIC_UNICODE_CLR_FT")
    else:
        codes = ("PhoneticCode",) if name == "TVF_ColognePhonetic" else ("PrimaryCode", "AlternateCode")
        for code in codes:
            need("CONVERT(varchar(max)," + code + " COLLATE Latin1_General_100_BIN2) COLLATE Latin1_General_100_BIN2 AS " + code in source, "PHONETIC_STATIC_ASCII_PUBLIC_CONVERSION")
bridge = text("Clr/PhoneticBridge.cs")
need('TableDefinition = "PhoneticCode nvarchar(max), ErrorCode int"' in bridge and 'TableDefinition = "PrimaryCode nvarchar(max), AlternateCode nvarchar(max), ErrorCode int"' in bridge, "PHONETIC_STATIC_UNICODE_BRIDGE")
need(bridge.count("[SqlFunction(") == 2 and bridge.count("DataAccessKind.None") == 4, "PHONETIC_STATIC_ATTRIBUTES")
need("yield " not in bridge and "return new CologneRow[]" in bridge and "return new DoubleRow[]" in bridge, "PHONETIC_STATIC_EAGER")
need("catch (Exception" not in bridge and bridge.count("catch (PhoneticQuotaException)") == 2, "PHONETIC_STATIC_TECHNICAL_ERROR")
source = text("Clr/PhoneticInput.cs")
for token in ("MaximumInput = 4096", "MaximumTransformed = 8192", "MaximumCode = 16384", "MaximumCodePair = 32768"): need(token in source, "PHONETIC_STATIC_QUOTA")
need(source.index("length > MaximumInput") < source.index("new char[") < source.index("char.IsHighSurrogate") < source.index("bool allowed"), "PHONETIC_STATIC_PRIORITY")
double = text("Clr/DoubleMetaphoneKernel.cs")
need("while (index <= value.Length - 1)" in double and "result.append('J', ' ')" in double, "PHONETIC_STATIC_FULL_SCANNER")
for forbidden in ("isComplete", "getMaxCodeLen", "Substring(0, 4)", "ToUpper(", "ToUpperInvariant("): need(forbidden not in double, "PHONETIC_STATIC_NO_CLAMP")
need(len(re.findall(r"private static int handle", double)) == 18, "PHONETIC_STATIC_HANDLERS")
for name in ("CologneKernel.cs", "DoubleMetaphoneKernel.cs"):
    source = text("Clr/" + name)
    need(source.startswith("/*") and "Licensed to the Apache Software Foundation" in source and "Geänderter C#-Port" in source, "PHONETIC_STATIC_PORT_LICENSE")
for name, digest in {"LICENSE.txt": "CFC7749B96F63BD31C3C42B5C471BF756814053E847C10F3EB003417BC523D30", "NOTICE.txt": "B64933EE1D36D14659156223A2604EDADB60BFFDD465D5368FF422D7689DB5FB"}.items():
    need(hashlib.sha256((ROOT / "ThirdParty/ApacheCommonsCodec" / name).read_bytes()).hexdigest().upper() == digest, "PHONETIC_STATIC_LEGAL_BYTES")
preflight = text("Deployment/Preflight.sql")
need("c.system_type_id<>CASE WHEN s.Kind='FT' THEN 231 ELSE 167 END" in preflight and "c.system_type_id<>167" not in preflight, "PHONETIC_STATIC_LIFECYCLE_KIND_TYPES")
need(preflight.index("IF @@TRANCOUNT <> 0") < preflight.index("SET XACT_ABORT"), "PHONETIC_STATIC_CALLER_GUARD")
for token in ("WHILE @Pass<=2", "sys.sp_getapplock", "@ExpectedHash", "sys.assembly_files", "sys.sql_expression_dependencies", "COALESCE(o.principal_id,@SchemaOwner)", "CONVERT(varbinary(2),o.type)", "null_on_null_input=0"): need(token in preflight, "PHONETIC_STATIC_LIFECYCLE")
for forbidden in ("sp_add_trusted_assembly", "GRANT ", "TRUSTWORTHY", "RECONFIGURE", "AUTHORIZATION TO"): need(forbidden not in preflight, "PHONETIC_STATIC_NO_SECURITY_MUTATION")
project = ET.fromstring(text("Clr/Toolbelt.String.Phonetic.csproj")); ns = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
need({n.attrib["Include"] for n in project.findall(".//m:Reference", ns)} == {"System", "System.Data"}, "PHONETIC_STATIC_REFERENCES")
need(len(project.findall(".//m:Compile", ns)) == 5, "PHONETIC_STATIC_COMPILE_SET")
for name in ("README.md", "Documentation/TVF_ColognePhonetic.md", "Documentation/TVF_DoubleMetaphone.md", "Tests/PHONETIC_TEST_MATRIX.md", "Tests/README.md"): need((ROOT / name).is_file(), "PHONETIC_STATIC_DOC")
differential = ROOT / "Tests/Differential"
for name in ("run-differential-phonetic.ps1", "PhoneticDifferentialConsumer.cs", "PhoneticReferenceConsumer.java", "DifferentialCorpus.tsv", "TRANSPORT.md", "Reference.manifest.json"):
    need((differential / name).is_file(), "PHONETIC_STATIC_DIFFERENTIAL_FILES")
need(hashlib.sha256((differential / "Reference.manifest.json").read_bytes()).hexdigest().upper() == "D3839828C20B7831DF95B4362C700E67A12338BA7E3D869B35246BA9C97EEBA8", "PHONETIC_STATIC_DIFFERENTIAL_REFERENCE")
print("PASS PHONETIC_STATIC_SOURCE_ONLY")
