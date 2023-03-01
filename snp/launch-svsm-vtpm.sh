#!/bin/bash

LINUXSVSM="~/src/linux-svsm"
DISK="~/f37-cloud.raw"

sudo ${LINUXSVSM}/scripts/launch-qemu.sh \
    -hda ${DISK} \
    -sev-snp \
    -bios /usr/share/edk2/ovmf-svsm/OVMF_CODE.svsm.fd \
    -bios-vars /usr/share/edk2/ovmf-svsm/OVMF_VARS.svsm.fd \
    -svsm /usr/share/svsm-vtpm/svsm-vtpm.bin \
    -svsmcrb
