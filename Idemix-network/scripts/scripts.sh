#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo

. scripts/utils.sh

export CC_SRC_PATH="github.com/chaincode/chaincode_example02/go"
export CHANNEL_NAME=mychannel
export DELAY=3
export LANGUAGE=golang

setIdeMixGlobals() {
  PEER=$1
  ORG=$2
  if [ $ORG -eq 1 ]; then
  	export CORE_PEER_LOCALMSPTYPE=idemix
	  echo $CORE_PEER_LOCALMSPTYPE
    CORE_PEER_LOCALMSPID=idemixMSPID1
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/
    mkdir -p /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/user
    cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/user/SignerConfig /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/user/SignerConfig
    mkdir -p /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/ca
    cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/IssuerRevocationPublicKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/ca/RevocationKey
    cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/IssuerPublicKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/ca/IssuerPublicKey
    cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/msp/keystore/IssuerSecretKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/ca
    #mkdir -p /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/msp
    cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/IssuerRevocationPublicKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/RevocationPublicKey
    #cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/IssuerPublicKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/msp/IssuerPublicKey
    if [ $PEER -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.org1.example.com:7051
    else
      CORE_PEER_ADDRESS=peer1.org1.example.com:8051
    fi
   fi
}

setIdeMixGlobals2() {
  PEER=$1
  ORG=$2
  if [ $ORG -eq 1 ]; then
  	#export CORE_PEER_LOCALMSPTYPE=idemix
	  #echo $CORE_PEER_LOCALMSPTYPE
    CORE_PEER_LOCALMSPID="Org1MSP"
    CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp
    cp /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/IssuerRevocationPublicKey /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/idemix/msp/RevocationPublicKey
    if [ $PEER -eq 0 ]; then
      CORE_PEER_ADDRESS=peer0.org1.example.com:7051
    else
      CORE_PEER_ADDRESS=peer1.org1.example.com:8051
    fi
   fi
}

NewparsePeerConnectionParameters() {
  # check for uneven number of peer and org parameters
  if [ $(($# % 2)) -ne 0 ]; then
    exit 1
  fi

  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    PEER="peer$1.org$2"
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "true" ]; then
      TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$1_ORG$2_CA")
      PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    fi
    # shift by two to get the next pair of peer/org parameters
    shift
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

# chaincodeInvoke <peer> <org> ...
# Accepts as many peer/org pairs as desired and requests endorsement from each
chaincodeInvokeNew() {
  NewparsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode invoke -o orderer.example.com:7050 -C $CHANNEL_NAME -n mycc $PEER_CONN_PARMS -c '{"Args":["move","a","b","10"]}' >&log.txt
    res=$?
    set +x
  else
    set -x
    env
    peer chaincode invoke -o orderer.example.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n mycc $PEER_CONN_PARMS -c '{"Args":["move","a","b","10"]}' >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
  echo
}

createChannel() {
	setGlobals 0 1 2

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
		joinChannelWithRetry 0 1
		echo "===================== peer${peer}.org${org} joined channel '$CHANNEL_NAME' ===================== "
		sleep $DELAY
		echo
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Install chaincode on peer0.org1 and peer0.org1
echo "Installing chaincode on peer0.org1..."
installChaincode 0 1

# Instantiate chaincode on peer0.org1
echo "Instantiating chaincode on peer0.org1..."
instantiateChaincode 0 1

# Query on chaincode on peer1.org1, check if the result is 90
#echo "Querying chaincode on peer0.org1..."
#chaincodeQuery 0 1 100

sleep 10

setGlobals 0 1
chaincodeInvokeNew 0 1

sleep 10

setIdeMixGlobals2 0 1
chaincodeInvokeNew 0 1

setIdeMixGlobals 0 1
chaincodeInvokeNew 0 1

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0