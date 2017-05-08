#!/bin/bash
# script customized using as base script the one published at
# https://www.mongodb.com/blog/post/secure-mongodb-with-x-509-authentication

OUTPUT_DIR=/srv/mongodb

#/srv/mongodb
EXPIRATION=3650



cd $OUTPUT_DIR
echo "##### STEP 1: Generate root CA "
pwd="PaWd$RANDOM$RANDOM$pwdRANDOM$pwdRANDOM.$RANDOM$RANDOM?$RANDOM";
echo $pwd > $OUTPUT_DIR/pwd
echo "PASSWORD GENERATED and saved at $OUTPUT_DIR/pwd "
openssl genrsa -aes256 -out root-ca.key -passout pass:"$pwd"  2048
openssl req -new -x509 -days 3650 -key root-ca.key -out root-ca.crt -passin pass:"$pwd" -subj "$dn_prefix/CN=ROOTCA"

mkdir -p RootCA/ca.db.certs
echo "01" >> RootCA/ca.db.serial
touch RootCA/ca.db.index
echo $RANDOM >> RootCA/ca.db.rand
mv root-ca* RootCA/

echo "##### STEP 2: Create CA config"
# Generate CA config
cat >> root-ca.cfg <<EOF
[ RootCA ]
dir             = ./RootCA
certs           = \$dir/ca.db.certs
database        = \$dir/ca.db.index
new_certs_dir   = \$dir/ca.db.certs
certificate     = \$dir/root-ca.crt
serial          = \$dir/ca.db.serial
private_key     = \$dir/root-ca.key
RANDFILE        = \$dir/ca.db.rand
default_md      = sha256
default_days    = EXPIRATION
default_crl_days= EXPIRATION
email_in_dn     = no
unique_subject  = no
policy          = policy_match

[ SigningCA ]
dir             = ./SigningCA
certs           = \$dir/ca.db.certs
database        = \$dir/ca.db.index
new_certs_dir   = \$dir/ca.db.certs
certificate     = \$dir/signing-ca.crt
serial          = \$dir/ca.db.serial
private_key     = \$dir/signing-ca.key
RANDFILE        = \$dir/ca.db.rand
default_md      = sha256
default_days    = EXPIRATION
default_crl_days= EXPIRATION
email_in_dn     = no
unique_subject  = no
policy          = policy_match

[ policy_match ]
countryName     = match
stateOrProvinceName = match
localityName            = match
organizationName    = match
organizationalUnitName  = optional
commonName      = supplied
emailAddress        = optional

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment

[ v3_ca ]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = CA:true
EOF

sed -i s/EXPIRATION/$EXPIRATION/g root-ca.cfg

echo "##### STEP 3: Generate signing key"
# We do not use root key to sign certificate, instead we generate a signing key
openssl genrsa -aes256  -out signing-ca.key -passout pass:"$pwd" 2048

openssl req -new -days $EXPIRATION -key signing-ca.key -passin pass:"$pwd" -out signing-ca.csr -subj "$dn_prefix/CN=CA-SIGNER"
openssl ca -batch -name RootCA -passin pass:"$pwd" -config root-ca.cfg -extensions v3_ca  -out signing-ca.crt -infiles signing-ca.csr
mkdir -p SigningCA/ca.db.certs
echo "01" >> SigningCA/ca.db.serial
touch SigningCA/ca.db.index
# Should use a better source of random here..
echo $RANDOM >> SigningCA/ca.db.rand
mv signing-ca* SigningCA/

# Create root-ca.pem
cat RootCA/root-ca.crt SigningCA/signing-ca.crt > root-ca.pem

echo "created $OUTPUT_DIR/root-ca.pem file"


