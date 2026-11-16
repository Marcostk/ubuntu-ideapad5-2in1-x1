"""Lê (SOMENTE LEITURA) o ext4 do Ubuntu instalado direto do SSD, pelo Windows, e copia arquivos para análise.

Precisa de admin (abre \\\\.\\PhysicalDrive0) e do pacote PyPI `ext4`.
Uso:  python read-ubuntu-disk.py <offset_da_particao> <tamanho_da_particao> <saida> [caminhos...]
Sem caminhos, copia o conjunto padrão de diagnóstico (logs, journal, /boot, dpkg, GRUB).
"""
import io
import os
import sys

import ext4

SECTOR = 4096  # múltiplo de 512 e de 4096: serve para qualquer setor lógico do NVMe

DEFAULT = [
    "/var/log/apt/history.log", "/var/log/apt/term.log", "/var/log/dpkg.log",
    "/var/log/journal",
    "/var/lib/dpkg/status",
    "/boot/grub/grub.cfg", "/etc/default/grub", "/etc/default/grub.d",
    "/etc/modules-load.d", "/etc/initramfs-tools/hooks",
    "/boot/vmlinuz-7.3.0-15-qcom-x1e", "/boot/initrd.img-7.3.0-15-qcom-x1e",
    "/usr/lib/modules/7.3.0-15-qcom-x1e/kernel/drivers/interconnect/qcom/qnoc-x1e80100.ko.zst",
    "/usr/share/alsa/ucm2/Qualcomm/x1e80100/x1e80100.conf",
]
LISTINGS = ["/boot", "/usr/lib/modules", "/etc/apt/sources.list.d", "/etc/grub.d",
            "/usr/lib/firmware/qcom/x1p42100/LENOVO/83GH", "/opt", "/var/log/journal"]


class AlignedRawReader(io.RawIOBase):
    """Leitor somente leitura sobre um dispositivo bruto que só aceita leituras alinhadas ao setor."""

    def __init__(self, path, size):
        self._f = open(path, "rb", buffering=0)
        self._pos = 0
        self._size = size  # disco bruto não informa o tamanho; SEEK_END usa o fim da partição

    def readable(self):
        return True

    def seekable(self):
        return True

    def writable(self):
        return False

    def seek(self, pos, whence=io.SEEK_SET):
        if whence == io.SEEK_SET:
            self._pos = pos
        elif whence == io.SEEK_CUR:
            self._pos += pos
        else:
            self._pos = self._size + pos
        return self._pos

    def tell(self):
        return self._pos

    def readinto(self, b):
        n = len(b)
        if n == 0:
            return 0
        start = self._pos - self._pos % SECTOR
        end = -(-(self._pos + n) // SECTOR) * SECTOR
        self._f.seek(start)
        data = self._f.read(end - start)
        chunk = data[self._pos - start:self._pos - start + n]
        b[:len(chunk)] = chunk
        self._pos += len(chunk)
        return len(chunk)

    def close(self):
        self._f.close()
        super().close()


def kind(inode):
    return {ext4.Directory: "dir", ext4.File: "file", ext4.SymbolicLink: "link"}.get(type(inode), type(inode).__name__)


def copy(vol, path, out, log):
    try:
        inode = vol.root.inode_at(path)
    except Exception as e:  # noqa: BLE001 - registrar e seguir com os outros caminhos
        log.write(f"FALTA {path}: {e}\n")
        return
    dst = os.path.join(out, path.lstrip("/").replace("/", os.sep))
    if isinstance(inode, ext4.Directory):
        os.makedirs(dst, exist_ok=True)
        for dirent, _ in inode.opendir():
            name = dirent.name_str
            if name in (".", ".."):
                continue
            copy(vol, path.rstrip("/") + "/" + name, out, log)
    elif isinstance(inode, ext4.File):
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with inode.open() as src, open(dst, "wb") as f:
            while chunk := src.read(1 << 20):
                f.write(chunk)
        log.write(f"ok    {path} ({os.path.getsize(dst)} bytes)\n")
    else:
        log.write(f"pula  {path} ({kind(inode)})\n")


def listing(vol, path, log):
    log.write(f"\n== ls {path}\n")
    try:
        d = vol.root.inode_at(path)
        for dirent, _ in d.opendir():
            name = dirent.name_str
            if name in (".", ".."):
                continue
            try:
                child = vol.root.inode_at(path.rstrip("/") + "/" + name)
                size = getattr(child.i_size, "real", child.i_size) if hasattr(child, "i_size") else "?"
                log.write(f"  {kind(child):5} {size!s:>12}  {name}\n")
            except Exception as e:  # noqa: BLE001
                log.write(f"  ?     {name} ({e})\n")
    except Exception as e:  # noqa: BLE001
        log.write(f"  erro: {e}\n")


def main():
    offset, psize, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    paths = sys.argv[4:] or DEFAULT
    os.makedirs(out, exist_ok=True)
    # BufferedReader dá o peek() que o ext4.Volume exige
    disk = io.BufferedReader(AlignedRawReader(r"\\.\PhysicalDrive0", offset + psize), buffer_size=1 << 20)
    vol = ext4.Volume(disk, offset=offset, ignore_checksum=True)
    with open(os.path.join(out, "_leitura.txt"), "w", encoding="utf-8") as log:
        log.write(f"volume: {vol.superblock.s_volume_name!r} bloco={vol.block_size}\n")
        for p in paths:
            copy(vol, p, out, log)
        for p in LISTINGS:
            listing(vol, p, log)
    disk.close()
    print("ok")


if __name__ == "__main__":
    main()
