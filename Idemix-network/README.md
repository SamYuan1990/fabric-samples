Will have 1 CA, orderer, peer, cli.
Channel Org org1 and Idemix org1.
Currently in channel msp config, we need to different between x509 type msp and idemix type msp, even same user.
A chaincode in golang language with cid.getX509cert(), invoke chaincode two times by x509 cert and idemix cert.

./idemixNetwork.sh up
./idemixNetwork.sh down
