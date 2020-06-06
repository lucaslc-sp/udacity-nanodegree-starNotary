pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./interfaces/IFlightSuretyData.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */

contract FlightSuretyApp {
    // :: Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // :: minimum funding amount
    uint public MIN_FUND = 10 ether;
    uint256 private constant MAXINSURANCEPAYMENT = 1 ether;

    // :: Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    // :: Account used to deploy contract
    address private contractOwner;

    // :: Multi-party consensus - part of app logic
    mapping(address => address[]) public airlineVotes;

    // :: Interface for data contract
    IFlightSuretyData public flightSuretyData;

    // :: Events for Smart Contracts functions
    event WithdrawRequest(address recipient);

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address _dataContract) public
    {
        contractOwner = msg.sender;
        flightSuretyData = IFlightSuretyData(_dataContract);
    }

     /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
         // Modify to call data contract's status
        require(flightSuretyData.isOperational(), "Contract is currently not operational");  
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires enough fund
    */
    modifier requireHaveEnoughFund()
    {
        require(msg.value >= MIN_FUND, "Minimun funding amount is 10 ETH");
        _;
    }

    /**
    * @dev Modifier that requires payment between range
    */
    modifier requireIsPaidEnough() {
        require(msg.value >= MAXINSURANCEPAYMENT, "Sent value must cover the price");
        _;
    }
    /**
    * @dev Modifier that check transfer amount
    */
    modifier requireCheckValue() {
        uint amountToReturn = msg.value - MAXINSURANCEPAYMENT;
        msg.sender.transfer(amountToReturn);
        _;
    }

    /**
    * @dev Modifier that requires that flight is registered
    */
    modifier requireIsAirlineRegistered() {
        require(flightSuretyData.isAirlineRegistered(msg.sender),"Airline must be registered");
        _;
    }

    /**
    * @dev Modifier that requires that airfline is funded
    */
    modifier requireIsAirlineFunded() {
        require(flightSuretyData.isAirlineFunded(msg.sender),"Airline must provide funding");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool) 
    {
        return flightSuretyData.isOperational();
    }

    /**
    * @dev Function flight key from code and destination
    */
    function getFlightKey(string _flightCode, string _destination, uint _timestamp) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_flightCode, _destination, _timestamp));
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline (address _airline) external
    requireIsOperational
    requireIsAirlineFunded
    {
        // :: Number 4 is referent Multiparty Consensus
        if (flightSuretyData.getRegisteredAirlinesCount() < 4) {
            flightSuretyData.registerAirline(_airline, msg.sender);
        } else {
            // :: Multi party consensus
            bool isDuplicate = false;
            for (uint i = 0; i < airlineVotes[_airline].length; i += 1) {
                if (airlineVotes[_airline][i] == msg.sender) {
                    isDuplicate = true;
                    break;
                }
            }
            
            // :: Is not duplicate ? Add in airfline votes
            require(!isDuplicate, "Voting already submitted for this airline");
            airlineVotes[_airline].push(msg.sender);

            uint registeredVotes = airlineVotes[_airline].length;
            uint multipartyConsensysDivider = flightSuretyData.getRegisteredAirlinesCount().div(2);

            if (multipartyConsensysDivider.sub(registeredVotes) == 0) {
                airlineVotes[_airline] = new address[](0);
                flightSuretyData.registerAirline(_airline, msg.sender);
            }
        }
    }


   /**
    * @dev Funding for the insurance
    *
    */  
    function fund() external payable
    requireIsAirlineRegistered
    requireHaveEnoughFund
    requireIsOperational
    {
        flightSuretyData.fund.value(msg.value)(msg.sender);
    }

    /**
    * @dev Method for register a flight
    */
    function registerFlight(
        string _flightCode,
        uint _timestamp,
        uint _price,
        string _departure,
        string _destination
    ) external
    requireIsOperational
    requireIsAirlineFunded {
        flightSuretyData.registerFlight(_flightCode, _timestamp, _price, _departure, _destination, msg.sender);
    }

    /**
    * @dev Passanger can book for a flight
    */
    function book(string _flightCode, string _destination, uint _timestamp) public payable
    requireIsOperational
    requireIsPaidEnough
    requireCheckValue {
        bytes32 flightKey = getFlightKey(_flightCode, _destination, _timestamp);
        flightSuretyData.book(flightKey, msg.value, msg.sender);
    }

    /**
    * @dev Method for passanger withdraw and pay
    */
    function withdraw() external requireIsOperational {
        flightSuretyData.pay(msg.sender);
        emit WithdrawRequest(msg.sender);
    }

    /**
    * @dev Generate request for oracles to fetch flight information
    */
    function fetchFlightStatus(string _flightCode, string _destination, uint _timestamp) external {
    uint8 index = getRandomIndex(msg.sender);

    // Generate a unique key for storing the request
    bytes32 key = getFlightKey(_flightCode, _destination, _timestamp);
    oracleResponses[key] = ResponseInfo({
        requester: msg.sender,
        isOpen: true
    });

    emit OracleRequest(index, _flightCode, _destination, _timestamp);
    }

    /********************************************************************************************/
    /*                                     ORACLE MANAGEMENT                             */
    /********************************************************************************************/

    // :: Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // :: Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // :: Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(string flightCode, string destination, uint timestamp, uint8 statusCode);

    event OracleRegistered(uint8[3] indexes);

    event OracleReport(string flightCode, string destination, uint timestamp, uint8 statusCode);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, string flightCode, string destination, uint timestamp);


    // Register an oracle with the contract
    function registerOracle() external payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
                                    
        emit OracleRegistered(indexes);
    }

    function getMyIndexes() external view returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 _index,
                            string _flightCode,
                            string _destination,
                            uint256 _timestamp,
                            uint8 _statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == _index) ||
                (oracles[msg.sender].indexes[1] == _index) ||
                (oracles[msg.sender].indexes[2] == _index),
                "Index does not match oracle request");


        bytes32 key = getFlightKey(_flightCode, _destination, _timestamp);
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[_statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(_flightCode, _destination, _timestamp, _statusCode);
        if (oracleResponses[key].responses[_statusCode].length == MIN_RESPONSES) {

            emit FlightStatusInfo(_flightCode, _destination, _timestamp, _statusCode);

            // Handle flight status as appropriate
            flightSuretyData.processFlightStatus(key, _statusCode);
        }
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address _account) internal returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(_account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(_account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(_account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address _account) internal returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), _account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}   
