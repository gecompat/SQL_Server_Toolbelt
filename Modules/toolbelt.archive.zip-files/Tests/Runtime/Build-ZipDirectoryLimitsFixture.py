from pathlib import Path
from zipfile import ZipFile, ZipInfo
import sys

path = Path(sys.argv[1])
with ZipFile(path, 'w') as archive:
    archive.writestr(ZipInfo('first.bin'), b'\x01\x02\x03')
    archive.writestr(ZipInfo('second.bin'), b'\x04\x05')
with ZipFile(path) as archive:
    entries = archive.infolist()
    assert [(e.filename, e.file_size, e.compress_size) for e in entries] == [
        ('first.bin', 3, 3), ('second.bin', 2, 2)]
    assert archive.testzip() is None
