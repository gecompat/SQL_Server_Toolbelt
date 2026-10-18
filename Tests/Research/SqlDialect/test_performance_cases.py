"""Unabhängige kleine Gegenkontrollen für Orakel und Stabilitätsklassifikation."""

import unittest

from performance_cases import cases, oracle, parent_rows, signature, stability


class PerformanceControls(unittest.TestCase):
    def test_heap_oracle_against_naive_relations(self):
        size = 6000
        events = [(i + 1, None if i % 997 == 0 else i % 1000 + 1,
                   None if i % 97 == 0 else (i // 1000) // 2) for i in range(size)]
        parents = parent_rows(size)
        wanted = oracle(size)['rows']
        order = lambda e: (-1 if e[2] is None else e[2], e[0])
        for name, scope, top, cutoff in [('selective', 32, 1, False), ('broad', 2000, 3, False), ('cutoff', 2000, 1, True)]:
            rows = []
            for rowid, key, bound in parents[:scope]:
                match = [e for e in events if key is not None and e[1] == key and
                         (not cutoff or (bound is not None and e[2] is not None and e[2] <= bound))]
                match = sorted(match, key=order, reverse=True)[:top]
                rows.extend((rowid, key, e[0], e[2]) for e in match)
                if not match:
                    rows.append((rowid, key, None, None))
            self.assertEqual(signature(rows), signature(wanted[name]), name)
        rows = [(0, e[1], e[0], e[2]) for e in sorted(events, key=order, reverse=True)[:100]]
        self.assertEqual(signature(rows, True), signature(wanted['global'], True))

    def test_signature_keeps_nulls_duplicates_and_order(self):
        rows = [(1, None, 2, 3), (1, None, 2, 3), (2, 0, 2, 3)]
        self.assertNotEqual(signature(rows), signature(rows[1:]))
        self.assertNotEqual(signature([(None,)]), signature([(0,)]))
        self.assertEqual(signature(rows), signature(list(reversed(rows))))
        self.assertNotEqual(signature(rows, True), signature(list(reversed(rows)), True))

    def test_stable_and_confirmation(self):
        self.assertEqual(stability([[10, 11, 12], [11, 12, 13], [10, 11, 12]])['status'], 'validated')
        self.assertEqual(stability([[10, 10, 10], [10, 10, 10], [30, 30, 30]])['status'], 'not executed')
        self.assertEqual(stability([[10, 10, 10]])['code'], 'INCOMPLETE_REPETITIONS')
        self.assertEqual(stability([[0, 0, 0]] * 3)['status'], 'not executed')

    def test_closed_matrix_and_left_row_identity(self):
        for dialect in ('tsql', 'spark'):
            matrix = cases(dialect)
            self.assertEqual(len(matrix), 10)
            cutoff = next(c['sql'] for c in matrix if c['variant'] == 'window_eligible')
            self.assertIn('PARTITION BY p.RowId', cutoff)
            self.assertIn('e.EventTime<=p.CutoffTime', cutoff)
            self.assertIn('LEFT JOIN Ranked', cutoff)


if __name__ == '__main__':
    unittest.main()
