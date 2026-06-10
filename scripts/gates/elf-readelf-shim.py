#!/usr/bin/env python3
"""Minimal readelf subset for li-os check-zero-c gate (no binutils required)."""
from __future__ import annotations

import struct
import sys
from pathlib import Path


def u16(data: bytes, off: int, endian: str) -> int:
    return struct.unpack_from(f"{endian}H", data, off)[0]


def u32(data: bytes, off: int, endian: str) -> int:
    return struct.unpack_from(f"{endian}I", data, off)[0]


def parse_elf(path: Path) -> tuple[str, list[tuple[int, int, int, int, int, int]]]:
    data = path.read_bytes()
    if data[:4] != b"\x7fELF":
        raise SystemExit(f"elf-readelf-shim: not an ELF: {path}")
    ei_class = data[4]
    ei_data = data[5]
    if ei_class == 1:
        endian = "<"
        e_shoff = u32(data, 0x20, endian)
        e_shentsize = u16(data, 0x2E, endian)
        e_shnum = u16(data, 0x30, endian)
        e_shstrndx = u16(data, 0x32, endian)

        def sh_field(sh_off: int, idx: int) -> int:
            return u32(data, sh_off + idx * 4, endian)
    elif ei_class == 2:
        endian = "<" if ei_data == 1 else ">"
        e_shoff = struct.unpack_from(f"{endian}Q", data, 0x28)[0]
        e_shentsize = u16(data, 0x3A, endian)
        e_shnum = u16(data, 0x3C, endian)
        e_shstrndx = u16(data, 0x3E, endian)

        def sh_field(sh_off: int, idx: int) -> int:
            return struct.unpack_from(f"{endian}Q", data, sh_off + idx * 8)[0]
    else:
        raise SystemExit(f"elf-readelf-shim: unsupported ELF class: {ei_class}")

    sections: list[tuple[int, int, int, int, int, int]] = []
    for i in range(e_shnum):
        off = e_shoff + i * e_shentsize
        if ei_class == 1:
            sh_name, sh_type, sh_flags, sh_addr, sh_offset, sh_size = struct.unpack_from(
                "<IIIIII", data, off
            )
        else:
            sh_name, sh_type, sh_flags = struct.unpack_from(f"{endian}III", data, off)
            sh_addr = sh_field(off, 3)
            sh_offset = sh_field(off, 4)
            sh_size = sh_field(off, 5)
        sections.append((sh_name, sh_type, sh_flags, sh_addr, sh_offset, sh_size))

    shstr_off = sections[e_shstrndx][4]
    shstr_size = sections[e_shstrndx][5]
    shstr = data[shstr_off : shstr_off + shstr_size]
    named: list[tuple[str, int, int, int, int, int, int]] = []
    for sh_name, sh_type, sh_flags, sh_addr, sh_offset, sh_size in sections:
        end = shstr.find(b"\x00", sh_name)
        name = shstr[sh_name:end].decode("ascii", errors="replace")
        named.append((name, sh_type, sh_flags, sh_addr, sh_offset, sh_size, sh_name))
    return endian, named


def cmd_p_comment(path: Path) -> None:
    _, sections = parse_elf(path)
    for name, _t, _f, _a, off, size, _n in sections:
        if name == ".comment":
            blob = path.read_bytes()[off : off + size]
            text = blob.decode("utf-8", errors="replace")
            for line in text.splitlines():
                print(f"  [{line}]")
            return


def cmd_s_symbols(path: Path) -> None:
    data = path.read_bytes()
    _, sections = parse_elf(path)
    symtab = None
    strtab = None
    for name, sh_type, _f, _a, off, size, _n in sections:
        if name == ".symtab" and sh_type == 2:
            symtab = (off, size)
        if name == ".strtab" and sh_type == 3:
            strtab = (off, size)
    if not symtab or not strtab:
        return
    sym_off, sym_size = symtab
    str_off, str_size = strtab
    str_blob = data[str_off : str_off + str_size]
    entry_size = 16 if data[4] == 1 else 24
    for i in range(0, sym_size, entry_size):
        chunk = data[sym_off + i : sym_off + i + entry_size]
        if data[4] == 1:
            _name_idx, _info, _other, _shndx, _value, _size = struct.unpack("<IBBHII", chunk)
            name_idx = struct.unpack_from("<I", chunk, 0)[0]
        else:
            name_idx = struct.unpack_from("<I", chunk, 0)[0]
        end = str_blob.find(b"\x00", name_idx)
        sym_name = str_blob[name_idx:end].decode("ascii", errors="replace")
        if sym_name:
            print(f"     {sym_name}")


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit("usage: elf-readelf-shim.py -p|-s <elf>")
    flag, elf = sys.argv[1], Path(sys.argv[2])
    if flag == "-p":
        cmd_p_comment(elf)
    elif flag == "-s":
        cmd_s_symbols(elf)
    else:
        raise SystemExit(f"elf-readelf-shim: unsupported flag: {flag}")


if __name__ == "__main__":
    main()
