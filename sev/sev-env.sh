CERTDIR=/home/crobinso/src/sevcerts/$VMNAME
VIRSH="$HOME/src/libvirt/build/tools/virsh"
SCRIPTDIR="$(dirname $(realpath $0))"

validate() {
    VALIDATE="$HOME/src/libvirt/tools/virt-qemu-sev-validate"
    DOCONSOLE="${DOCONSOLE:-$DOSECRET}"

    if [ "$REGEN" = "1" ] ; then
        sudo $VIRSH destroy $VMNAME 2>&1 > /dev/null || :
        regenerate_session
    fi

    if [ "$SEVES" = "1" ] ; then
        #ESARGS="--vmsa-cpu0 $CERTDIR/vmsa0.bin --vmsa-cpu1 $CERTDIR/vmsa1.bin"
        ESARGS=""
    fi

    if [ "$DOSECRET" = "1" ] ; then
        sudo $VIRSH destroy $VMNAME 2>&1 > /dev/null || :
        SECRETARGS="--inject-secret 736869e5-84f0-4973-92ec-06879ce3da0b:${SCRIPTDIR}/secret.txt"
        sudo $VIRSH start --paused $VMNAME
    else
        sudo $VIRSH start $VMNAME || :
    fi


    $VALIDATE \
    --domain $VMNAME \
    --tek $CERTDIR/sevctl_${VMNAME}_tek.bin \
    --tik $CERTDIR/sevctl_${VMNAME}_tik.bin \
    $ESARGS $SECRETARGS \
    --insecure \
    --debug \
    "$@"


    if [ "$DOCONSOLE" = "1" ] ; then
        sudo $VIRSH console $VMNAME
        sleep 2
    fi
    sudo $VIRSH destroy $VMNAME
}


regenerate_session() {
    SEVCTL=$HOME/src/sevctl/target/debug/sevctl
    PREFIX="sevctl_${VMNAME}"

    POLICY=3
    [ "$SEVES" = "1" ] && POLICY="5"
    KERNELHASHES="off"
    [ "$DO_KERNEL" = "1" ] && KERNELHASHES="on"

    mkdir -p $CERTDIR
    sudo $SEVCTL export -f $CERTDIR/sevctl-export.chain
    sudo $SEVCTL session $CERTDIR/sevctl-export.chain $POLICY --name $PREFIX
    mv -f ${PREFIX}* $CERTDIR

    DHCERT=`cat $CERTDIR/${PREFIX}_godh.b64`
    SESSION=`cat $CERTDIR/${PREFIX}_session.b64`

    sudo virt-xml ${VMNAME} --edit  \
        --launchSecurity type=sev,policy=$POLICY,session=$SESSION,dhCert=$DHCERT,kernelHashes=$KERNELHASHES \
        --confirm
}

set -x
set -e
