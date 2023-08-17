#!/bin/bash


DISK="/var/lib/libvirt/images/crobinso-snp.qcow2"

#SVSMGIT="$HOME/src/svsm-vtpm"
SVSMGIT="$HOME/src/linux-svsm"

QEMU=/usr/bin/qemu-system-x86_64
QEMU=/home/crobinso/src/qemu/build/x86_64-softmmu/qemu-system-x86_64
QEMU=/home/crobinso/src/qemu/build-snp-latest-tmp/x86_64-softmmu/qemu-system-x86_64

SVSM=$HOME/src/linux-svsm/svsm.bin
SVSM=/usr/share/svsm-vtpm/svsm-vtpm.bin
SVSM=/home/crobinso/src/coconut-svsm/svsm.bin

OVMF=/home/crobinso/src/edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF_CODE.fd
#OVMF=/home/crobinso/src/edk2/Fedora/ovmf/OVMF.snp-latest.fd
#OVMF=/usr/share/edk2/ovmf-svsm/OVMF_CODE.svsm.fd
#OVMF=/home/crobinso/src/edk2/Fedora/ovmf-svsm/OVMF_CODE.svsm.fd
#OVMF=/usr/share/edk2/ovmf/OVMF_CODE.fd
#OVMF=/usr/share/edk2/ovmf/OVMF.amdsev.fd

VARS=/usr/share/edk2/ovmf-svsm/OVMF_VARS.svsm.fd
#VARS=/home/crobinso/src/edk2/Fedora/ovmf-svsm/OVMF_VARS.svsm.fd
#VARS=/home/crobinso/src/edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF_VARS.fd
#VARS=/usr/share/edk2/ovmf/OVMF_VARS.fd
#VARS=/usr/share/edk2/ovmf/OVMF_VARS.fd


OPTS=""
OPTS="${OPTS} -hda ${DISK}"
OPTS="${OPTS} -sev-snp"
OPTS="${OPTS} -bios ${OVMF}"
OPTS="${OPTS} -bios-vars ${VARS}"
OPTS="${OPTS} -qemu ${QEMU}"
OPTS="${OPTS} -svsm ${SVSM}"
#OPTS="${OPTS} -svsmcrb"
#OPTS="${OPTS} -noupm"


cd $SVSMGIT
sudo -E $SVSMGIT/scripts/launch-qemu.sh $OPTS
