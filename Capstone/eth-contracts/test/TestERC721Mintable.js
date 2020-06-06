var DecentralandERC721Token = artifacts.require('DecentralandERC721Token');

contract('DecentralandERC721Token', accounts => {

    const account0 = accounts[0];
    const account1 = accounts[1];
    const account2 = accounts[2];
    const account3 = accounts[3];
    const account4 = accounts[4];
    const account5 = accounts[5];
    const account6 = accounts[6];
    const account7 = accounts[7];
    const account8 = accounts[8];
    const account9 = accounts[9];



    describe('match erc721 spec', function () {
        beforeEach(async function () { 
            this.contract = await DecentralandERC721Token.new({from: account0});
            await this.contract.mint(account0, 1,{from: account0});
            await this.contract.mint(account1,2,{from: account0});
            await this.contract.mint(account2,3,{from: account0});
            await this.contract.mint(account3,4,{from: account0});
            await this.contract.mint(account4,5,{from: account0});
            await this.contract.mint(account5,6,{from: account0});
            await this.contract.mint(account6,7,{from: account0});
            await this.contract.mint(account7,8,{from: account0});
            await this.contract.mint(account8,9,{from: account0});
            await this.contract.mint(account9,10,{from: account0});
            let owner = await this.contract.ownerOf.call(1,{from: account0});
            assert.equal(owner,account0,"Owner not match..");

            // TODO: mint multiple tokens
        })

        it('should return total supply', async function () { 
            let supply = await this.contract.totalSupply.call({from:account0});
            assert.equal(supply,10,"Supply should be 10 at this point.");
        })

        it('should get token balance', async function () { 
            let balance = await this.contract.balanceOf.call(account0,{from:account0});
            assert.equal(balance.toNumber(),1,"Supply should be 10 at this point.");
        })

        // token uri should be complete i.e: https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1
        it('should return token uri', async function () { 
            let tokenURI = await this.contract.tokenURI.call(1,{from:account0});
            assert.equal(tokenURI,"https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/1","URI does not match.")
        })

        it('should transfer token from one owner to another', async function () { 
            await this.contract.approve(account1,1,{from:account0});
            await this.contract.transferFrom(account0,account1,1,{from:account0});
            let owner = await this.contract.ownerOf.call(1,{from:account1});
            assert.equal(owner,account1,"Ownership didnt transferred.");
        })
    });

    describe('have ownership properties', function () {
        beforeEach(async function () { 
            this.contract = await DecentralandERC721Token.new({from: account0});
        })

        it('should fail when minting when address is not contract owner', async function () { 
            let exception = false;
            try{
                await this.contract.mint(account1,11,{from: account1});
            }
            catch(e){
                exception = true;
            }
            assert.equal(exception,true,"Minting without contract owner.");
        })

        it('should return contract owner', async function () { 
            let contract_owner = await this.contract.getOwner.call({from:account0});
            assert.equal(contract_owner,account0,"Contract owner does not match.")
        })

    });
})