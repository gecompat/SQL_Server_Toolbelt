"""Gemeinsame synthetische Sollfälle für CLR- und externen SSIS-Modellkern."""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

MODULE=Path(__file__).resolve().parents[2]
DTS="{www.microsoft.com/SqlServer/Dts}"


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host",type=Path,required=True)
    parser.add_argument("--framework-assembly",type=Path,required=True)
    parser.add_argument("--jsonschema-path",type=Path)
    args=parser.parse_args()
    if args.jsonschema_path:
        import sys
        sys.path.insert(0,str(args.jsonschema_path))
    from jsonschema import Draft202012Validator
    schema=json.loads((MODULE/"Contracts/Exchange/SSIS_Exchange_V1.schema.json").read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    validator=Draft202012Validator(schema)
    fixture=(MODULE/"Contracts/Exchange/Fixtures/direct-8.dtsx").read_bytes()
    oracle=json.loads((MODULE/"Contracts/Exchange/Fixtures/direct-8.expected.json").read_text(encoding="utf-8"))
    checks=0
    def check(condition,label):
        nonlocal checks
        if not condition: raise AssertionError(label)
        checks+=1
    def canonical(value):
        value=copy.deepcopy(value)
        value.pop("producer")
        return value
    with tempfile.TemporaryDirectory(prefix="ToolbeltSsisModelTests-") as temporary:
        root=Path(temporary)
        compiler=Path(os.environ["WINDIR"])/"Microsoft.NET/Framework64/v4.0.30319/csc.exe"
        parity=root/"FrameworkParity.exe"
        shutil.copy2(args.framework_assembly,root/args.framework_assembly.name)
        compile_result=subprocess.run([str(compiler),"/nologo","/target:exe",f"/out:{parity}",
            "/reference:System.Core.dll","/reference:System.Web.Extensions.dll",f"/reference:{args.framework_assembly}",
            str(MODULE/"Exchange/Tests/FrameworkParity.cs")],capture_output=True,text=True)
        check(compile_result.returncode==0,"framework parity harness compilation: "+compile_result.stdout)
        def run(data,expected=True):
            path=root/"synthetic.dtsx";path.write_bytes(data)
            external=subprocess.run(["dotnet",str(args.host),str(path)],capture_output=True,text=True,encoding="utf-8",timeout=40)
            framework=subprocess.run([str(parity),str(path)],capture_output=True,text=True,encoding="utf-8",timeout=40)
            if not expected:
                check(external.returncode==3 and framework.returncode==3,"invalid source rejected by both hosts")
                check(not external.stdout and not framework.stdout,"no partial output on invalid source")
                return None
            check(external.returncode==0 and framework.returncode==0,"both core hosts succeed")
            a,b=json.loads(external.stdout),json.loads(framework.stdout)
            validator.validate(a);validator.validate(b)
            check(canonical(a)==canonical(b),"same typed structure and lineage on net48 and external host")
            check(a["source"]["packageSha256"]==hashlib.sha256(data).hexdigest(),"exact original byte hash")
            check(a["source"]["byteLength"]==len(data),"exact original byte length")
            check(len({n["id"] for n in a["nodes"]})==len(a["nodes"]),"unique occurrence IDs")
            return a
        basic=run(fixture)
        check([[n["id"],n["kind"],n["parentId"]] for n in basic["nodes"]]==oracle["nodeSignatures"],"fixed independent object oracle")
        check([[e["kind"],e["fromId"],e["toId"],e["ruleId"]] for e in basic["edges"]]==oracle["edgeSignatures"],"fixed independent lineage oracle")
        check(all(c["status"]==oracle["coverageStatus"] for c in basic["coverage"]),"bounded direct-profile coverage")
        identity_schema=json.loads((MODULE/"Contracts/Exchange/SSIS_Object_Identities_V1.schema.json").read_text(encoding="utf-8"))
        identity_validator=Draft202012Validator(identity_schema)
        Draft202012Validator.check_schema(identity_schema)
        def bundle_run(data):
            path=root/"synthetic.dtsx";path.write_bytes(data)
            external=subprocess.run(["dotnet",str(args.host),"--bundle",str(path)],capture_output=True,text=True,encoding="utf-8",timeout=40)
            framework=subprocess.run([str(parity),"--bundle",str(path)],capture_output=True,text=True,encoding="utf-8",timeout=40)
            check(external.returncode==0 and framework.returncode==0,"both hosts export identity bundle")
            a,b=json.loads(external.stdout),json.loads(framework.stdout)
            check(set(a)=={"contract","version","model","identities"} and a["contract"]=="ssis-export-bundle" and a["version"]=="1.0.0","closed separate bundle transport")
            validator.validate(a["model"]);identity_validator.validate(a["identities"])
            check(canonical(a["model"])==canonical(b["model"]) and a["identities"]==b["identities"],"one common identity core on net48 and external host")
            check(a["identities"]["packageSha256"]==hashlib.sha256(data).hexdigest(),"identity sidecar bound to exact source bytes")
            check([n["nodeId"] for n in a["identities"]["objects"]]==[n["id"] for n in a["model"]["nodes"] if n["kind"] in ("PACKAGE","EXECUTABLE")],"same occurrence universe and order")
            return a
        missing=bundle_run(fixture)
        check(all(n["dtsId"] is None for n in missing["identities"]["objects"]),"missing native IDs stay null")
        identity_xml=ET.fromstring(fixture)
        identity_xml.set(DTS+"DTSID","{11111111-1111-1111-1111-111111111111}")
        identity_exe=identity_xml.find(f"{DTS}Executables/{DTS}Executable")
        identity_exe.set(DTS+"DTSID","{ABCDEF12-2222-2222-2222-222222222222}")
        identity_exe.set("DTSID","33333333-3333-3333-3333-333333333333")
        identified=bundle_run(ET.tostring(identity_xml,encoding="utf-8",xml_declaration=True))
        check([n["dtsId"] for n in identified["identities"]["objects"]]==["11111111-1111-1111-1111-111111111111","abcdef12-2222-2222-2222-222222222222"],"qualified native DTSID and canonical GUID without unqualified shadowing")
        identity_xml.find(f"{DTS}Executables").append(copy.deepcopy(identity_exe))
        duplicate=bundle_run(ET.tostring(identity_xml,encoding="utf-8",xml_declaration=True))
        check(duplicate["identities"]["objects"][1]["dtsId"]==duplicate["identities"]["objects"][2]["dtsId"] and duplicate["identities"]["objects"][1]["nodeId"]!=duplicate["identities"]["objects"][2]["nodeId"],"duplicate DTSIDs remain separate occurrences and prove no runtime match")
        identity_exe.set(DTS+"DTSID","SyntheticInvalidGuid")
        invalid_identity=bundle_run(ET.tostring(identity_xml,encoding="utf-8",xml_declaration=True))
        check(invalid_identity["identities"]["objects"][1]["dtsId"] is None,"invalid native identity remains unbound")
        run(fixture.replace(b">8</DTS:Property>",b">6</DTS:Property>"))
        root_xml=ET.fromstring(fixture)
        executable=root_xml.find(f"{DTS}Executables")
        executable.append(copy.deepcopy(executable[0]))
        repeated=run(ET.tostring(root_xml,encoding="utf-8",xml_declaration=True))
        check(len(repeated["nodes"])==16 and len(repeated["edges"])==6,"same names/native refs in different flows remain separate")
        check({e["scopeId"] for e in repeated["edges"]}=={"exe1","exe2"},"flow scopes retained")
        root_xml=ET.fromstring(fixture)
        constraints=ET.SubElement(root_xml,DTS+"PrecedenceConstraints")
        ET.SubElement(constraints,DTS+"PrecedenceConstraint",{DTS+"From":"Flow",DTS+"To":"Flow",DTS+"Expression":"@[User::SyntheticVariable]"})
        expression=run(ET.tostring(root_xml,encoding="utf-8",xml_declaration=True))
        check(next(c for c in expression["coverage"] if c["feature"]=="expressionReferences")["status"]=="PARTIAL","expression attributes cannot imply complete reference coverage")
        root_xml=ET.fromstring(fixture)
        components=root_xml.find(f"{DTS}Executables/{DTS}Executable/{DTS}ObjectData/pipeline/components")
        components.insert(0,ET.Element("component",{"refId":"Unknown","name":"SyntheticUnknown","componentClassID":"Synthetic.Unknown","version":"1"}))
        unknown=run(ET.tostring(root_xml,encoding="utf-8",xml_declaration=True))
        check(next(n for n in unknown["nodes"] if n["name"]=="SyntheticSource")["id"]=="cmp2","ID reservation precedes component support filtering")
        check(any(d["code"]=="UNKNOWN_COMPONENT" for d in unknown["diagnostics"]),"unknown component disclosed")
        root_xml=ET.fromstring(fixture)
        parameter_parent=ET.SubElement(root_xml,DTS+"PackageParameters")
        parameter=ET.SubElement(parameter_parent,DTS+"PackageParameter",{DTS+"ObjectName":"SyntheticParameter",DTS+"DataType":"130",DTS+"Sensitive":"1"})
        ET.SubElement(parameter,DTS+"Property",{DTS+"Name":"ParameterValue"}).text="SYNTHETIC_PRIVATE_LITERAL"
        private=run(ET.tostring(root_xml,encoding="utf-8",xml_declaration=True))
        check("SYNTHETIC_PRIVATE_LITERAL" not in json.dumps(private),"literal values never exported")
        run(fixture.replace(b">8</DTS:Property>",b">99</DTS:Property>"),False)
        run(b'<?xml version="1.0"?><!DOCTYPE x [<!ENTITY a "SYNTHETIC_PRIVATE_LITERAL">]>'+fixture.split(b"?>",1)[1],False)
        check(not any(word in (MODULE/"Clr/PackageModel.cs").read_text(encoding="utf-8") for word in ("XElement","XDocument","XmlReader",".Descendants(",".Element(")),"generator contains no second XML traversal")
        for file in (MODULE/"Exchange/Core").glob("*.cs"):
            check(not any(word in file.read_text(encoding="utf-8") for word in ("File.Read","File.Write","SqlConnection","HttpClient","Process.Start")),"core has no external effects")
    print(f"SSIS_EXCHANGE_CONFORMANCE_PASS checks={checks}; same core net48/external; synthetic source and graph oracles; no SQL executed")


if __name__=="__main__":
    main()
