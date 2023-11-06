#!/usr/bin/env python3

import argparse
import os
import re
import subprocess
import sys


def _find_vmsa_start(lines):
    pattern = r"^.*\(VMSA\):$"
    for idx, line in reversed(list(enumerate(lines))):
        if re.match(pattern, line):
            return idx
    sys.exit(f"ERROR: Failed to find dmesg line with pattern={pattern}")


def _parse_vmsa(lines):
    bytestrs = []
    for line in lines:
        hexpattern = ("[0-9a-f][0-9a-f] " * 16).strip()
        pattern = fr"\[.*\] {hexpattern}$"
        if not re.match(pattern, line):
            break
        bytestrs += line.split("]", 1)[1].strip().split()
    return bytestrs


def _parse_args():
    desc = """
Enable VMSA kernel debugging with:

    echo 'func sev_es_sync_vmsa +p' | sudo tee /sys/kernel/debug/dynamic_debug/control

Launch your SEV/SEV-ES/SEV-SNP VM, then run this script.
It will spit out the most recent VMSA dump and save it to vmsa0.bin.

You can then use `sevctl vmsa show vmsa0.bin` to pretty print the content
"""

    parser = argparse.ArgumentParser(
            description=desc,
            formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument("vcpu_count", nargs="?", type=int, default=1,
                        help="vcpu count of the VM")

    options = parser.parse_args()

    if sys.stdin.closed or sys.stdin.isatty():
        print("Running dmesg...")
        dmesg = subprocess.check_output(["dmesg"], text=True)
    else:
        dmesg = sys.stdin.read()

    options.dmesg = dmesg
    return options


def _main():
    options = _parse_args()

    vmsa_list = []
    lines = options.dmesg.splitlines()
    for vcpu in reversed(list(range(options.vcpu_count))):
        print(f"\nFinding VMSA for vcpu={vcpu}...")
        idx = _find_vmsa_start(lines)
        vmsa_bytes = _parse_vmsa(lines[idx + 1:])
        print(f"Parsed {len(vmsa_bytes)} bytes.")
        vmsa_list.insert(0, vmsa_bytes)
        lines = lines[:idx]

    print()
    for idx, vmsa_bytes in enumerate(vmsa_list):
        filename = f"vmsa{idx}.bin"
        if os.path.exists(filename):
            sys.exit(f"ERROR: filename={filename} already exists")

        # Pad to 4096 bytes
        vmsa_bytes += ("00" * max(4096 - len(vmsa_bytes), 0))
        b = bytes().fromhex("".join(vmsa_bytes))
        open(filename, "wb").write(b)
        print(f"Wrote '{filename}'")

    return 0


if __name__ == '__main__':
    sys.exit(_main())
