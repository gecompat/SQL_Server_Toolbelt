"""Projektabwehr SC-010: Rootbindung während Datei-I/O, kein Pfadfallback.

POSIX verwendet komponentenweise dir_fd/NOFOLLOW und private Stagingverzeichnisse.
Windows hält alle Verzeichniskomponenten ohne Delete-Sharing geöffnet und
veröffentlicht die exakte Stagingdatei über ihren Handle. Kein Prozesssandbox.
"""
from __future__ import annotations

import contextlib
import os
from pathlib import Path
import secrets
import stat


class SecurePathError(OSError):
    """Bewusst ohne reale Pfade oder Betriebssystemfehlermeldungen."""


def _selection(raw, roots):
    if not isinstance(raw, (str, os.PathLike)) or not str(raw):
        raise SecurePathError("INVALID_HANDLE")
    path = Path(os.path.abspath(raw))
    choices = [Path(os.path.abspath(r)) for r in roots]
    choices = [r for r in choices if path != r and r in path.parents]
    if not choices:
        raise SecurePathError("HANDLE_OUTSIDE_ALLOWED_ROOT")
    root = max(choices, key=lambda p: len(p.parts))
    if any(p in {".", ".."} or p.endswith((".", " ")) or ":" in p for p in path.parts[1:]):
        raise SecurePathError("HANDLE_COMPONENT_UNSUPPORTED")
    return root, path


class _PosixParent:
    def __init__(self, root, path, create):
        self.fds = []
        self.name = path.name
        try:
            if not all(hasattr(os, n) for n in ("O_NOFOLLOW", "O_DIRECTORY")):
                raise SecurePathError("HANDLE_PLATFORM_UNSUPPORTED")
            if os.open not in os.supports_dir_fd or os.rename not in os.supports_dir_fd:
                raise SecurePathError("HANDLE_PLATFORM_UNSUPPORTED")
            descriptor = os.open(path.anchor, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
            self.fds.append(descriptor)
            for part in path.parent.parts[1:]:
                try:
                    next_fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=descriptor)
                except FileNotFoundError:
                    # Verzeichnisse nur unter dem bereits geöffneten erlaubten Root erzeugen.
                    current = Path(path.anchor, *path.parent.parts[1:len(self.fds)])
                    if not create or not (current == root or root in current.parents):
                        raise
                    try:
                        os.mkdir(part, mode=0o700, dir_fd=descriptor)
                    except FileExistsError:
                        pass
                    next_fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=descriptor)
                descriptor = next_fd
                self.fds.append(descriptor)
            self.fd = descriptor
        except BaseException:
            self.close()
            raise

    def close(self):
        for descriptor in reversed(self.fds):
            os.close(descriptor)
        self.fds = []


class _WindowsParent:
    def __init__(self, root, path, create):
        import ctypes
        from ctypes import wintypes
        self.c = ctypes
        self.handles = []
        self.path = path
        self.k = ctypes.WinDLL("kernel32", use_last_error=True)
        self.k.CreateFileW.argtypes = [wintypes.LPCWSTR, wintypes.DWORD, wintypes.DWORD,
                                     wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.HANDLE]
        self.k.CreateFileW.restype = wintypes.HANDLE
        self.k.CloseHandle.argtypes = [wintypes.HANDLE]
        self.k.CloseHandle.restype = wintypes.BOOL
        self.k.GetFileInformationByHandle.argtypes = [wintypes.HANDLE, wintypes.LPVOID]
        self.k.GetFileInformationByHandle.restype = wintypes.BOOL
        self.k.SetFileInformationByHandle.argtypes = [wintypes.HANDLE, ctypes.c_int, wintypes.LPVOID, wintypes.DWORD]
        self.k.SetFileInformationByHandle.restype = wintypes.BOOL
        if len(path.drive) != 2 or path.drive[1] != ":" or path.anchor.startswith("\\\\"):
            raise SecurePathError("HANDLE_FILESYSTEM_UNSUPPORTED")
        try:
            current = Path(path.anchor)
            for part in (None, *path.parent.parts[1:]):
                if part is not None:
                    current = current / part
                if create and (current == root or root in current.parents) and not current.exists():
                    # Alle Eltern sind schon ohne Delete-Sharing gebunden. Ein
                    # konkurrierend erzeugter Reparse Point wird beim Open verworfen.
                    try:
                        os.mkdir(current, mode=0o700)
                    except FileExistsError:
                        pass
                handle = self._open(str(current), 0x80, 1, 0x02200000, 3)
                self.handles.append(handle)
                info = self.info(handle)
                if not info[0] & 0x10 or info[0] & 0x400:
                    raise SecurePathError("HANDLE_REPARSE_FORBIDDEN")
            self.parent_handle = self.handles[-1]
        except BaseException:
            self.close()
            raise

    def _open(self, path, access, share, flags, creation):
        handle = self.k.CreateFileW(path, access, share, None, creation, flags, None)
        if handle == self.c.c_void_p(-1).value:
            raise SecurePathError("HANDLE_OPEN_FAILED")
        return handle

    def info(self, handle):
        # BY_HANDLE_FILE_INFORMATION besteht aus 13 DWORDs; Dateiattribute und
        # Linkanzahl werden vor Übergabe an CRT/Python geprüft.
        info = (self.c.c_uint32 * 13)()
        if not self.k.GetFileInformationByHandle(handle, self.c.byref(info)):
            raise SecurePathError("HANDLE_INFORMATION_FAILED")
        return info

    def open_file(self, name, write=False):
        import msvcrt
        access = 0xC0010000 if write else 0x80000000
        handle = self._open(str(self.path.parent / name), access, 0 if write else 1,
                            0x00200080, 1 if write else 3)
        try:
            info = self.info(handle)
            if info[0] & (0x400 | 0x10) or info[10] != 1:
                raise SecurePathError("HANDLE_FILE_UNSUPPORTED")
            descriptor = msvcrt.open_osfhandle(handle, os.O_BINARY | (os.O_RDWR if write else os.O_RDONLY))
        except BaseException:
            self.k.CloseHandle(handle)
            raise
        return descriptor

    def publish(self, descriptor):
        import msvcrt
        name = str(self.path).encode("utf-16-le")
        pointer_offset = 8 if self.c.sizeof(self.c.c_void_p) == 8 else 4
        length_offset = pointer_offset + self.c.sizeof(self.c.c_void_p)
        name_offset = length_offset + 4
        data = self.c.create_string_buffer(name_offset + len(name) + 2)
        data[0] = b"\x01"  # ReplaceIfExists; kein erneuter Open des Stagingnamens.
        self.c.c_void_p.from_buffer(data, pointer_offset).value = None
        self.c.c_uint32.from_buffer(data, length_offset).value = len(name)
        self.c.memmove(self.c.addressof(data) + name_offset, name, len(name))
        if not self.k.SetFileInformationByHandle(msvcrt.get_osfhandle(descriptor), 3, data, len(data)):
            raise SecurePathError("HANDLE_PUBLISH_FAILED")

    def discard(self, descriptor):
        import msvcrt
        disposition = self.c.c_ubyte(1)
        if not self.k.SetFileInformationByHandle(msvcrt.get_osfhandle(descriptor), 4,
                                                self.c.byref(disposition), 1):
            raise SecurePathError("HANDLE_STAGING_CLEANUP_FAILED")

    def close(self):
        for handle in reversed(self.handles):
            self.k.CloseHandle(handle)
        self.handles = []


def _parent(raw, roots, create=False):
    root, path = _selection(raw, roots)
    return (_WindowsParent if os.name == "nt" else _PosixParent)(root, path, create)


@contextlib.contextmanager
def open_read(raw, roots):
    parent = None
    try:
        parent = _parent(raw, roots)
        if os.name == "nt":
            descriptor = parent.open_file(parent.path.name)
        else:
            descriptor = os.open(parent.name, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=parent.fd)
        with os.fdopen(descriptor, "rb") as source:
            info = os.fstat(source.fileno())
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
                raise SecurePathError("HANDLE_FILE_UNSUPPORTED")
            yield source
    except (OSError, ValueError) as exc:
        raise SecurePathError("HANDLE_READ_FAILED") from exc
    finally:
        if parent:
            parent.close()


@contextlib.contextmanager
def open_atomic_output(raw, roots):
    parent = None
    stage_fd = None
    stage = None
    owned_stage = False
    name = "tbx-" + secrets.token_hex(16) + ".tmp"
    published = False
    try:
        parent = _parent(raw, roots, create=True)
        if os.name == "nt":
            descriptor = parent.open_file(name, write=True)
        else:
            stage = "tbx-stage-" + secrets.token_hex(16)
            os.mkdir(stage, mode=0o700, dir_fd=parent.fd)
            stage_fd = os.open(stage, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=parent.fd)
            info = os.fstat(stage_fd)
            if info.st_uid != os.geteuid() or stat.S_IMODE(info.st_mode) & 0o077:
                raise SecurePathError("HANDLE_STAGING_AUTHORITY_CHANGED")
            owned_stage = True
            descriptor = os.open(name, os.O_CREAT | os.O_EXCL | os.O_RDWR | os.O_NOFOLLOW, 0o600, dir_fd=stage_fd)
        with os.fdopen(descriptor, "w+b") as destination:
            try:
                yield destination
                destination.flush()
                os.fsync(destination.fileno())
                if os.name == "nt":
                    parent.publish(destination.fileno())
                else:
                    os.replace(name, parent.name, src_dir_fd=stage_fd, dst_dir_fd=parent.fd)
                published = True
            finally:
                if os.name == "nt" and not published:
                    parent.discard(destination.fileno())
    except (OSError, ValueError) as exc:
        raise SecurePathError("HANDLE_WRITE_FAILED") from exc
    finally:
        if stage_fd is not None:
            if owned_stage and not published:
                try:
                    os.unlink(name, dir_fd=stage_fd)
                except FileNotFoundError:
                    pass
            # Nur den unveränderten eigenen Directoryeintrag entfernen. Bei
            # Drift bleibt der private, weiterhin fdgebundene Stagingrest erhalten.
            try:
                observed = os.stat(stage, dir_fd=parent.fd, follow_symlinks=False)
                owned = os.fstat(stage_fd)
                if owned_stage and (observed.st_dev, observed.st_ino) == (owned.st_dev, owned.st_ino):
                    os.rmdir(stage, dir_fd=parent.fd)
            except FileNotFoundError:
                pass
            finally:
                os.close(stage_fd)
        if parent:
            parent.close()
