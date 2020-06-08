# Udacity Blockchain Capstone

This is the capstone project for udacity blockchain nanodegree. The Objective of this project is minting your own tokens to represent your title to the properties.

## Versions

- Truffle v5.1.25 (core: 5.1.25)
- Solidity v0.5.16 (solc-js)
- Node v10.20.1
- Web3.js v1.2.1

## Deployed Contracts Info's

### Contract Address on Rinkeby Network

Square Verifier Contract Address: `0x0b6edfccffe33a9ada986948a21bed71e8b00610`

#### Transactions
- Migrations: `0xd906fb8de81298952f421ba446aada85e9da58a04027847f91b096734db508be`
- Verifier: `0x81e7e6186eba76759b7dd992a3e89b06006e03fb75d864d886e803fa961f75a6`
- SolnSquareVerifier: `0xa5947291c635af5be9c8e19a58ecd94c24fdff94664fb4b4a512a33a92851ec0`

### OpenSea Marketplace

- Seller (lucaslc_test): https://rinkeby.opensea.io/accounts/0xefb7eb9bad9aa82696a85361182f3f5ae1e55462
- Buyer (lucaslc): https://rinkeby.opensea.io/accounts/0x336f878fd7382167fbacd5240d05651a3d014453

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

| To Do | Command |
| ------------- | ------------- |
| Step 1: Install Docker | You can find instructions for installing it [here](https://docs.docker.com/install/)|
| Step 2: Run ZoKrates | docker run -v <Your path to zokrates>:/home/zokrates/code -ti zokrates/zokrates /bin/bash| 
| Step 3: A Quick Overview of the ZoKrates Process | 1.Compile Program</br> 2.Trusted Setup</br>3.Compute-Witness</br>4.Generate-Proof</br>5.Export-Verifier |
| Step 4: Compile the program written in ZoKrates DSL | cd code/zokrates/code/square/ </br> ~/zokrates compile -i square.code |
| Step 5: Generate the Trusted Setup | ~/zokrates setup |
| Step 6: Compute Witness | ~/zokrates compute-witness -a 3 9 |
| Step 7: Generate Proof | ~/zokrates generate-proof |
| Step 8: Export Verifier | ~/zokrates export-verifier|

Copy `proof.json` file and paste in `scripts` folder and update `scripts/mint.js` for use new proof.

### Mint Tokens

All the proofs files in `scripts/mint` are valid proofs that attend `square.code` (square root). 

Is necessary to export following environment variables before mint:

```
export INFURA_KEY="<infura_key>"
export MNEMONIC="<metmask_mnemonic>"
export OWNER_ADDRESS="<my_address>"
export CONTRACT_ADDRESS="<deployed_contract_address>"
export NETWORK="rinkeby"
```

Finally, execute to mind tokens and see on the OpenSea items:

```
node scripts/mint.js
```

https://rinkeby.opensea.io/


# Project Resources

* [Remix - Solidity IDE](https://remix.ethereum.org/)
* [Visual Studio Code](https://code.visualstudio.com/)
* [Truffle Framework](https://truffleframework.com/)
* [Ganache - One Click Blockchain](https://truffleframework.com/ganache)
* [Open Zeppelin ](https://openzeppelin.org/)
* [Interactive zero knowledge 3-colorability demonstration](http://web.mit.edu/~ezyang/Public/graph/svg.html)
* [Docker](https://docs.docker.com/install/)
* [ZoKrates](https://github.com/Zokrates/ZoKrates)
