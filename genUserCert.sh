#!/bin/bash

# 
# Issue a TLS/SSL user certificate
#
# Script generates TLS/SSL user certificates for authenticating web browser 
# clients (e.g. InternetExplorer, Firefox). This script automatically 
# creates password protected pkcs12 files that users can import 
# into Firefox or IE (double click) to allow access to a TLS/SSL user certificate 
# protected web-server.
#

. _common/variables
. _common/functions

checkIfRootCaExists || errorNoCa
COMMENT="TLS/SSL user certificate"

function usage
{
	cat <<-EOF
	`basename $0` generates a TLS/SSL user certificate signed by ca.pem with
	the distinguished name: DN=CN/emailAddress/O/OU/C/ST/L. This DN can be used with
	SSLRequire and SSLFakeAuth for user access management.
	
	Example (minimal - uses defaults of script and full):
	./`basename $0` -C "Jan Novak" -e "jnovak@openindiana.cz" -x "My Passvvord" -p "secret-CA-password"
	./`basename $0` -C "Jan Novak" -e "jnovak@openindiana.cz" -x "My Passvvord" -p "secret-CA-password" -o "OpenIndiana Czech" -u "OpenIndiana Czech Secure Server" -c CZ -s "Plzensky kraj" -l Plzen
	
	These options are recognized:		Default:

	-C   Common Name (CN)		"$CN"
	-e   full email address of user	$EMAIL
	-x   P12 import/export userpassword 	$EXPORTPASSWORD
	-p   CA master password		$CAPASSWORD
	-c   country (two letters, e.g. DE)	$C
	-s   state (ST)			$ST
	-l   city (L)			$L
	-o   organisation (O)		"$O"
	-u   organisational unit (OU)	"$U"
	-d   days user cert is valid for	$DEFAULT_USER_AGE
	-h   show usage
	EOF
}    

while getopts C:c:s:l:o:u:n:e:x:p:h OPT; do
    case $OPT in
        C) CN=$OPTARG;;
        x) EXPORTPASSWORD=$OPTARG;;
        p) CAPASSWORD=$OPTARG;;
        c) C=$OPTARG;;
        s) ST=$OPTARG;;
        l) L=$OPTARG;;
        u) U=$OPTARG;;
        o) O=$OPTARG;;
        e) EMAIL=$OPTARG;;
        h) usage; exit 2;;
        *) echo unrecognized option: $OPT; usage; exit 2;;
    esac
done

if [[ $CN == "" || $EMAIL == "" || $CAPASSWORD == "" ]]; then
	echo "*** ERROR: CommonName (CN), full admin email-address, and CA password required (-C -e -p)!"
	echo ""
	usage; exit 2;
fi

if [[ $EXPORTPASSWORD == "" ]]; then
	echo "*** ERROR: P12 export password required (-x option)!"
	echo ""
	usage; exit 3;
fi

checkIfUserCertExists $EMAIL && exitUserExists

showValuesFromArgs "CN EMAIL C ST L U O"
generateCertsDbStore

echo "========== REQUEST (key and csr) =========="
generatePrivateKey $EMAIL $DEFAULT_USER_SIZE

SUBJECT_DN="/CN=$CN/emailAddress=$EMAIL/O=$O/OU=$U/C=$C/ST=$ST/L=$L"

setCnfFromTemplate $SSL_USER_CONFIG

echo "Creating certificate request for $SUBJECT_DN ..."
generateCertRequest $EMAIL


echo "========== SIGNING (crt) =========="
echo "CA signing: $EMAIL.csr -> $EMAIL.pem:"
signCertRequest $EMAIL

echo "CA verifying: $EMAIL.pem <-> CA cert"
verifyCertificate $EMAIL

echo "========== EXPORTING: P12 =========="
generatePkcs12

generateSslFakeAuth > $EMAIL.sslFakeAuth
generateSslFakeAuth >> $APACHE_HTPASSWD

[ -x "$USERSDB_DIR/$EMAIL" ] || mkdir -p "$USERSDB_DIR/$EMAIL"
mv $EMAIL.* "$USERSDB_DIR/$EMAIL"

cleanup

echo "Done."

