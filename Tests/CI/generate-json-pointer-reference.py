"""Erzeuge synthetische JSON-Pointer-Oracles aus Pythons JSON-Parser.

Die Ausgabe ist nur für eine bereits installierte flüchtige Testdatenbank gedacht.
Sie legt keine persistenten Objekte an und liest keine Anwendungsdaten.
"""

import json
import random

rng = random.Random(20261006)
keys = ["", "a", "a/b", "a~b", "x ", "01", "-", "0", "Z", "a/b~c", "é", "😀", "\x00"]
leaves = [None, True, False, 0, 1, -17, "", "text", "é", "😀", "\x00", "/~"]


def node(depth):
    if depth == 0 or rng.randrange(4) == 0:
        return rng.choice(leaves)
    if rng.randrange(2):
        return [node(depth - 1) for _ in range(rng.randrange(4))]
    selected = rng.sample(keys, rng.randrange(1, 5))
    return {key: node(depth - 1) for key in selected}


def pointer(tokens):
    return "".join("/" + token.replace("~", "~0").replace("/", "~1") for token in tokens)


def paths(value, prefix=()):
    yield prefix, value
    if isinstance(value, dict):
        for key, child in value.items():
            yield from paths(child, prefix + (key,))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from paths(child, prefix + (str(index),))


def resolve(value, tokens):
    for token in tokens:
        if isinstance(value, dict):
            if token not in value:
                return "MISSING", None, None, None
            value = value[token]
        elif isinstance(value, list):
            if token == "-":
                return "MISSING", None, None, None
            if not token.isascii() or not token.isdecimal() or (len(token) > 1 and token[0] == "0") or not token:
                return "INVALID", None, None, "ARRAY_INDEX"
            index = int(token)
            if index >= len(value):
                return "MISSING", None, None, None
            value = value[index]
        else:
            return "MISSING", None, None, None
    if value is None:
        return "JSON_NULL", "NULL", None, None
    if isinstance(value, str):
        return "FOUND", "STRING", value, None
    if isinstance(value, bool):
        return "FOUND", "BOOLEAN", str(value).lower(), None
    if isinstance(value, int):
        return "FOUND", "NUMBER", str(value), None
    return None


def hex_text(value):
    if value is None:
        return "NULL"
    return "CONVERT(nvarchar(max),0x" + value.encode("utf-16-le").hex().upper() + ")"


def quote(value):
    return "N'" + value.replace("'", "''") + "'"


def append_case(rows, case_id, tree, tokens, statuses):
    document = json.dumps(tree, ensure_ascii=True, separators=(",", ":"))
    decoded = json.loads(document)
    path = pointer(tokens)
    expected = resolve(decoded, tokens)
    if expected is None:
        return  # Für Containertexte gilt keine Formatierungstreue.
    status, kind, value, code = expected
    statuses.add(status)
    rows.append(f"({case_id},{quote(document)},{hex_text(path)},'{status}',"
                f"{quote(kind) if kind else 'NULL'},{hex_text(value)},{quote(code) if code else 'NULL'})")


def main():
    rows = []
    statuses = set()
    for case_id in range(1, 401):
        tree = node(3)
        document = json.dumps(tree, ensure_ascii=True, separators=(",", ":"))
        decoded = json.loads(document)
        all_paths = list(paths(decoded))
        leaf_paths = [path for path, value in all_paths if not isinstance(value, (dict, list))]
        array_paths = [path for path, value in all_paths if isinstance(value, list)]
        object_paths = [path for path, value in all_paths if isinstance(value, dict)]
        if case_id % 4 in (0, 1) and leaf_paths:
            tokens = rng.choice(leaf_paths)
        elif case_id % 4 == 2 and array_paths:
            tokens = rng.choice(array_paths) + (rng.choice(["", "01", "+1", "1.0"]),)
        elif case_id % 4 == 3 and object_paths:
            tokens = rng.choice(object_paths) + ("absent",)
        elif leaf_paths:
            tokens = rng.choice(leaf_paths)
        else:
            continue
        append_case(rows, case_id, decoded, tokens, statuses)

    # Diese Grenzfälle bleiben auch bei später geänderter Zufallsfolge erhalten.
    fixed = [
        ({"a/b": 1}, ("a/b",)),
        ({"a~b": "v"}, ("a~b",)),
        ({"é": 2}, ("é",)),
        ({"😀": True}, ("😀",)),
        ({"\x00": None}, ("\x00",)),
        ({"x ": 0}, ("x ",)),
        ({"x ": 0}, ("x",)),
        ([5], ("01",)),
        ([5], ("-",)),
        ([5], ("0",)),
        ({"~1": 3}, ("~1",)),
    ]
    for case_id, (tree, tokens) in enumerate(fixed, 401):
        append_case(rows, case_id, tree, tokens, statuses)

    # Die SQL-Gegenprobe kann eine leer geschrumpfte Fallmenge nicht erkennen:
    # beide Seiten waeren dann leer und der Lauf faelschlich gruen.
    if len(rows) != 380 or statuses != {"FOUND", "MISSING", "JSON_NULL", "INVALID"}:
        raise RuntimeError("JSON_POINTER_REFERENCE_COVERAGE_CHANGED")

    print("SET NOCOUNT ON;")
    print("DECLARE @Cases TABLE(Id int PRIMARY KEY,Doc nvarchar(max),Pointer nvarchar(max),"
          "ExpectedStatus varchar(16),ExpectedType varchar(8),ExpectedValue nvarchar(max),ExpectedCode varchar(32));")
    for offset in range(0, len(rows), 100):
        print("INSERT @Cases VALUES\n" + ",\n".join(rows[offset:offset+100]) + ";")
    print("""
DECLARE @Actual TABLE(Id int PRIMARY KEY,Status varchar(16),JsonType varchar(8),Value nvarchar(max),ErrorCode varchar(32));
INSERT @Actual SELECT c.Id,r.Status,r.JsonType,r.Value,r.ErrorCode
FROM @Cases c CROSS APPLY toolbelt_json.TVF_ResolveJsonPointer(c.Doc,c.Pointer,16777216,128) r;
IF (SELECT COUNT(*) FROM @Actual)<>(SELECT COUNT(*) FROM @Cases)
 OR EXISTS(SELECT 1 FROM @Cases c LEFT JOIN @Actual a ON a.Id=c.Id
 WHERE a.Id IS NULL OR a.Status IS NULL
 OR ISNULL(a.Status,'<NULL>') COLLATE Latin1_General_100_BIN2<>ISNULL(c.ExpectedStatus,'<NULL>') COLLATE Latin1_General_100_BIN2
 OR ISNULL(a.JsonType,'<NULL>') COLLATE Latin1_General_100_BIN2<>ISNULL(c.ExpectedType,'<NULL>') COLLATE Latin1_General_100_BIN2
 OR ISNULL(a.ErrorCode,'<NULL>') COLLATE Latin1_General_100_BIN2<>ISNULL(c.ExpectedCode,'<NULL>') COLLATE Latin1_General_100_BIN2
 OR ((a.Value IS NULL AND c.ExpectedValue IS NOT NULL) OR (a.Value IS NOT NULL AND c.ExpectedValue IS NULL))
 OR (a.Value IS NOT NULL AND c.ExpectedValue IS NOT NULL AND
     (DATALENGTH(a.Value)<>DATALENGTH(c.ExpectedValue)
      OR CONVERT(varbinary(max),a.Value)<>CONVERT(varbinary(max),c.ExpectedValue))))
 THROW 55590,N'Synthetic Pointer reference mismatch.',1;
""")
    print(f"SELECT {len(rows)} AS ReferenceCasesPassed;")


if __name__ == "__main__":
    main()
