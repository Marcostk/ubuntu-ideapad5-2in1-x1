#!/usr/bin/env python3
"""Extrai os DTBs (.dtbauto) e a tabela .hwids de um UKI/stubble arm64.
Uso: extract-dtbs.py <vmlinuz> <dir_saida>"""
import struct, sys, os

def sections(data):
    pe = struct.unpack_from('<I', data, 0x3c)[0]
    assert data[pe:pe+4] == b'PE\0\0', 'não é PE'
    nsec = struct.unpack_from('<H', data, pe + 6)[0]
    optsz = struct.unpack_from('<H', data, pe + 20)[0]
    off = pe + 24 + optsz
    for i in range(nsec):
        name = data[off:off+8].rstrip(b'\0').decode()
        vsize, _, rsize, rptr = struct.unpack_from('<IIII', data, off + 8)
        yield i, name, data[rptr:rptr + min(vsize, rsize)]
        off += 40

data = open(sys.argv[1], 'rb').read()
out = sys.argv[2]; os.makedirs(out, exist_ok=True)
for i, name, blob in sections(data):
    if name == '.dtbauto':
        assert blob[:4] == b'\xd0\x0d\xfe\xed', f'seção {i} sem magic FDT'
        open(f'{out}/{i:02d}.dtb', 'wb').write(blob)
    elif name == '.hwids':
        open(f'{out}/hwids.bin', 'wb').write(blob)
