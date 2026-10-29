# Closed SSIS installer navigation sources

These two byte-for-byte snapshots preserve the release-page source used by the
closed standalone-installer navigation delta. They are validated against fixed
SHA-256 pins before that historical delta is replayed. The source commit was
`e5d4bbfbd2e55b79a3987d1c637d05d829e08b77`.

- `Releases-1.0.0-README.txt`: `95f817e0ff7a450481a43df715f9dd0593c672f3f0a383424183c2327e38d1e3`
- `Releases-1.0.0-EVIDENCE-MAP.txt`: `7e00b3763cfc94789eca6a86d2f7267588093d66e9c352757daf08b8ac2f157b`

These snapshots qualify only the closed historical documentation delta. The
current release navigation remains governed by the ordinary documentation
checks and is not frozen by this historical evidence.
