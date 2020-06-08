pragma solidity >=0.4.21 <0.6.0;

// TODO define a contract call to the zokrates generated solidity contract <Verifier> or <renamedVerifier>
import { DecentralandERC721Token } from "./ERC721Mintable.sol";
import { Verifier } from "./Verifier.sol";

// TODO define another contract named SolnSquareVerifier that inherits from your ERC721Mintable class
contract SolnSquareVerifier is Verifier, DecentralandERC721Token {

    // TODO define a solutions struct that can hold an index & an address
    struct Solution {
        uint256 tokenId;
        address to;
        bool used;
    }

    // TODO define an array of the above struct
    Solution[] solutions;

    // TODO define a mapping to store unique solutions submitted
    mapping(uint256 => Solution) uniqueSolutions;

    // TODO Create an event to emit when a solution is added
    event SolutionAdded(address to, uint256 tokenId);

    // TODO Create a function to add the solutions to the array and emit the event
    function addSolution(
        address to,
        uint256 tokenId
    )
        public
    {
        Solution memory _soln = Solution({ tokenId : tokenId, to : to, used: false });
        solutions.push(_soln);
        uniqueSolutions[tokenId] = _soln;
        emit SolutionAdded(to, tokenId);
    }

    // TODO Create a function to mint new NFT only after the solution has been verified
    //  - make sure the solution is unique (has not been used before)
    //  - make sure you handle metadata as well as tokenSuplly
    function mintToken(
        address to,
        uint256 tokenId,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input
    )
        public
        whenNotPaused
    {
        require(verifyTx(a, b, c, input), "Solution is incorrect");
        require(!uniqueSolutions[tokenId].used, "Solution is already used");
        super.mint(to, tokenId);
        uniqueSolutions[tokenId].used = true;
    }
}
