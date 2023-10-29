#!/bin/bash

QEMU=/usr/bin/qemu-kvm
SVSM=/usr/share/coconut-svsm/coconut-svsm.bin
OVMF=/usr/share/edk2/ovmf-coconutsvsm/OVMF_CODE.coconutsvsm.fd
VARS=/usr/share/edk2/ovmf-coconutsvsm/OVMF_VARS.coconutsvsm.fd


function usage() {
    echo
    echo "USAGE: $0 -disk DISKIMAGE [..]"
    echo "Available options:"
    echo " -svsm PATH       path to SVSM binary, default=$SVSM"
    echo " -qemu PATH       path to qemu binary, default=$QEMU"
    echo " -ovmf PATH       path to OVMF binary, default=$OVMF"
    echo " -vars PATH       path to OVMF vars file, default=$VARS"
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
    -svsm)
        SVSM="$2"
        shift
        ;;
    -ovmf)
        OVMF="$2"
        shift
        ;;
    -vars)
        VARS="$2"
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
  -cpu EPYC-v4 \
  -machine q35,confidential-guest-support=sev0,memory-backend=ram1,kvm-type=protected \
  -object memory-backend-memfd-private,id=ram1,size=8G,share=true \
  -object sev-snp-guest,id=sev0,cbitpos=51,reduced-phys-bits=1,svsm=on \
  -smp 8 \
  -no-reboot \
  -drive if=pflash,format=raw,unit=0,file="$OVMF",readonly=on \
  -drive if=pflash,format=raw,unit=1,file="$VARS",snapshot=on \
  -drive if=pflash,format=raw,unit=2,file="$SVSM",readonly=on \
  -netdev user,id=vmnic -device e1000,netdev=vmnic,romfile= \
  -drive file="$DISK",if=none,id=disk0,snapshot=off \
  -device virtio-scsi-pci,id=scsi0,disable-legacy=on,iommu_platform=on \
  -device scsi-hd,drive=disk0,bootindex=0 \
  -nodefaults \
  -display none \
  -serial mon:stdio
