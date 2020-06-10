var ERC721MintableComplete = artifacts.require('CustomERC721Token');

contract('TestERC721Mintable', accounts => {

    const account_one = accounts[0];
    const account_two = accounts[1];

    describe('match erc721 spec', function () {
        beforeEach(async function () {
            this.contract = await ERC721MintableComplete.new({ from: account_one });

            // TODO: mint multiple tokens
            await this.contract.mint(account_one, 1, { from: account_one })
            await this.contract.mint(account_two, 2, { from: account_one })
        })

        it('should return total supply', async function () {
            const totalSupply = await this.contract.totalSupply({ from: account_one })
            assert.equal(totalSupply, 2);
        })

        it('should get token balance', async function () {
            const token_balance = await this.contract.balanceOf.call(account_one,{from:account_one});
            assert.equal(token_balance.toNumber(), 1);
        })

        // token uri should be complete i.e: https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1
        it('should return token uri', async function () {
            const token_uri = await this.contract.tokenURI(1, { from: account_one });
            assert.equal(token_uri, "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1");
        })

        it('should transfer token from one owner to another', async function () {
            // Transfer from account_one to account_two
            await this.contract.transferFrom(account_one, account_two, 1, {from: account_one });
            const newOwner = await this.contract.ownerOf(1);
            assert.equal(newOwner, account_two,"Ownership didnt transferred.");
        })
    });

    describe('have ownership properties', function () {
        beforeEach(async function () {
            this.contract = await ERC721MintableComplete.new({ from: account_one });
        })

        it('should fail when minting when address is not contract owner', async function () {
            let exception_message = "";
            try {
                await this.contract.mint(account_two, 1, { from: account_two })
            } catch (ex) {
                exception_message = ex.reason;
            }
            assert.equal(exception_message, "Caller is not contract owner")
        })

        it('should return contract owner', async function () {
            const owner = await this.contract.getOwner();
            assert.equal(owner.receipt.from, account_one.toLowerCase());
        })

    });
})