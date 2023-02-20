#!/bin/bash

#create certificate using CA

# defaults
FILE_NAME=certificate
PRINT_CERTS=false
PRINT_BASE64_CERTS=false
VIEW_CERT=false

Help()
{
    echo "Create certificates using CA."
    echo ""
    echo "Usage: $0 -c <CN> [-f <filename>] [<options>] <SAN> [<SAN> ...]"
    echo ""
    echo "Options:"
    echo " -h            - This help."
    echo " -c            - Certificate Common Name (CN)."
    echo " -f <filename> - Filename, without extension, for the certificate and key (default: $FILE_NAME)."
    echo " -p            - Print key and certificate files to system out."
    echo " -P            - Print base64 encoded key and certificate to system out."
    echo " -v            - View the created certificate."
    echo ""
    echo "Note: SAN=Subject Alternative Name"
    exit 1
}

Error()
{
    echo "ERROR: $1"
    exit 1
}

if [[ "$1" == "" ]]; then
    echo "No options or arguments."
    Help
fi


# Get the options
while getopts "hf:c:Ppv" option; do
   case $option in
      h) 
        Help;;
      f) 
        FILE_NAME=$OPTARG;;
      c) 
        COMMON_NAME=$OPTARG;;
      p) 
        PRINT_CERTS=true;;
      P) 
        PRINT_BASE64_CERTS=true;;
      v)
        VIEW_CERT=true;;
     \?) # Invalid option
        Error "Unknown option."
   esac
done
#remove options so parameters can be used $1, $2 and so on
shift $((OPTIND - 1))

if [[ "$COMMON_NAME" == "" ]]; then
    Error "-c <common name> not specified."
fi

if [[ "$1" == "" ]]; then
    Error "SAN not specified. At least one SAN is required."
fi

echo "Creating self-signed certificate using CA..."

__cert_dir="."
if [ -d "certs" ]; then
    __cert_dir="./certs"
    FILE_NAME=${__cert_dir}/${FILE_NAME}
fi

__common_name=$COMMON_NAME
__validity_days=1000
__ca_file=certificate/ca.crt
__ca_key_file=certificate/ca.key
__csr_cfg_file=${FILE_NAME}_csr.txt
__csr_file=${FILE_NAME}.csr
__cert_file=${FILE_NAME}.crt
__cert_key_file=${FILE_NAME}.key

#shift
__alt_names_array=($*)

cat > ${__csr_cfg_file} << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
x509_extensions = req_ext
req_extensions = req_ext
distinguished_name = dn

[ dn ]
commonName = ${__common_name}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
EOF
#optionally, add fields under dn:
# organizationName  = IBM
# organizationalUnitName = Technology
# localityName = Helsinki
# stateOrProvinceName = Uusimaa
# countryName = FI
# emailAddress = sami.salkosuo@noreply.com

position=0
for ((i = 0; i < ${#__alt_names_array[@]}; ++i)); do
    # bash arrays are 0-indexed
    position=$(( $position + 1 ))
    name=${__alt_names_array[$i]}
    echo "DNS.$position  = $name" >> ${__csr_cfg_file}
done

#create certificate key:
openssl genrsa -out ${__cert_key_file} 4096

#create CSR:  
openssl req -new -sha256 -key ${__cert_key_file} -out ${__csr_file} -config ${__csr_cfg_file}

#sign CSR usign CA cert
openssl x509 -req \
        -extfile ${__csr_cfg_file} \
        -extensions req_ext \
        -in ${__csr_file} \
        -CA ${__ca_file} \
        -CAkey ${__ca_key_file} \
        -CAcreateserial \
        -out ${__cert_file} \
        -days ${__validity_days} \
        -sha256

#delete temp files
rm -f $__csr_cfg_file
rm -f $__csr_file

#print 
if [[ "$PRINT_CERTS" == "true" ]]; then
    cat $FILE_NAME.key
    cat $FILE_NAME.crt
fi

echo "Creating self-signed certificate using CA...done." 

echo "" 
if [[ "$VIEW_CERT" == "true" ]]; then
    openssl x509 -in $__cert_file -text -noout
else
    echo "View the certificate using command:" 
    echo "  openssl x509 -in $__cert_file -text -noout" 
fi
echo "" 

#print 
if [[ "$PRINT_CERTS" == "true" ]]; then
    cat $FILE_NAME.key
    cat $FILE_NAME.crt
fi

#print base64 certs
if [[ "$PRINT_BASE64_CERTS" == "true" ]]; then
    key=$(cat $FILE_NAME.key | base64 -w 0)
    echo "base64 key: $key"
    echo ""
    cert=$(cat $FILE_NAME.crt | base64 -w 0)
    echo "base64 certificate: $cert"    
fi
