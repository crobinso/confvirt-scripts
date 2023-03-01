VMNAME=cole-sev-plain-kernel
DO_KERNEL=1
#DOCONSOLE=1
#DOSECRET=1

SCRIPTDIR="$(dirname $(realpath $0))"
source "${SCRIPTDIR}/sev-env.sh"

validate
