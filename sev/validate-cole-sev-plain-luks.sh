VMNAME=cole-sev-plain-luks
DOSECRET=1
DOCONSOLE=1

SCRIPTDIR="$(dirname $(realpath $0))"
source "${SCRIPTDIR}/sev-env.sh"

validate
