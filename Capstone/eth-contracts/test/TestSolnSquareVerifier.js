const SolnSquareVerifier = artifacts.require('SolnSquareVerifier');
const zokratesProof = require("../../zokrates/code/square/proof.json");

contract('TestSolnSquareVerifier', accounts => {
    const to = accounts[1];
    const tokenId = 1;
    const proofs = Object.values(zokratesProof.proof);
    const inputs = zokratesProof.inputs;
    
    describe('test SolnSquareVerifier', function(){
        beforeEach(async function() {
            this.contract = await SolnSquareVerifier.new();
        });

        // Test if a new solution can be added for contract - SolnSquareVerifier
        it('should add new solutions', async function(){
            const tx = await this.contract.addSolution(to, tokenId);
            const added_event = tx.logs[0].event;
            assert.equal(added_event, 'SolutionAdded', 'Invalid event emitted');
        });

        // Test if an ERC721 token can be minted for contract - SolnSquareVerifier
        it('should mint tokens for contract', async function(){
            let tx = await this.contract.mintToken(to, tokenId, ...proofs, inputs);
            let tokenTransferredEvent = tx.logs[0].event;
            assert.equal(tokenTransferredEvent, 'Verified', 'Invalid event emitted');
        });
    });
})