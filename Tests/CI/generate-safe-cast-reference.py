#!/usr/bin/env python3
"""Emit deterministic Safe Cast oracles from Python's numeric/calendar/UUID types.

The generated SQL is for an already installed disposable test database only.
It creates no persistent objects and never reads application data.
"""

from __future__ import annotations

import datetime as dt
from decimal import Decimal, getcontext
import random
import re
import sys
import uuid


getcontext().prec = 100
MAX_DECIMAL = Decimal("99999999999999999999.999999999999999999")
ERROR_CODES = {
    "INVALID_ARGUMENT": "PARAMETER",
    "LIMIT": "INPUT_LIMIT",
    "EMPTY": "EMPTY",
    "INVALID_FORMAT": "FORMAT",
    "OUT_OF_RANGE": "RANGE",
    "LOSSY": "SCALE",
}


def sql_text(value: str | None) -> str:
    return "NULL" if value is None else "N'" + value.replace("'", "''") + "'"


def sql_number(value: int | None) -> str:
    return "NULL" if value is None else str(value)


def classify_common(value: str | None, budget: int | None) -> str | None:
    if value is None:
        return "SQL_NULL"
    if budget is None or not 1 <= budget <= 8192:
        return "INVALID_ARGUMENT"
    if len(value.encode("utf-16-le")) > budget:
        return "LIMIT"
    if value == "":
        return "EMPTY"
    return None


def decimal_oracle(value: str | None, budget: int | None) -> tuple[str, str | None]:
    common = classify_common(value, budget)
    if common:
        return common, None
    assert value is not None
    if not re.fullmatch(r"[+-]?[0-9]+(?:\.[0-9]+)?", value):
        return "INVALID_FORMAT", None
    number = Decimal(value)
    if abs(number) > MAX_DECIMAL:
        return "OUT_OF_RANGE", None
    if "." in value and len(value.split(".", 1)[1].rstrip("0")) > 18:
        return "LOSSY", None
    return "OK", format(number, "f")


def calendar_oracle(kind: str, value: str | None, budget: int | None) -> str:
    common = classify_common(value, budget)
    if common:
        return common
    assert value is not None
    syntax = (
        r"[0-9]{4}-[0-9]{2}-[0-9]{2}"
        if kind == "Date"
        else r"[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]{1,7})?"
    )
    if not re.fullmatch(syntax, value):
        return "INVALID_FORMAT"
    try:
        parts = (int(value[:4]), int(value[5:7]), int(value[8:10]))
        if kind == "Date":
            dt.date(*parts)
        else:
            dt.datetime(*parts, int(value[11:13]), int(value[14:16]), int(value[17:19]))
    except ValueError:
        return "OUT_OF_RANGE"
    return "OK"


def scalar_oracle(kind: str, value: str | None, budget: int | None) -> tuple[str, str | None]:
    common = classify_common(value, budget)
    if common:
        return common, None
    assert value is not None
    if kind == "BigInt":
        if not re.fullmatch(r"[+-]?[0-9]+", value):
            return "INVALID_FORMAT", None
        number = int(value)
        if not -(2**63) <= number < 2**63:
            return "OUT_OF_RANGE", None
        return "OK", str(number)
    if kind == "Bit":
        return ("OK", value) if value in ("0", "1") else ("INVALID_FORMAT", None)
    assert kind == "UniqueIdentifier"
    if not re.fullmatch(
        r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}",
        value,
    ):
        return "INVALID_FORMAT", None
    return "OK", str(uuid.UUID(value))


def emit_inserts(table: str, rows: list[str]) -> None:
    for offset in range(0, len(rows), 100):
        print(f"INSERT {table} VALUES\n" + ",\n".join(rows[offset : offset + 100]) + ";")


def emit_decimal() -> None:
    rng = random.Random(20261006)
    values: list[str | None] = [
        None, "", " ", ".1", "1.", "1e0", "+0", "-0",
        "0.0000000000000000001",
        "99999999999999999999.9999999999999999991",
        "-99999999999999999999.9999999999999999991",
    ]
    for _ in range(400):
        sign = rng.choice(["", "", "+", "-"])
        whole = "".join(rng.choices("0123456789", k=rng.randint(1, 26)))
        if rng.randrange(6) == 0:
            whole = "0" * rng.randint(1, 25) + whole
        fraction = (
            ""
            if rng.randrange(3) == 0
            else "." + "".join(rng.choices("0123456789", k=rng.randint(1, 27)))
        )
        values.append(sign + whole + fraction)
    rows = []
    for number, value in enumerate(values, 1):
        budget = rng.choice([8192, 8192, 8192, 1, 0, 8193, None])
        status, expected = decimal_oracle(value, budget)
        rows.append(
            f"({number},{sql_text(value)},{sql_number(budget)},'{status}',"
            f"{sql_text(expected)},{sql_text(ERROR_CODES.get(status))})"
        )
    print("DECLARE @DecimalCases TABLE(Id int PRIMARY KEY,Input nvarchar(max),Budget int NULL,"
          "ExpectedStatus varchar(16),ExpectedValue nvarchar(128) NULL,ExpectedCode varchar(32) NULL);")
    emit_inserts("@DecimalCases", rows)
    print("""
DECLARE @ActualDecimal TABLE(Id int PRIMARY KEY,Value decimal(38,18) NULL,Status varchar(16),ErrorCode varchar(32) NULL);
INSERT @ActualDecimal SELECT c.Id,v.Value,v.Status,v.ErrorCode
FROM @DecimalCases c CROSS APPLY toolbelt_conversion.TVF_TryCastDecimal(c.Input,c.Budget) v;
IF (SELECT COUNT(*) FROM @ActualDecimal)<>(SELECT COUNT(*) FROM @DecimalCases)
 OR EXISTS(SELECT 1 FROM @DecimalCases c LEFT JOIN @ActualDecimal a ON a.Id=c.Id
 WHERE a.Id IS NULL OR a.Status IS NULL OR a.Status COLLATE Latin1_General_100_BIN2<>c.ExpectedStatus COLLATE Latin1_General_100_BIN2
 OR ISNULL(a.ErrorCode,'<NULL>') COLLATE Latin1_General_100_BIN2<>ISNULL(c.ExpectedCode,'<NULL>') COLLATE Latin1_General_100_BIN2
 OR (c.ExpectedStatus='OK' AND (a.Value IS NULL OR a.Value<>TRY_CONVERT(decimal(38,18),c.ExpectedValue)))
 OR (c.ExpectedStatus<>'OK' AND a.Value IS NOT NULL))
 THROW 55490,N'Synthetic Decimal reference oracle mismatch.',1;
""")


def emit_calendar() -> None:
    rng = random.Random(20261006)
    fixed: list[str | None] = [
        None, "", "2024-02-29", "1900-02-29", "2000-02-29", "0000-01-01",
        "9999-12-31", "2025-12-31T23:59:59.9999999", "2025-12-31T24:00:00",
        "2025-12-31T23:59:60", "2025-01-01T00:00:00.12345678",
    ]
    rows = []
    for kind in ("Date", "DateTime2"):
        values = list(fixed)
        for _ in range(300):
            year, month, day = rng.randint(0, 10000), rng.randint(0, 13), rng.randint(0, 32)
            value = f"{year:04d}-{month:02d}-{day:02d}"
            if kind == "DateTime2":
                hour, minute, second = rng.randint(0, 25), rng.randint(0, 60), rng.randint(0, 60)
                fraction = (
                    ""
                    if rng.randrange(3) == 0
                    else "." + "".join(rng.choices("0123456789", k=rng.randint(1, 8)))
                )
                value += f"T{hour:02d}:{minute:02d}:{second:02d}" + fraction
            values.append(value)
        for value in values:
            budget = rng.choice([8192, 8192, 8192, 1, 0, 8193, None])
            status = calendar_oracle(kind, value, budget)
            rows.append(
                f"({len(rows)+1},'{kind}',{sql_text(value)},{sql_number(budget)},"
                f"'{status}',{sql_text(ERROR_CODES.get(status))})"
            )
    print("DECLARE @CalendarCases TABLE(Id int PRIMARY KEY,Kind varchar(12),Input nvarchar(max),"
          "Budget int NULL,ExpectedStatus varchar(16),ExpectedCode varchar(32) NULL);")
    emit_inserts("@CalendarCases", rows)
    for kind in ("Date", "DateTime2"):
        print(f"""
DECLARE @Actual{kind} TABLE(Id int PRIMARY KEY,ValueIsNull bit,Status varchar(16),ErrorCode varchar(32) NULL);
INSERT @Actual{kind} SELECT c.Id,CASE WHEN v.Value IS NULL THEN 1 ELSE 0 END,v.Status,v.ErrorCode
FROM @CalendarCases c CROSS APPLY toolbelt_conversion.TVF_TryCast{kind}(c.Input,c.Budget) v WHERE c.Kind='{kind}';
IF (SELECT COUNT(*) FROM @Actual{kind})<>(SELECT COUNT(*) FROM @CalendarCases WHERE Kind='{kind}')
 OR EXISTS(SELECT 1 FROM @CalendarCases c LEFT JOIN @Actual{kind} a ON a.Id=c.Id WHERE c.Kind='{kind}' AND
 (a.Id IS NULL OR a.Status IS NULL OR a.Status COLLATE Latin1_General_100_BIN2<>c.ExpectedStatus COLLATE Latin1_General_100_BIN2
 OR ISNULL(a.ErrorCode,'<NULL>') COLLATE Latin1_General_100_BIN2<>ISNULL(c.ExpectedCode,'<NULL>') COLLATE Latin1_General_100_BIN2
 OR (c.ExpectedStatus='OK' AND a.ValueIsNull<>0) OR (c.ExpectedStatus<>'OK' AND a.ValueIsNull<>1)))
 THROW 55490,N'Synthetic {kind} reference oracle mismatch.',1;
""")


def emit_scalars() -> int:
    rng = random.Random(20261007)
    fixed: dict[str, list[str | None]] = {
        "BigInt": [
            None, "", "+0", "-0", "9223372036854775807", "-9223372036854775808",
            "9223372036854775808", "-9223372036854775809", "1e0", " 1", "+",
        ],
        "Bit": [None, "", "0", "1", "2", "-0", "+1", " 0", "0 ", "true"],
        "UniqueIdentifier": [
            None, "", "00000000-0000-0000-0000-000000000000",
            "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF",
            "{00000000-0000-0000-0000-000000000000}",
            "00000000-0000-0000-0000-000000000000x",
        ],
    }
    rows = []
    for kind in ("BigInt", "Bit", "UniqueIdentifier"):
        values = list(fixed[kind])
        if kind == "BigInt":
            for _ in range(400):
                values.append(
                    rng.choice(["", "", "+", "-"])
                    + "".join(rng.choices("0123456789", k=rng.randint(1, 28)))
                )
        elif kind == "Bit":
            for _ in range(200):
                values.append(rng.choice(["0", "1", "2", "-1", "01", "True", ""]))
        else:
            for _ in range(250):
                text = str(uuid.UUID(int=rng.getrandbits(128)))
                values.append(rng.choice([text, text.upper(), text.replace("-", ""), text + "x"]))
        for value in values:
            budget = rng.choice([8192, 8192, 8192, 1, 0, 8193, None])
            status, expected = scalar_oracle(kind, value, budget)
            rows.append(
                f"({len(rows)+1},'{kind}',{sql_text(value)},{sql_number(budget)},"
                f"'{status}',{sql_text(expected)},{sql_text(ERROR_CODES.get(status))})"
            )
    print("DECLARE @ScalarCases TABLE(Id int PRIMARY KEY,Kind varchar(20),Input nvarchar(max),"
          "Budget int NULL,ExpectedStatus varchar(16),ExpectedValue nvarchar(128) NULL,"
          "ExpectedCode varchar(32) NULL);")
    emit_inserts("@ScalarCases", rows)
    for kind, value_type in (("BigInt", "bigint"), ("Bit", "bit"),
                             ("UniqueIdentifier", "uniqueidentifier")):
        print(f"""
DECLARE @Actual{kind} TABLE(Id int PRIMARY KEY,Value {value_type} NULL,Status varchar(16),ErrorCode varchar(32) NULL);
INSERT @Actual{kind} SELECT c.Id,v.Value,v.Status,v.ErrorCode
FROM @ScalarCases c CROSS APPLY toolbelt_conversion.TVF_TryCast{kind}(c.Input,c.Budget) v WHERE c.Kind='{kind}';
IF (SELECT COUNT(*) FROM @Actual{kind})<>(SELECT COUNT(*) FROM @ScalarCases WHERE Kind='{kind}')
 OR EXISTS(SELECT 1 FROM @ScalarCases c LEFT JOIN @Actual{kind} a ON a.Id=c.Id WHERE c.Kind='{kind}' AND
 (a.Id IS NULL OR a.Status IS NULL OR a.Status COLLATE Latin1_General_100_BIN2<>c.ExpectedStatus COLLATE Latin1_General_100_BIN2
 OR ISNULL(a.ErrorCode,'<NULL>') COLLATE Latin1_General_100_BIN2<>ISNULL(c.ExpectedCode,'<NULL>') COLLATE Latin1_General_100_BIN2
 OR (c.ExpectedStatus='OK' AND (a.Value IS NULL OR a.Value<>TRY_CONVERT({value_type},c.ExpectedValue)))
 OR (c.ExpectedStatus<>'OK' AND a.Value IS NOT NULL)))
 THROW 55490,N'Synthetic {kind} reference oracle mismatch.',1;
""")
    return len(rows)


def main() -> None:
    print("SET NOCOUNT ON;")
    emit_decimal()
    emit_calendar()
    scalar_count = emit_scalars()
    print(f"SELECT {1033 + scalar_count} AS ReferenceCasesPassed;")


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(1)
