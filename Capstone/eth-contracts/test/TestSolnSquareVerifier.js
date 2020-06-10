const SolnSquareVerifier = artifacts.require('SolnSquareVerifier');
const zokratesProof = require("../../scripts/proof_2_4.json");
const zokratesProof02 = require("../../scripts/proof_3_9.json");
const zokratesWrongProof = require("../../scripts/wrong_proof.json");

contract('TestSolnSquareVerifier', accounts => {
    const addr = accounts[0];
    const tokenId = 1;

    // First proof
    const proofs = Object.values(zokratesProof.proof);
    const inputs = zokratesProof.inputs;

    // Second proof
    const proofs02 = Object.values(zokratesProof02.proof);
    const inputs02 = zokratesProof02.inputs;

    // wrong proof
    const wrong_proofs = Object.values(zokratesWrongProof.proof);
    const wrong_inputs = zokratesWrongProof.inputs;
    
    describe('test SolnSquareVerifier', function(){
        before(async function() {
            this.contract = await SolnSquareVerifier.new();
        });

        // Test if a new solution can be added for contract - SolnSquareVerifier
        it('should add new solutions', async function(){
            const result = await this.contract.addSolution(addr, tokenId, ...proofs, inputs);
            const added_event = result.logs[1].event;
            assert.equal(added_event, 'SolutionAdded', 'Invalid event emitted');
        });

        // Test if unique solution check is working
        it('should not add duplicate solutions', async function() {
            let exception_message = "";
            try {
                await this.contract.addSolution(addr, tokenId, ...proofs, inputs);
            } catch(ex) {
                exception_message = ex.reason;
            }
            assert.equal(exception_message, 'Solution need to be unique')
        });

        // Test if solution check is working
        it('should not add invalid solutions', async function() {
            let exception_message = "";
            try {
                await this.contract.addSolution(addr, tokenId, ...wrong_proofs, wrong_inputs);
            } catch(ex) {
                exception_message = ex.reason;
            }
            assert.equal(exception_message, 'Solution is invalid')
        });

        // Test if an ERC721 token can be minted for contract - SolnSquareVerifier
        it('should mint tokens for contract', async function(){
            // using new proof
            let result = await this.contract.mintToken(addr, tokenId, ...proofs02, inputs02);
            let tokenTransferredEvent = result.logs[3].event;
            assert.equal(tokenTransferredEvent, 'TokenMint', 'Invalid event emitted');
        });
    });
})