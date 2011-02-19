#!/bin/bash

#
# Generate a root certificate authority
#
# Script generates a root CA for signing server and user certificates
#

. _common/variables
. _common/functions

checkIfRootCaExists && errorExistingCa
setCnfFromTemplate $SSL_CA_CONFIG

generateMasterKey $DEFAULT_CA_SIZE
generateMasterCert $DEFAULT_CA_AGE

generateCertsDbStore
mv ca.pem ca.key $CADB_DIR

cleanup

echo "Done."
