#DEBUGCON_STDIO=1

# UPM mode. Requires upm qemu branch. Not required to run SNP on non-UPM kernel at least
ENABLE_UPM=${ENABLE_UPM:-0}
# Enable SNP
ENABLE_SNP=${ENABLE_SNP:-1}

echo "ENABLE_SNP=${ENABLE_SNP}"
echo "ENABLE_UPM=${ENABLE_UPM}"

FIRMWARE="/home/crobinso/src/ovmf/Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd"
#FIRMWARE="/home/crobinso/src/ovmf/Build/OvmfX64/DEBUG_GCC5/FV/OVMF_CODE.fd"
FIRMWARE="/usr/share/edk2/ovmf/OVMF.amdsev.fd"
#FIRMWARE="/usr/share/edk2/ovmf/OVMF_CODE.cc.fd"
#FIRMWARE="/tmp/rpmbuild/BUILDROOT/edk2-20221117gitfff6d81270b5-11.fc39.x86_64/usr/share/edk2/ovmf-svsm/OVMF_CODE.svsm.fd"
#NVRAM="/home/crobinso/src/ovmf/Build/OvmfX64/DEBUG_GCC5/FV/OVMF_VARS.fd"


QEMU=/home/crobinso/src/qemu/build/x86_64-softmmu/qemu-system-x86_64
QEMU=/usr/bin/qemu-system-x86_64


# Not sure if anything uses this image...
DISK=/var/lib/libvirt/images/f35-sev.img
# This is F37 cloud, with `yum update` as of at least Feb 7. root:root
DISK=/home/crobinso/f37-cloud.raw,format=raw


# May be required for svsm
#CPU="EPYC-v4,host-phys-bits=true"
CPU="EPYC-Milan-v2"

MEM="memory-backend-ram,id=ram1,size=2G   -overcommit mem-lock=on"
MACHINE="-machine q35,memory-backend=ram1,pflash0=libvirt-pflash0-format"

# Works on UPM and non-UPM qemu on non-UPM kernel
if [ "$ENABLE_SNP" = "1" ]; then
    MACHINE="$MACHINE,confidential-guest-support=lsec0"
    SEV="-object sev-snp-guest,id=lsec0,cbitpos=51,reduced-phys-bits=1"

    if [ "$ENABLE_UPM" = "1" ]; then
        SEV="$SEV,upm-mode=on"
        # This only works on UPM branch
        MEM="memory-backend-memfd-private,id=ram1,size=2G,share=true"
    fi
fi


DEBUGCON=pty
SERIAL=stdio
if [ "$DEBUGCON_STDIO" = "1" ] ; then
    DEBUGCON=stdio
    SERIAL=pty
fi

#-kernel /home/crobinso/vmlinuz-6.1.9-200.fc37.x86_64 \
#-initrd /home/crobinso/initramfs-6.1.9-200.fc37.x86_64.img \

sudo $QEMU \
  -name guest=cole-f35-sevtest,debug-threads=on \
  -accel kvm \
  -cpu $CPU \
  -object $MEM \
  -smp 2,sockets=2,cores=1,threads=1 \
  -uuid 023645f4-8a44-4a55-9f7e-3fae48dfc504 \
  -display none \
  -boot strict=on \
  -no-user-config \
  -nodefaults \
  -rtc base=utc,driftfix=slew \
  -global kvm-pit.lost_tick_policy=delay \
  -no-hpet \
  -no-shutdown \
  -global ICH9-LPC.disable_s3=1 \
  -global ICH9-LPC.disable_s4=1 \
  -device pcie-root-port,port=8,chassis=1,id=pci.1,bus=pcie.0,multifunction=true,addr=0x1 \
  -device pcie-root-port,port=9,chassis=2,id=pci.2,bus=pcie.0,addr=0x1.0x1 \
  -device pcie-root-port,port=10,chassis=3,id=pci.3,bus=pcie.0,addr=0x1.0x2 \
  -device pcie-root-port,port=11,chassis=4,id=pci.4,bus=pcie.0,addr=0x1.0x3 \
  -device pcie-root-port,port=12,chassis=5,id=pci.5,bus=pcie.0,addr=0x1.0x4 \
  -device pcie-root-port,port=13,chassis=6,id=pci.6,bus=pcie.0,addr=0x1.0x5 \
  -device pcie-root-port,port=14,chassis=7,id=pci.7,bus=pcie.0,addr=0x1.0x6 \
  -device pcie-root-port,port=15,chassis=8,id=pci.8,bus=pcie.0,addr=0x1.0x7 \
  -device pcie-root-port,port=16,chassis=9,id=pci.9,bus=pcie.0,multifunction=true,addr=0x2 \
  -device pcie-root-port,port=17,chassis=10,id=pci.10,bus=pcie.0,addr=0x2.0x1 \
  -device pcie-root-port,port=18,chassis=11,id=pci.11,bus=pcie.0,addr=0x2.0x2 \
  -device pcie-root-port,port=19,chassis=12,id=pci.12,bus=pcie.0,addr=0x2.0x3 \
  -device pcie-root-port,port=20,chassis=13,id=pci.13,bus=pcie.0,addr=0x2.0x4 \
  -device pcie-root-port,port=21,chassis=14,id=pci.14,bus=pcie.0,addr=0x2.0x5 \
  -device qemu-xhci,p2=15,p3=15,id=usb,bus=pci.3,addr=0x0 \
  -device virtio-serial-pci,iommu_platform=true,id=virtio-serial0,bus=pci.2,addr=0x0 \
  -device isa-serial,chardev=charserial0,id=serial0,index=0 \
  -chardev socket,id=charchannel0,path=/tmp/org.qemu.guest_agent.0,server=on,wait=off \
  -device virtserialport,bus=virtio-serial0.0,nr=1,chardev=charchannel0,id=channel0,name=org.qemu.guest_agent.0 \
  -object rng-random,id=objrng0,filename=/dev/urandom \
  -device virtio-rng-pci,iommu_platform=true,rng=objrng0,id=rng0,bus=pci.5,addr=0x0 \
  -msg timestamp=on \
  -chardev ${SERIAL},id=charserial0 \
  -device isa-debugcon,iobase=0x402,chardev=debugcon \
  -chardev $DEBUGCON,id=debugcon \
  -drive if=none,format=raw,file=$FIRMWARE,id=libvirt-pflash0-format,readonly=on \
  $MACHINE \
  $SEV \
  -drive if=none,file=$DISK,id=libvirt-1-format \
  -device virtio-blk-pci,iommu_platform=true,bus=pci.4,addr=0x0,drive=libvirt-1-format,id=virtio-disk0,bootindex=1 \
  -netdev bridge,br=virbr0,helper=/usr/libexec/qemu-bridge-helper,id=hostnet0 \
  -device e1000e,netdev=hostnet0,id=net0,mac=52:54:00:81:9a:2e,bus=pci.1,addr=0x0 \

  #-drive if=pflash,format=raw,unit=1,file=/home/crobinso/src/ovmf/Build/OvmfX64/DEBUG_GCC5/FV/OVMF_VARS.fd \
  #-chardev file,id=debugcon,path=/tmp/ovmf.log \
  #-machine q35,usb=off,dump-guest-core=off,memory-backend=pc.ram,pflash0=libvirt-pflash0-format \
  #-drive if=none,format=raw,file=/usr/share/edk2/ovmf/OVMF.amdsev.fd,id=libvirt-pflash0-format \
