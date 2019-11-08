#!/bin/bash

export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

function replaceJson() {
  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and delete it at the end of the function
  ARCH=$(uname -s | grep Darwin)
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  # Copy the template to the file that will be modified to add the private key
  # cp docker-compose-template.yaml docker-compose.yaml

  # The next steps will replace the template's contents with the
  # actual values of the private key file names for the two CAs.
  CURRENT_DIR=$PWD
  cd crypto-config/idemix/msp/user/
  sed $OPTS "s/Cred/cred/g" SignerConfig
  sed $OPTS "s/Sk/sk/g" SignerConfig
  cd "$CURRENT_DIR"
}

function replacePrivateKey() {
  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and delete it at the end of the function
  ARCH=$(uname -s | grep Darwin)
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  # Copy the template to the file that will be modified to add the private key
  cp docker-compose-template.yaml docker-compose.yaml

  # The next steps will replace the template's contents with the
  # actual values of the private key file names for the two CAs.
  CURRENT_DIR=$PWD
  cd crypto-config/peerOrganizations/org1.example.com/ca/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yaml
}

function networkUp(){
    echo up
    cryptogen generate --config=./crypto-config.yaml
    replacePrivateKey
    export IMAGE_TAG=1.4.0
    export COMPOSE_PROJECT_NAME=idemix-network
    # start ca
    docker-compose up -d ca0
    sleep 10
    # copy file from ca container for idemix gensis block
    # ca-tools
    docker-compose up -d ca-tools
    sleep 5
    docker cp ca.org1.example.com:/etc/hyperledger/fabric-ca-server-config/ca.org1.example.com-cert.pem  crypto-config
    docker cp crypto-config/ca.org1.example.com-cert.pem ca-tools:/ca-cert.pem
    docker exec ca-tools ./scripts/cascript.sh
    mkdir -p crypto-config/peerOrganizations/org2.example.com/msp
    ls crypto-config/idemix/
    ls crypto-config/peerOrganizations/org2.example.com/
    #cp -rf crypto-config/idemix/* crypto-config/peerOrganizations/org2.example.com/
    docker cp ca.org1.example.com:/etc/hyperledger/fabric-ca-server/msp crypto-config/peerOrganizations/org2.example.com
    docker cp ca.org1.example.com:/etc/hyperledger/fabric-ca-server/IssuerPublicKey crypto-config/peerOrganizations/org2.example.com
    docker cp ca.org1.example.com:/etc/hyperledger/fabric-ca-server/IssuerRevocationPublicKey crypto-config/peerOrganizations/org2.example.com
    cp crypto-config/peerOrganizations/org2.example.com/IssuerPublicKey crypto-config/peerOrganizations/org2.example.com/msp
    cp crypto-config/peerOrganizations/org2.example.com/IssuerRevocationPublicKey crypto-config/peerOrganizations/org2.example.com/msp/RevocationPublicKey
    # gensis block
    mkdir -p ./channel-artifacts
    configtxgen -profile TwoOrgsOrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block
    # channel tx
    sleep 10
    configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
    # peer
    docker-compose up -d peer0.org1.example.com
    # orderer
    docker-compose up -d orderer.example.com
    # channel
    # cli
    replaceJson
    docker-compose up -d cli
    #docker exec -it cli -- mkdir -p /opt/go/src/github.com/hyperledger
    #docker cp /Users/samyuan/go/src/github.com/hyperledger/fabric cli:/opt/go/src/github.com/hyperledger/
    docker cp peer cli:/usr/local/bin/peer
    docker exec cli ./scripts/scripts.sh 
    # chaincode
}

function networkDown(){
    docker-compose down
    removeUnwantedImages
    rm -rf ./crypto-config
    rm docker-compose.yaml
    rm -rf ./channel-artifacts
    echo down
}

#Create the network using docker compose
if [ "${1}" == "up" ]; then
  networkUp
elif [ "${1}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${1}" == "restart" ]; then ## Clear the network
  networkDown
  networkUp
fi