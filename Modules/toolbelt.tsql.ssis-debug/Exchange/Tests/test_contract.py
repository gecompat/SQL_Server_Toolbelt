"""Gemeinsame synthetische SollfÃ¤lle fÃ¼r CLR- und externen SSIS-Modellkern."""
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
        iteration_schema=json.loads((MODULE/"Contracts/Exchange/SSIS_Object_Identities_V1_1.schema.json").read_text(encoding="utf-8"))
        iteration_validator=Draft202012Validator(iteration_schema)
        Draft202012Validator.check_schema(iteration_schema)
        scope_validator=Draft202012Validator(json.loads((MODULE/"Contracts/Exchange/SSIS_Object_Identities_V1_2.schema.json").read_text(encoding="utf-8")))
        pipeline_validator=Draft202012Validator(json.loads((MODULE/"Contracts/Exchange/SSIS_Pipeline_Identities_V1.schema.json").read_text(encoding="utf-8")))
        def bundle_run(data,iterations=False,scopes=False,pipelines=False):
            path=root/"synthetic.dtsx";path.write_bytes(data)
            option="--pipeline-bundle" if pipelines else "--scope-bundle" if scopes else "--iteration-bundle" if iterations else "--bundle"
            external=subprocess.run(["dotnet",str(args.host),option,str(path)],capture_output=True,text=True,encoding="utf-8",timeout=40)
            framework=subprocess.run([str(parity),option,str(path)],capture_output=True,text=True,encoding="utf-8",timeout=40)
            check(external.returncode==0 and framework.returncode==0,"both hosts export identity bundle")
            a,b=json.loads(external.stdout),json.loads(framework.stdout)
            check(set(a)==({"contract","version","model","identities","pipelineIdentities"} if pipelines else {"contract","version","model","identities"}) and a["contract"]=="ssis-export-bundle" and a["version"]=="1.0.0","closed separate bundle transport")
            validator.validate(a["model"]);(scope_validator if scopes or pipelines else iteration_validator if iterations else identity_validator).validate(a["identities"])
            check(canonical(a["model"])==canonical(b["model"]) and a["identities"]==b["identities"],"one common identity core on net48 and external host")
            check(a["identities"]["packageSha256"]==hashlib.sha256(data).hexdigest(),"identity sidecar bound to exact source bytes")
            check([n["nodeId"] for n in a["identities"]["objects"]]==[n["id"] for n in a["model"]["nodes"] if n["kind"] in ("PACKAGE","EXECUTABLE")],"same occurrence universe and order")
            if pipelines:
                pipeline_validator.validate(a["pipelineIdentities"])
                check(a["pipelineIdentities"]==b["pipelineIdentities"],"one shared pipeline identity projection")
                check(a["pipelineIdentities"]["packageSha256"]==hashlib.sha256(data).hexdigest(),"pipeline identities bound to bytes")
            return a
        missing=bundle_run(fixture)
        check(all(n["dtsId"] is None for n in missing["identities"]["objects"]),"missing native IDs stay null")
        check(all("iterationContainer" not in n for n in missing["identities"]["objects"]),"legacy 1.0 sidecar stays unchanged")
        for executable_type,expected in (("STOCK:FORLOOP",True),("STOCK:FOREACHLOOP",True),("STOCK:SEQUENCE",False),("SyntheticCustomForLoop",False)):
            loop_xml=ET.fromstring(fixture)
            loop_exe=loop_xml.find(f"{DTS}Executables/{DTS}Executable")
            loop_exe.set(DTS+"ExecutableType",executable_type)
            loop_exe.set(DTS+"ObjectName","STOCK:FORLOOP")
            loop_bundle=bundle_run(ET.tostring(loop_xml,encoding="utf-8",xml_declaration=True),True)
            check([n["iterationContainer"] for n in loop_bundle["identities"]["objects"]]==[False,expected],"qualified loop role independent of display name: "+executable_type)
        scope_xml=ET.fromstring(fixture)
        scope_exe=scope_xml.find(f"{DTS}Executables/{DTS}Executable")
        scope_exe.set(DTS+"ExecutableType","Microsoft.ExecutePackageTask")
        scope_exe.set(DTS+"refId","Package\\SyntheticCall")
        object_data=scope_exe.find(DTS+"ObjectData")
        task=ET.SubElement(object_data,"ExecutePackageTask")
        ET.SubElement(task,"UseProjectReference").text="True"
        ET.SubElement(task,"PackageName").text="SyntheticChild.dtsx"
        scope_payload=ET.tostring(scope_xml,encoding="utf-8",xml_declaration=True)
        scoped=bundle_run(scope_payload,scopes=True)
        check(scoped["identities"]["objects"][1]["callTarget"]=="SyntheticChild.dtsx","explicit same-project call target")
        task.find("UseProjectReference").text="False"
        check(bundle_run(ET.tostring(scope_xml,encoding="utf-8",xml_declaration=True),scopes=True)["identities"]["objects"][1]["callTarget"] is None,"external package reference remains unqualified")
        task.find("UseProjectReference").text="True"
        duplicate_target=ET.SubElement(task,"PackageName");duplicate_target.text="SyntheticOther.dtsx"
        check(bundle_run(ET.tostring(scope_xml,encoding="utf-8",xml_declaration=True),scopes=True)["identities"]["objects"][1]["callTarget"] is None,"duplicate call target cannot select first property")
        task.remove(duplicate_target)
        expression=ET.SubElement(scope_exe,DTS+"PropertyExpression",{DTS+"Name":"PackageName"});expression.text='"SyntheticChild.dtsx"'
        check(bundle_run(ET.tostring(scope_xml,encoding="utf-8",xml_declaration=True),scopes=True)["identities"]["objects"][1]["callTarget"] is None,"expression target remains unqualified")
        scope_exe.remove(expression)
        handlers=ET.SubElement(scope_xml,DTS+"EventHandlers")
        handler=ET.SubElement(handlers,DTS+"EventHandler",{DTS+"refId":"Package.EventHandlers[OnError]",DTS+"EventName":"OnError"})
        scoped=bundle_run(ET.tostring(scope_xml,encoding="utf-8",xml_declaration=True),scopes=True)
        eh=scoped["identities"]["objects"][-1]
        check(eh["scopeKind"]=="HANDLER" and eh["parentId"]=="pkg1" and eh["steps"]==[{"text":"\\OnError","counter":False}],"handler role and runtime steps from qualified native declaration")
        pipeline_xml=ET.fromstring(fixture)
        pipeline_flow=pipeline_xml.find(f"{DTS}Executables/{DTS}Executable")
        pipeline_flow.set(DTS+"refId","Package\\SyntheticFlow")
        aliases={}
        for component in pipeline_flow.findall(f"{DTS}ObjectData/pipeline/components/component"):
            old=component.get("refId");new="Package\\SyntheticFlow\\"+component.get("name");aliases[old]=new;component.set("refId",new)
            for group,tag,role in (("outputs","output","Outputs"),("inputs","input","Inputs")):
                for port in component.findall(group+"/"+tag):
                    old=port.get("refId");new=component.get("refId")+"."+role+"["+port.get("name")+"]";aliases[old]=new;port.set("refId",new)
        for path in pipeline_flow.findall(f"{DTS}ObjectData/pipeline/paths/path"):
            path.set("refId","Package\\SyntheticFlow.Paths[SyntheticTransfer]");path.set("name","SyntheticTransfer")
            path.set("startId",aliases[path.get("startId")]);path.set("endId",aliases[path.get("endId")])
        pipeline_bundle=bundle_run(ET.tostring(pipeline_xml,encoding="utf-8",xml_declaration=True),pipelines=True)
        identities=pipeline_bundle["pipelineIdentities"]["pipelines"][0]
        check(identities["nodeId"]=="exe1" and len(identities["components"])==2,"pipeline refers to canonical flow and components")
        check(identities["paths"][0]["identificationString"]=="Paths[SyntheticSource.SyntheticOutput]" and identities["paths"][0]["name"]=="SyntheticTransfer","SDK identification uses source output rather than display path name")
        check(any(e["id"]==identities["paths"][0]["edgeId"] and e["kind"]=="PIPELINE_PATH" and e["fromId"]==identities["paths"][0]["fromPortId"] for e in pipeline_bundle["model"]["edges"]),"pipeline path reuses canonical edge and port")
        altered=copy.deepcopy(pipeline_xml);altered.find(f"{DTS}Executables/{DTS}Executable/{DTS}ObjectData/pipeline/paths/path").set("refId","SyntheticWrongReference")
        check(bundle_run(ET.tostring(altered,encoding="utf-8",xml_declaration=True),pipelines=True)["pipelineIdentities"]["pipelines"][0]["paths"][0]["profileStatus"]=="UNQUALIFIED","unsupported path syntax never becomes runtime identity")
        identity_xml=ET.fromstring(fixture)
        identity_xml.set(DTS+"DTSID","{11111111-1111-1111-1111-111111111111}")
        identity_exe=identity_xml.find(f"{DTS}Executables/{DTS}Executable")
        identity_exe.set(DTS+"refId","Package\\SyntheticFlow")
        # Rollen folgen dem qualifizierten Komponentenprofil und der nativen
        # Ausgangsreihenfolge; beliebige Anzeigenamen sind keine Semantik.
        role_xml=ET.fromstring(fixture)
        role_component=next(role_xml.iter("component"))
        role_component.set("componentClassID","Microsoft.Lookup");role_component.set("version","6")
        props=role_component.find("properties")
        if props is None: props=ET.SubElement(role_component,"properties")
        ET.SubElement(props,"property",{"name":"NoMatchBehavior"}).text="1"
        outputs=role_component.find("outputs")
        for child in list(outputs): outputs.remove(child)
        for index in range(2):
            ET.SubElement(outputs,"output",{"refId":"SyntheticRoleOutput"+str(index),"name":"SyntheticRenamed"+str(index),"isErrorOut":"false"})
        roles=run(ET.tostring(role_xml,encoding="utf-8",xml_declaration=True))
        check(next(n for n in roles["nodes"] if n["name"]=="SyntheticRenamed1")["attributes"]["portRole"]=="NO_MATCH","lookup ordered second output without name inference")
        role_component.set("version","999")
        roles=run(ET.tostring(role_xml,encoding="utf-8",xml_declaration=True))
        check(next(n for n in roles["nodes"] if n["name"]=="SyntheticRenamed1")["attributes"]["portRole"]=="UNKNOWN","unknown profile has no no-match role")
        role_component.set("version","6")
        ET.SubElement(outputs,"output",{"refId":"SyntheticRoleOutput2","name":"SyntheticRenamed2","isErrorOut":"false"})
        roles=run(ET.tostring(role_xml,encoding="utf-8",xml_declaration=True))
        check(next(n for n in roles["nodes"] if n["name"]=="SyntheticRenamed1")["attributes"]["portRole"]=="UNKNOWN","ambiguous output shape remains unknown")
        identity_exe.set(DTS+"DTSID","{ABCDEF12-2222-2222-2222-222222222222}")
        identity_exe.set("DTSID","33333333-3333-3333-3333-333333333333")
        identified=bundle_run(ET.tostring(identity_xml,encoding="utf-8",xml_declaration=True))
        check([n["dtsId"] for n in identified["identities"]["objects"]]==["11111111-1111-1111-1111-111111111111","abcdef12-2222-2222-2222-222222222222"],"qualified native DTSID and canonical GUID without unqualified shadowing")
        check([n["packagePath"] for n in identified["identities"]["objects"]]==["\\Package","\\Package\\SyntheticFlow"],"qualified native refId yields package path without name-based reconstruction")
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
