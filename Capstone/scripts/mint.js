const HDWalletProvider = require("truffle-hdwallet-provider")
const zokratesProof = [
    require("./proof_2_4.json"),
    require("./proof_3_9.json"),
    require("./proof_4_16.json"),
    require("./proof_5_25.json"),
    require("./proof_6_36.json"),
    require("./proof_7_49.json"),
    require("./proof_8_64.json"),
    require("./proof_9_81.json"),
    require("./proof_10_100.json"),
    require("./proof_11_121.json"),
    require("./proof_12_144.json")
];
const web3 = require('web3')
const OWNER_ADDRESS = process.env.OWNER_ADDRESS
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS
const NETWORK = process.env.NETWORK
const MNEMONIC = process.env.MNEMONIC
const INFURA_KEY = process.env.INFURA_KEY

if (!MNEMONIC || !INFURA_KEY || !OWNER_ADDRESS || !NETWORK) {
    console.error("Please set a mnemonic, infura key, owner, network, and contract address.")
    return
}

const contract = require('../eth-contracts/build/contracts/SolnSquareVerifier.json'); 
const ABI = contract.abi;

async function main() {
    const provider = new HDWalletProvider(MNEMONIC, `https://${NETWORK}.infura.io/v3/${INFURA_KEY}`)
    const web3Instance = new web3(
        provider
    )

    if (CONTRACT_ADDRESS) {
        const r2token = new web3Instance.eth.Contract(ABI, CONTRACT_ADDRESS, { gasLimit: "4500000" })
        for (let i = 1; i < zokratesProof.length ; i++) {
            try {
                const proofs = Object.values(zokratesProof[i].proof);
                const inputs = zokratesProof[i].inputs;
                console.log("OWNER_ADDRESS "+ OWNER_ADDRESS + "\n");
                console.log("i "+i+ "\n");
                console.log("proofs "+ proofs+ "\n");
                console.log("inputs "+ inputs+ "\n");
                let tx = await r2token.methods.addSolution(OWNER_ADDRESS, i).send({ from: OWNER_ADDRESS });
                console.log("Solution added. Transaction: " + tx.transactionHash);
                let tx2 = await r2token.methods.mintToken(OWNER_ADDRESS, i, ...proofs, inputs).send({ from: OWNER_ADDRESS });
                console.log("Minted item. Transaction: " + tx2.transactionHash);
            } catch (e) {
                console.log(e);
            }
        }
    }
}

main()