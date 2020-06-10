# Udacity Blockchain Capstone

This is the capstone project for udacity blockchain nanodegree. The Objective of this project is minting your own tokens to represent your title to the properties.

## Versions

- Truffle v5.1.25 (core: 5.1.25)
- Solidity v0.5.16 (solc-js)
- Node v10.20.1
- Web3.js v1.2.1

## Deployed Contracts Info's

### Contract Address on Rinkeby Network

Square Verifier Contract Address: `0xA2abCE5990A54ed88497D6525c5eF2e332614327`

#### Transactions
- Migrations: `0xab1544d0e4384850cc87969b6be47c151af15167df6d39ac9880a87b98794633`
- Verifier: `0x7c6a79451e48af04f5f522ec3b2a0370fafa85fd884fe6ac304b674e404ddcaa`
- SolnSquareVerifier: `0xbad4649caee71948bb205bfc1dd24b4b090fe9c569e13ec375f50fd380b263ad`

### OpenSea Marketplace

- Seller (lucaslc_test): https://rinkeby.opensea.io/accounts/0xefb7eb9bad9aa82696a85361182f3f5ae1e55462
- Buyer (lucaslc_test02): https://rinkeby.opensea.io/accounts/0xcd7b5a1fdc0b11ebb0f29e7de0f901ae487586a9

### Contract Abi's

- https://github.com/lucaslc-sp/Udacity-blockchain-nanodegree/blob/master/Capstone/zokrates/code/square/abi.json

## How to Execute Application

### Tests

For test contracts and execute unit tests run these commands:

```
 - npm install
 - cd eth-contracts
 - truffle test
```
### Deploy Project

For deploy project, follow the steps:

- Step 1: create a `.secret` file with `metmask mnemonic`
- Step 2: exec command: `truffle migrate --network rinkeby --reset`

## Generate more items (Proofs)

To generate a new valid proof for you contract, you need do some commands on Zokrates:

First of all, install docker: You can find instructions [here](https://docs.docker.com/install/)

| To Do | Command |
| ------------- | ------------- |
| Step 1: Run ZoKrates | docker run -v <Your path to zokrates>:/home/zokrates/code -ti zokrates/zokrates /bin/bash| 
| Step 2: A Quick Overview of the ZoKrates Process | 1.Compile Program</br> 2.Trusted Setup</br>3.Compute-Witness</br>4.Generate-Proof</br>5.Export-Verifier |
| Step 3: Compile the program written in ZoKrates DSL | cd code/zokrates/code/square/ </br> ~/zokrates compile -i square.code |
| Step 4: Generate the Trusted Setup | ~/zokrates setup |
| Step 5: Compute Witness | ~/zokrates compute-witness -a 3 9 |
| Step 6: Generate Proof | ~/zokrates generate-proof |
| Step 7: Export Verifier | ~/zokrates export-verifier|

Copy `proof.json` file and paste in `scripts` folder and update `scripts/mint.js` for use new proof. You need to update `scripts/mint.js` and add the new `proof.json` in `zokratesProof` array.

### Mint Tokens

All the proofs files in `/scripts` are valid proofs that attend `square.code` (square root). 

Is necessary to export following environment variables before mint:

```
export INFURA_KEY="<infura_key>"
export MNEMONIC="<metmask_mnemonic>"
export OWNER_ADDRESS="<my_address_account>"
export CONTRACT_ADDRESS="<deployed_contract_address>"
export NETWORK="rinkeby"
```

Finally, execute to mint tokens and see on the OpenSea items:

```
node scripts/mint.js
```

Enter on opensea and go on account > my items

```
https://rinkeby.opensea.io/accounts/<my_address_account>
```

# Project Resources

* [Remix - Solidity IDE](https://remix.ethereum.org/)
* [Visual Studio Code](https://code.visualstudio.com/)
* [Truffle Framework](https://truffleframework.com/)
* [Ganache - One Click Blockchain](https://truffleframework.com/ganache)
* [Open Zeppelin ](https://openzeppelin.org/)
* [Interactive zero knowledge 3-colorability demonstration](http://web.mit.edu/~ezyang/Public/graph/svg.html)
* [Docker](https://docs.docker.com/install/)
* [ZoKrates](https://github.com/Zokrates/ZoKrates)
