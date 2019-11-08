#!/bin/bash
mkdir /admin
CA_NAME=ca-org1
TLS_FILE=/ca-cert.pem

CA_URL=https://admin:adminpw@ca.org1.example.com:7054
fabric-ca-client enroll -d -u $CA_URL -H /admin --caname ca-org1 --tls.certfiles $TLS_FILE

mkdir -p /admin/msp/admincerts
cp /admin/msp/signcerts/cert.pem /admin/msp/admincerts/

fabric-ca-client register --caname ca-org1 --id.affiliation org1.department1 --id.name idemix --id.secret idemixpw --id.maxenrollments -1 -H /admin --tls.certfiles $TLS_FILE


mkdir -p /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/

OCA_URL=https://idemix:idemixpw@ca.org1.example.com:7054
fabric-ca-client enroll -d -u $OCA_URL --caname ca-org1  -H /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix --tls.certfiles $TLS_FILE
mkdir -p /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/admincerts
fabric-ca-client enroll -d -u $OCA_URL --caname ca-org1  -H /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix --enrollment.type idemix --tls.certfiles $TLS_FILE
cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/signcerts/cert.pem /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/admincerts/
cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/fabric-ca-client-config.yaml /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/config.yaml