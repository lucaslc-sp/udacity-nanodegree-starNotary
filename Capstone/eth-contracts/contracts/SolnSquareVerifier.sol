pragma solidity >=0.4.21 <0.6.0;

// TODO define a contract call to the zokrates generated solidity contract <Verifier> or <renamedVerifier>
import { CustomERC721Token } from "./ERC721Mintable.sol";
import { Verifier } from "./Verifier.sol";

// TODO define another contract named SolnSquareVerifier that inherits from your ERC721Mintable class
contract SolnSquareVerifier is Verifier, CustomERC721Token {

    // TODO define a solutions struct that can hold an index & an address
    struct Solution {
        address addr;
        uint256 tokenId;
    }

    // TODO define an array of the above struct
    Solution[] solutions;

    // TODO define a mapping to store unique solutions submitted
    mapping(bytes32 => Solution) uniqueSolutions;

    // TODO Create an event to emit when a solution is added
    event SolutionAdded(address addr, uint256 tokenId);
    event TokenMint(address addr, uint256 tokenId);

    // TODO Create a function to add the solutions to the array and emit the event
    function addSolution(
        address addr,
        uint256 tokenId,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input
    )
        public
    {
        bytes32 solution_key = keccak256(abi.encodePacked(a, b, c, input));
        // Verify solution check
        require(verifyTx(a, b, c, input), "Solution is invalid");
        // Unique solution check
        require(uniqueSolutions[solution_key].addr == address(0), "Solution need to be unique");
        // Add solution to array and mapping
        Solution memory _solution = Solution({ tokenId : tokenId, addr : addr });
        uniqueSolutions[solution_key] = _solution;
        emit SolutionAdded(addr, tokenId);
    }

    // TODO Create a function to mint new NFT only after the solution has been verified
    //  - make sure the solution is unique (has not been used before)
    //  - make sure you handle metadata as well as tokenSuplly
    function mintToken(
        address addr,
        uint256 tokenId,
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[2] memory input
    )
        public
    {
        // AddSolution there are verify solution check and unique solution check
        addSolution(addr, tokenId, a, b, c, input);
        // handle metadata as well as tokenSuplly
        super.mint(addr, tokenId);
        emit TokenMint(addr, tokenId);
    }
}
