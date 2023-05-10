QEMU=/home/crobinso/src/qemu/build/x86_64-softmmu/qemu-system-x86_64
SVSM=/home/crobinso/src/coconut-svsm/svsm.bin
OVMF=/usr/share/edk2/ovmf-svsm/OVMF_CODE.svsm.fd
VARS=/usr/share/edk2/ovmf-svsm/OVMF_VARS.svsm.fd
DISK="$HOME/f37-cloud.qcow2"

sudo $QEMU \
  -enable-kvm \
  -cpu EPYC-v4 \
  -machine q35,confidential-guest-support=sev0,memory-backend=ram1,kvm-type=protected \
  -object memory-backend-memfd-private,id=ram1,size=8G,share=true \
  -object sev-snp-guest,id=sev0,cbitpos=51,reduced-phys-bits=1,svsm=on \
  -smp 8 \
  -no-reboot \
  -drive if=pflash,format=raw,unit=0,file=$OVMF,readonly=on \
  -drive if=pflash,format=raw,unit=1,file=$VARS,snapshot=on \
  -drive if=pflash,format=raw,unit=2,file=$SVSM,readonly=on \
  -netdev user,id=vmnic -device e1000,netdev=vmnic,romfile= \
  -drive file=$DISK,if=none,id=disk0,snapshot=off \
  -device virtio-scsi-pci,id=scsi0,disable-legacy=on,iommu_platform=on \
  -device scsi-hd,drive=disk0,bootindex=0 \
  -nographic
