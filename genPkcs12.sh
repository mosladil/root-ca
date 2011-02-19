#!/bin/bash

#
# Generate a client PKC12 certificate with a new password
#

. _common/variables
. _common/functions

checkIfRootCaExists || errorNoCa

function usage
{
        cat <<-EOF
	Usage:
	./`basename $0` -e jnovak@openindiana.cz -p "My-New-Passvv0rd"
	EOF
}

while getopts e:p:h OPT; do
    case $OPT in
        e) EMAIL=$OPTARG;;
		p) EXPORTPASSWORD=$OPTARG;;
		h) usage;;
        *) echo unrecognized option: $OPT; usage; exit 2;;
    esac
done

if [[ "$EMAIL" == "" || "$EXPORTPASSWORD"  == "" ]]; then
    echo "*** ERROR: missing arguments"; usage; exit 1
fi

USER_DIR=$USERSDB_DIR/$EMAIL

[ -f $USER_DIR/$EMAIL.key ] || exitKeyNotFound
[ -f $USER_DIR/$EMAIL.pem ] || exitCertNotFound

generatePkcs12

echo "Done."
