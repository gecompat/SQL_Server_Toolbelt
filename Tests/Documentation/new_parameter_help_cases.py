"""Create exact native Help oracles from signatures and canonical parameter notes."""
from pathlib import Path
import copy
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Documentation"))
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import generate_parameter_help as generator
import parameter_help_transition as transition
from new_parameter_help_package import WINDOWS_ONLY, LOCAL_ONLY


def cases():
    notes = generator.parameter_notes()
    metadata = json.loads((ROOT / generator.METADATA).read_text(encoding="utf-8"))
    ssis = json.loads(transition.ssis_files(ROOT)["Contracts/Api.json"])
    result = []
    for item in generator.catalog.objects(ROOT):
        if item["type"] != "USP": continue
        _, params = generator.catalog.signature(item)
        key = item["schema"] + "." + item["name"]
        if item["module"] == "toolbelt.tsql.ssis-debug":
            flags = {p["name"]: [p["required"], p["nullable"]] for p in ssis["parameters"]}
        else: flags = metadata[key]["parameters"]
        parameters = [dict(name=p["name"], type=p["type"], default=generator.default_value(p),
                           required=flags[p["name"]][0], nullable=flags[p["name"]][1],
                           description=notes[key]["parameter_notes"][p["name"]]) for p in params]
        invalid = {"@Hilfe": "1", "@Debug": "255", "@KeepData": "1", "@ResultTable": "N'not-a-local-temp-table'"}
        stress = "EXEC " + key + " " + ",".join(p["name"] + "=" + invalid.get(p["name"], "NULL") for p in params) + ";"
        minimal = "EXEC " + key + " " + ",".join(p["name"] + "=" + ("1" if p["name"] == "@Hilfe" else "NULL") for p in params if p["name"] == "@Hilfe" or p["default"] == "kein Default") + ";"
        result.append(dict(name=key, module=item["module"], windows_only=item["module"] in WINDOWS_ONLY,
                           local_only=item["module"] in LOCAL_ONLY, parameters=parameters,
                           internal=False, commands=[minimal, stress]))
        if item["module"] == "toolbelt.tsql.ssis-debug":
            internal = copy.deepcopy(result[-1])
            internal["name"] += "Internal"
            internal["internal"] = True
            internal["commands"] = [sql.replace(key, key + "Internal") for sql in internal["commands"]]
            for p in internal["parameters"]:
                if p["type"].startswith("varchar("):
                    p["type"] = "n" + p["type"]
                    p["description"] = generator.INTERNAL_UNICODE_NOTE + p["description"]
                if p["type"] in ("nvarchar(max)", "varbinary(max)"):
                    p["required"], p["default"] = True, None
                    p["description"] = generator.INTERNAL_LOB_NOTE + p["description"]
            # SQL CLR LOB arguments have no technical defaults even for Help.
            lob = [p["name"] + "=NULL" for p in internal["parameters"] if p["type"] in ("nvarchar(max)", "varbinary(max)")]
            internal["commands"][0] = "EXEC " + internal["name"] + " @Hilfe=1," + ",".join(lob) + ";"
            result.append(internal)
    return result


if __name__ == "__main__":
    if len(sys.argv) != 2: raise SystemExit("Private output path required")
    path = Path(sys.argv[1]).resolve()
    if not path.is_relative_to(ROOT / ".runtime") or path.exists(): raise ValueError("New private output required")
    path.write_text(json.dumps(cases(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
