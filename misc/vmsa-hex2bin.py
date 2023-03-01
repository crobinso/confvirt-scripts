import sys

raw = sys.stdin.read().replace("\n", "")
b = bytes().fromhex(raw)
sys.stdout.buffer.write(b)
