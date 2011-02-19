#!/bin/bash

#
# Issue a TLS/SSL server certificate
#
# Script generates a TLS/SSL server certificate signed by ca.pem with
# the distinguished name: DN=CN/emailAddress/O/OU/C/ST/L.
# This certificate can be used for Apache to provide TLS/SSL encryption
# and/or for authenticating a web server.
#

. _common/variables
. _common/functions

checkIfRootCaExists || errorNoCa
COMMENT="TLS/SSL server certificate"

function usage
{
	cat <<-EOF
	Example (minimal - uses defaults of script and full):
	./`basename $0` -C server.openindiana.cz -e "root@openindiana.cz" -p "secret-CA-password"
	./`basename $0` -C server.openindiana.cz -e "root@openindiana.cz" -p "secret-CA-password" -o "OpenIndiana Czech" -u "OpenIndiana Czech Secure Server" -c CZ -s "Plzensky kraj" -l Plzen
	
	These options are recognized:		Default:

	-C 	Common Name (CN) NO-SPACES!	$CN
	-e 	full email address of admin	$EMAIL
	-p	CA master password		********
	-N	comment				$COMMENT
	-c	country (two letters, e.g. DE)	$C
	-s	state (ST)			$ST
	-l 	city (L)			$L
	-o 	organisation (O)		$O
	-u 	organisational unit (OU)	$U
	-h      show usage
	EOF
}

while getopts C:N:c:s:l:o:u:n:e:p:h OPT; do
    case $OPT in
	C) CN=$OPTARG;;
	N) COMMENT=$OPTARG;;
	p) CAPASSWORD=$OPTARG;;
	c) C=$OPTARG;;
	s) ST=$OPTARG;;
	l) L=$OPTARG;;
	u) U=$OPTARG;;
	o) O=$OPTARG;;
	e) EMAIL=$OPTARG;;
	h) usage; exit 2;;
	*) echo Unrecognized option: $OPT; usage; exit 2;;
    esac
done

if [[ $CN == "" || $EMAIL == "" || $CAPASSWORD == "" ]]; then
	echo "*** ERROR: CommonName (CN), full admin email-address, and CA password required (-C -e -p)!"
	echo ""
	usage; exit 2;
fi

checkIfServerCertExists $CN && exitServerExists

showValuesFromArgs "COMMENT CN EMAIL C ST L U O"
generateCertsDbStore

echo "========== REQUEST (key and csr) =========="
generatePrivateKey $CN $DEFAULT_SERVER_SIZE

SUBJECT_DN="/CN=$CN/emailAddress=$EMAIL/O=$O/OU=$U/C=$C/ST=$ST/L=$L"

setCnfFromTemplate "$SSL_SERVER_CONFIG"

echo "Creating certificate request for $SUBJECT_DN ..."
generateCertRequest $CN

echo "========== SIGNING (crt) =========="
echo "CA signing: $CN.csr -> $CN.pem:"
signCertRequest $CN

echo "CA verifying: $CN.pem <-> CA cert"
verifyCertificate $CN

[ -x $SERVERDB_DIR/$CN ] || mkdir -p $SERVERDB_DIR/$CN
mv $CN.* $SERVERDB_DIR/$CN

cleanup

echo "Done."
