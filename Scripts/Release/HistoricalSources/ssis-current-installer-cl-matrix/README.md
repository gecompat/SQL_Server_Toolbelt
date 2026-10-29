# Historical SSIS release navigation snapshot

`RELEASE-GATES.md.txt` preserves the exact r30 release-gates bytes used while
the prior SST navigation evidence was closed. Its SHA-256 is
`683AEA7D2CF6D2594138969C4CEE206C89B4D059E2AFA39132AC8E6E9279AF19`.
The historical validator replays only the two exact SSIS matrix additions from
this snapshot to recover the earlier navigation source hash. It does not pin
the current `Releases/1.0.0/RELEASE-GATES.md`; that guide can document later
qualification results independently while its ordinary documentation checks
remain active.
