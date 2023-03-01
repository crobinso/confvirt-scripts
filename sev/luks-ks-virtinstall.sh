VMNAME=tmp-lukstest
SEVES=1
POLICY=5
DOCONSOLE=1
DOSECRET=1

source sev-env.sh



install() {
    sudo rm -rf /var/lib/libvirt/images/$VMNAME.qcow2 || :
    sudo virsh destroy $VMNAME || :
    sudo virsh undefine --nvram $VMNAME || :

    sudo ~/src/virt-manager/virt-install \
        --name $VMNAME --ram 8096 --disk size=20 \
        --nographics \
        --location https://dl.fedoraproject.org/pub/fedora/linux/development/37/Server/x86_64/os/ \
        --initrd-inject luks.ks \
        --extra-args "inst.ks=file:/luks.ks console=ttyS0" \
        --tpm none \
        --boot firmware=efi \
        --memorybacking locked=on \
        --debug
}

run() {
    PREFIX="sevctl_${VMNAME}"
    DHCERT=`cat $CERTDIR/${PREFIX}_godh.b64`
    SESSION=`cat $CERTDIR/${PREFIX}_session.b64`

    sudo ~/src/virt-manager/virt-xml $VMNAME --edit \
        --launchSecurity sev,policy=$POLICY,kernelHashes=on,session=$SESSION,dhCert=$DHCERT
}

# XXX:
install
#validate
