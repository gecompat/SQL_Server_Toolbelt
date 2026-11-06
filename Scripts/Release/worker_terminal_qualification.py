"""Begrenzten Windows-Terminalhistorienrecord prüfen, keine Ausführung simulieren."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import evidence_sources

REPORT = 'Releases/1.0.0/worker-terminal-history-windows-qualification.json'
SOURCE = '8a0b0ac1b9171b0d66c047353cf1fc0f7d8d2895'
DIRECTORIES = tuple('Modules/toolbelt.core.' + name for name in (
    'result-table', 'execution-context', 'execution-cancel', 'work-type', 'work-queue', 'worker-control')) + (
    'Workers/ExternalQueue',)
HELPERS = ('Tests/CI/run-lab-local.ps1', 'Tests/CI/LabQualifiedContract.ps1')
CONTRACTS = ['real_transaction_rollback', 'terminal_failure_releases_slot',
             'two_reconciles_preserve_reservation', 'duplicate_failure_rejected',
             'successor_attempt_isolated', 'historical_hold_version_not_reused',
             'stale_reconcile_authority_rejected', 'successor_held_stop']


LIMITS = ['Only Windows SQL2025 CU8 CL170 local ManagedSqlOnly including terminal-history consumer.', 'No new external provider/full-product, Windows client login, authenticated TLS, minimal-rights, CrossDB or lost-coordinator/host/transport qualification.', 'No new SQL rights, server configuration, CLR, trust or Lab infrastructure changes.', 'Original failed Windows run and prior CI failures remain failed; no replay or repeat.', 'Static public source comparison does not replace original protected execution receipts or establish a new execution.', 'No publication or tags.']
PRIVATE_RECEIPTS = 'Exact controller, bound adapter, selected Lab contract, final plan, original journal, cleanup facts and fresh audit retained privately; no public hashes of private inputs.'


def require(value, message):
    if not value:
        raise ValueError(message)


def exact(actual, expected, label):
    # bool darf nicht stillschweigend als numerischer Zähler durchgehen.
    require(isinstance(actual, dict) and set(actual) == set(expected)
            and all(type(actual[k]) is type(v) and actual[k] == v for k, v in expected.items()), label)


def validate(record, root=ROOT):
    root = Path(root).resolve()
    require(set(record) == {'schema_version', 'date', 'result', 'publication_authorized',
            'source_commit', 'scope', 'budget', 'execution', 'audit', 'terminal_history_contracts',
            'history', 'public_input_sha256', 'private_receipts', 'limits'}, 'Record fields')
    require(record['schema_version'] == 'worker-terminal-windows-qualification/v1'
            and record['date'] == '2026-11-06' and record['result'] == 'PASS_FOR_DECLARED_SCOPE'
            and record['publication_authorized'] is False and record['source_commit'] == SOURCE,
            'Original execution identity')
    exact(record['scope'], {'platform': 'windows', 'sql_version': '2025', 'patch': 'CU8',
          'compatibility_level': 170, 'deployment_mode': 'local', 'runtime_mode': 'ManagedSqlOnly',
          'test_purpose': 'Functional', 'existing_lab_authentication': True}, 'Declared scope')
    exact(record['budget'], {'explicit_new_finite_user_approval': True, 'target_and_audit_calls': 3,
          'own_database_reservations': 1, 'run_count': 1, 'fresh_audit_count': 1, 'retries': 0,
          'maximum_minutes': 45, 'completed_within_original_deadline': True, 'scope_closed': True},
          'Closed finite scope')
    exact(record['execution'], {'prepare_exit_code': 0, 'run_exit_code': 0, 'audit_exit_code': 0,
          'managed_sql_witness_count': 1, 'terminal_history_witness_count': 1,
          'journal_stage': 'managed-database-dropped', 'original_primary_failure': False,
          'original_secondary_failures': 0, 'provider_cases': 0, 'full_product_qualified': False},
          'Actual coordinator and witness scope')
    exact(record['audit'], {'fresh_separate_connection': True, 'read_only': True,
          'database_absent': True, 'foreign_state_unchanged': True, 'post_pins': True,
          'run_pass': True, 'exact_final_plan_bound': True, 'exact_original_journal_bound': True,
          'cleanup_quiescence': 'QUIESCENT'}, 'Independent final audit')
    exact(record['history'], {'original_windows_sql208': 'FAILED_CLEANED',
          'prior_native_calls_closed': 3, 'prior_database_reservations_closed': 1,
          'prior_failure_not_upgraded': True, 'prior_budget_unchanged': True,
          'prior_linux_success_keeps_original_scope': True}, 'Original failures retained')
    require(record['terminal_history_contracts'] == CONTRACTS, 'Terminal history clauses')
    require(record['private_receipts'] == PRIVATE_RECEIPTS and record['limits'] == LIMITS,
            'Original receipt and limitation separation')

    # Ausführungspins kommen aus dem tatsächlichen unveränderlichen Quellbaum.
    # Heutige passende Bytes allein dürfen keinen gefälschten Originalpin decken.
    listing = subprocess.run(['git', '-C', str(root), 'ls-tree', '-r', '-z', '--name-only', SOURCE,
                              '--', *DIRECTORIES, *HELPERS], capture_output=True, timeout=30, check=True)
    paths = {p.decode('utf-8') for p in listing.stdout.split(b'\0')
             if p and Path(p.decode('utf-8')).suffix.lower() != '.md'}
    pins = record['public_input_sha256']
    require(isinstance(pins, dict) and set(pins) == paths and bool(paths), 'Public input closure')
    originals = evidence_sources._snapshot(root, SOURCE, paths)
    for name, digest in pins.items():
        require(isinstance(digest, str) and re.fullmatch('[0-9a-f]{64}', digest) is not None,
                'Public input digest')
        require(name in originals and hashlib.sha256(originals[name]).hexdigest() == digest,
                'Original source pin differs')
    bindings = evidence_sources.resolve(root, pins, revisions=[SOURCE])
    # Ein zukünftiger Quelldrift löscht die Originalausführung nicht. Aktuelle
    # Anwendbarkeit und neue native Abnahme bleiben davon getrennt.
    return evidence_sources.applicability(bindings)


if __name__ == '__main__':
    print(json.dumps(validate(json.loads((ROOT / REPORT).read_bytes())), sort_keys=True))
