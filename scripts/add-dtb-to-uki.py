#!/usr/bin/env python3
"""Acrescenta um DTB como nova seção .dtbauto no vmlinuz (UKI/stubble) do Ubuntu x1e.
O .hwids do Ubuntu já mapeia o 83GH para "lenovo,ideapad-5-2in1"; só faltava o DTB.
A assinatura de Secure Boot é removida: o teste exige Secure Boot desligado.
Uso: add-dtb-to-uki.py <vmlinuz original> <dtb> <vmlinuz novo>"""
import struct, sys

def align(x, a): return (x + a - 1) // a * a

src, dtb_path, out = sys.argv[1:4]
d = bytearray(open(src, 'rb').read())
dtb = open(dtb_path, 'rb').read()
assert dtb[:4] == b'\xd0\x0d\xfe\xed', 'DTB inválido'

pe = struct.unpack_from('<I', d, 0x3c)[0]
assert d[pe:pe+4] == b'PE\0\0'
nsec_off, optsz = pe + 6, struct.unpack_from('<H', d, pe + 20)[0]
nsec = struct.unpack_from('<H', d, nsec_off)[0]
opt = pe + 24
assert struct.unpack_from('<H', d, opt)[0] == 0x20b, 'esperado PE32+'
sec_align, file_align = struct.unpack_from('<II', d, opt + 32)
size_img_off, size_hdr_off = opt + 56, opt + 60
size_hdr = struct.unpack_from('<I', d, size_hdr_off)[0]
sec_tab = opt + optsz
secs = [struct.unpack_from('<8sIIIIIIHHI', d, sec_tab + 40*i) for i in range(nsec)]
first_raw = min(s[4] for s in secs if s[3])
first_va = min(s[2] for s in secs)

# espaço para mais uma entrada na tabela de seções
need = sec_tab + 40 * (nsec + 1)
if need > size_hdr:
    new_hdr = align(need, file_align)
    assert new_hdr <= first_raw and new_hdr <= first_va, 'sem espaço no cabeçalho para nova seção'
    struct.pack_into('<I', d, size_hdr_off, new_hdr)
assert not any(d[sec_tab + 40*nsec: need]), 'área da nova entrada não está vazia'

# remove assinatura Authenticode (diretório de segurança = índice 4)
sec_dir = opt + 112 + 8*4
cert_off, cert_len = struct.unpack_from('<II', d, sec_dir)
if cert_off:
    del d[cert_off:]
    struct.pack_into('<II', d, sec_dir, 0, 0)

va = align(max(s[2] + s[1] for s in secs), sec_align)
raw = align(len(d), file_align)
rawsize = align(len(dtb), file_align)
d += b'\0' * (raw - len(d)) + dtb + b'\0' * (rawsize - len(dtb))
struct.pack_into('<8sIIIIIIHHI', d, sec_tab + 40*nsec,
                 b'.dtbauto', len(dtb), va, rawsize, raw, 0, 0, 0, 0, 0x40000040)
struct.pack_into('<H', d, nsec_off, nsec + 1)
struct.pack_into('<I', d, size_img_off, align(va + len(dtb), sec_align))
struct.pack_into('<I', d, opt + 64, 0)  # checksum
open(out, 'wb').write(d)
print(f'seção {nsec} .dtbauto: VA=0x{va:x} raw=0x{raw:x} tamanho={len(dtb)}; assinatura removida={bool(cert_off)}')
