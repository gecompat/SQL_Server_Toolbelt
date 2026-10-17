"""Nur synthetische DTSX2-Strukturen, keine aus fremden Paketen kopierten Inhalte."""
from pathlib import Path
import xml.etree.ElementTree as E

D = "www.microsoft.com/SqlServer/Dts"
E.register_namespace("DTS", D)
CLASSES = {
    "source": ("Microsoft.OLEDBSource", "{165A526D-D5DE-47FF-96A6-F8274C19826B}", 7),
    "union": ("Microsoft.UnionAll", "{B594E9A8-4351-4939-891C-CFE1AB93E925}", 1),
    "derived": ("Microsoft.DerivedColumn", "{49928E82-9C4E-49F0-AABE-3812B82707EC}", 1),
    "lookup": ("Microsoft.Lookup", "{671046B0-AA63-4C9F-90E4-C06E0B710CE3}", 6),
    "split": ("Microsoft.ConditionalSplit", "{7F88F654-4E20-4D14-84F4-AF9C925D3087}", 1),
    "destination": ("Microsoft.OLEDBDestination", "{4ADA7EAA-136C-4215-8098-D7A7C27FC0D1}", 4),
}


def build(format_version):
    def d(name): return f"{{{D}}}{name}"
    root = E.Element(d("Executable"), {d("refId"): "Package", d("ExecutableType"): "SSIS.Package.3" if format_version == 6 else "Microsoft.Package"})
    E.SubElement(root, d("Property"), {d("Name"): "PackageFormatVersion"}).text = str(format_version)
    variables = E.SubElement(root, d("Variables"))
    variable_ids = {}
    for index, (name, value) in enumerate([("SourceFloor", 0), ("LookupFloor", 0), ("Offset", 1), ("Threshold", 100)], 1):
        variable_ids[name] = "{11111111-1111-1111-1111-" + str(index).zfill(12) + "}"
        v = E.SubElement(variables, d("Variable"), {d("Namespace"): "User", d("ObjectName"): name, d("DTSID"): variable_ids[name]})
        E.SubElement(v, d("VariableValue"), {d("DataType"): "3"}).text = str(value)
    managers = E.SubElement(root, d("ConnectionManagers"))
    E.SubElement(managers, d("ConnectionManager"), {d("refId"): "Package.ConnectionManagers[Synthetic]", d("CreationName"): "OLEDB", d("ObjectName"): "Synthetic"})
    tasks = E.SubElement(root, d("Executables"))
    task = E.SubElement(tasks, d("Executable"), {d("refId"): r"Package\Flow", d("ExecutableType"): "SSIS.Pipeline.3" if format_version == 6 else "Microsoft.Pipeline", d("ObjectName"): "Synthetic Flow"})
    pipeline = E.SubElement(E.SubElement(task, d("ObjectData")), "pipeline")
    components, paths = E.SubElement(pipeline, "components"), E.SubElement(pipeline, "paths")

    def props(parent, values):
        ps = E.SubElement(parent, "properties")
        for key, value in values.items(): E.SubElement(ps, "property", {"name": key}).text = str(value)

    def component(name, kind, values=None, connection=False):
        identity, guid, version = CLASSES[kind]
        c = E.SubElement(components, "component", {"refId": "Package\\Flow\\" + name, "name": name, "componentClassID": guid if format_version == 6 else identity, "version": str(version)})
        props(c, values or {})
        if connection:
            E.SubElement(E.SubElement(c, "connections"), "connection", {"connectionManagerRefId": "Package.ConnectionManagers[Synthetic]"})
        E.SubElement(c, "inputs"); E.SubElement(c, "outputs")
        return c

    def port(c, name, incoming=False, values=None):
        kind = "input" if incoming else "output"
        p = E.SubElement(c.find("inputs" if incoming else "outputs"), kind, {"refId": c.get("refId") + "." + kind + "[" + name + "]", "name": name, "errorRowDisposition": "IgnoreFailure"})
        props(p, values or {})
        E.SubElement(p, "inputColumns" if incoming else "outputColumns")
        E.SubElement(p, "externalMetadataColumns")
        return p

    def column(p, name, lineage=None, external=False, values=None):
        incoming = p.tag == "input"
        kind = "inputColumn" if incoming else "outputColumn"
        identity = p.get("refId") + ".Columns[" + name + "]"
        attrs = {"refId": identity, "name": name, "cachedName": name, "dataType": "i4", "cachedDataType": "i4", "lineageId": lineage or identity}
        if external:
            eid = p.get("refId") + ".External[" + name + "]"
            attrs["externalMetadataColumnId"] = eid
            E.SubElement(p.find("externalMetadataColumns"), "externalMetadataColumn", {"refId": eid, "name": name, "dataType": "i4"})
        col = E.SubElement(p.find("inputColumns" if incoming else "outputColumns"), kind, attrs)
        props(col, values or {})
        return attrs["lineageId"]

    def path(output, input):
        E.SubElement(paths, "path", {"refId": "path" + str(len(paths) + 1), "startId": output.get("refId"), "endId": input.get("refId")})

    sources = []
    for suffix in ("A", "B"):
        source = component("Source" + suffix, "source", {"AccessMode": 2, "SqlCommand": "SELECT KeyA, KeyB, Amount FROM dbo.SyntheticSource" + suffix + " WHERE Amount >= ?", "ParameterMapping": '"@Floor:Input",' + variable_ids["SourceFloor"] + ';'}, True)
        output = port(source, "Rows")
        ids = {n: column(output, n, external=True) for n in ("KeyA", "KeyB", "Amount")}
        sources.append((output, ids))
    union = component("Union", "union")
    union_out = port(union, "Rows")
    union_ids = {n: column(union_out, n) for n in ("KeyA", "KeyB", "Amount")}
    for n, (output, ids) in enumerate(sources):
        ip = port(union, "Input" + str(n), True)
        for name in ids: column(ip, name, ids[name], values={"OutputColumnLineageID": union_ids[name]})
        path(output, ip)
    derived = component("Derived", "derived")
    di, do = port(derived, "Input", True), port(derived, "Rows")
    path(union_out, di)
    adjusted = column(do, "Adjusted", values={"Expression": "[Amount] + @[User::Offset]"})
    lookup = component("Lookup", "lookup", {"SqlCommand": "SELECT KeyA, KeyB, Score FROM dbo.SyntheticLookup", "AccessMode": 2, "NoMatchBehavior": 1, "CacheType": 0}, True)
    li, lo = port(lookup, "Input", True), port(lookup, "Match")
    for name in ("KeyA", "KeyB"): column(li, name, union_ids[name], values={"JoinToReferenceColumn": name})
    score = column(lo, "Score", values={"CopyFromReferenceColumn": "Score"})
    path(do, li)
    split = component("Split", "split")
    si = port(split, "Input", True)
    path(lo, si)
    high = port(split, "High", values={"EvaluationOrder": 0, "Expression": "[Adjusted] > @[User::Threshold]", "IsDefaultOut": "false"})
    low = port(split, "Default", values={"EvaluationOrder": 1, "IsDefaultOut": "true"})
    for label, output in [("High", high), ("Default", low)]:
        dest = component("Destination" + label, "destination")
        ip = port(dest, "Input", True)
        for name, lineage in [("KeyA", union_ids["KeyA"]), ("KeyB", union_ids["KeyB"]), ("Adjusted", adjusted), ("Score", score)]: column(ip, name, lineage, True)
        path(output, ip)
    E.indent(root)
    return E.tostring(root, encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    folder = Path(__file__).resolve().parent
    for version in (6, 8): (folder / f"synthetic-{version}.dtsx").write_bytes(build(version))
