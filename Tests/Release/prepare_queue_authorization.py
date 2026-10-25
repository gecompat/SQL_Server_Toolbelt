"""Bindet den bestehenden Queue-Policyvertrag an einen eigenen Release-Testscope."""
from __future__ import annotations

import argparse
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTRACT = 'Modules/toolbelt.core.work-queue/Tests/Runtime/Authorization.Contract.sql'


def fixture_bytes(root: Path = ROOT) -> bytes:
    # Expliziter NULL-Default gilt nur fuer die eigene Erfassungstabelle des
    # unveraenderten Tests; seine Policy-/Wert-/Transaktionsorakel bleiben gleich.
    prelude = """SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value)
 FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32
 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c')
 OR @@TRANCOUNT<>0
 THROW 52992,N'Markierter eigener frischer Queue-Testscope erforderlich.',1;
IF USER_ID(N'SecurityQueueActor') IS NOT NULL OR OBJECT_ID(N'dbo.USP_SecurityQueueNoop') IS NOT NULL
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='security.queue')
 THROW 52992,N'Vorhandene Queuefixture wird nicht uebernommen.',2;
SET ANSI_NULL_DFLT_ON ON;
GO
"""
    postlude = """
IF USER_ID(N'SecurityQueueActor') IS NOT NULL OR OBJECT_ID(N'dbo.USP_SecurityQueueNoop') IS NOT NULL
 OR OBJECT_ID(N'tempdb..#SecurityClaim') IS NOT NULL OR @@TRANCOUNT<>0
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='security.queue')
 THROW 52992,N'Eigene Queuefixture nicht vollstaendig bereinigt.',3;
GO
"""
    return prelude.encode('utf-8') + (root / CONTRACT).read_bytes() + postlude.encode('utf-8')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    runtime = ROOT / '.runtime'
    if (not runtime.is_dir() or runtime.is_symlink()
            or getattr(runtime.lstat(), 'st_file_attributes', 0) & 0x400):
        raise SystemExit('QUEUE_AUTH_REPARSE_RUNTIME_REJECTED')
    output = args.output.resolve()
    if not output.is_relative_to(runtime.resolve()) or not output.parent.is_dir():
        raise SystemExit('QUEUE_AUTH_PRIVATE_NEW_OUTPUT_REQUIRED')
    for parent in (output.parent, *output.parent.parents):
        if parent == ROOT:
            break
        if parent.is_symlink() or getattr(parent.lstat(), 'st_file_attributes', 0) & 0x400:
            raise SystemExit('QUEUE_AUTH_REPARSE_OUTPUT_REJECTED')
    with output.open('xb') as stream:
        stream.write(fixture_bytes())
    print('PASS frozen own-scope Queue Authorization fixture; no SQL connection')


if __name__ == '__main__':
    main()
