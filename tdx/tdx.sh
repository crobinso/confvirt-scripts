#!/bin/bash

QEMU=/usr/libexec/qemu-kvm
OVMF=/usr/share/edk2/ovmf/OVMF.inteltdx.fd


function usage() {
    echo
    echo "USAGE: $0 -disk DISKIMAGE [..]"
    echo "Available options:"
    echo " -qemu PATH       path to qemu binary, default=$QEMU"
    echo " -ovmf PATH       path to OVMF binary, default=$OVMF"
    echo
    exit 0
}

while [ -n "$1" ]; do
    case "$1" in
    -disk)
        DISK="$2"
        shift
        ;;
    -qemu)
        QEMU="$2"
        shift
        ;;
    -ovmf)
        OVMF="$2"
        shift
        ;;
    *)
        echo "Unknown option '$1'"
        usage
        ;;
    esac
    shift
done

if [ -z "$DISK" ] ; then
    echo "ERROR: -disk DISKIMAGE must be specified"
    usage
fi

set -x

sudo "$QEMU" \
  -enable-kvm \
  -cpu host \
  -object memory-backend-memfd,id=ram1,size=8G,private=on \
  -object tdx-guest,id=cc0 \
  -machine q35,kernel-irqchip=split,confidential-guest-support=cc0,memory-backend=ram1 \
  -smp 8 \
  -no-reboot \
  -bios "$OVMF" \
  -netdev user,id=vmnic -device virtio-net-pci,netdev=vmnic,romfile= \
  -drive file="$DISK",if=virtio,id=disk0 \
  -nodefaults \
  -display none \
  -serial mon:stdio \
  || reset -w
