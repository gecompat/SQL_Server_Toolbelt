from io import BytesIO
from pathlib import Path
from zipfile import ZipFile, ZipInfo
import struct
import sys

buffer = BytesIO()
with ZipFile(buffer, 'w') as archive:
    for name, payload in [('first.bin', b'\x01\x02\x03'), ('second.bin', b'\x04\x05'), ('third.bin', b'\x06')]:
        archive.writestr(ZipInfo(name), payload)

data = bytearray(buffer.getvalue())
with ZipFile(BytesIO(data)) as archive:
    offset = archive.getinfo('second.bin').header_offset
    name_size, extra_size = struct.unpack_from('<HH', data, offset + 26)
data[offset + 30 + name_size + extra_size] ^= 1
with ZipFile(BytesIO(data)) as archive:
    assert archive.namelist() == ['first.bin', 'second.bin', 'third.bin']
    assert archive.read('first.bin') == b'\x01\x02\x03'
    assert archive.read('third.bin') == b'\x06'
    assert archive.testzip() == 'second.bin'
Path(sys.argv[1]).write_bytes(data)
print('Synthetic ZIP preflight: one checksum mismatch, three readable directory entries')
