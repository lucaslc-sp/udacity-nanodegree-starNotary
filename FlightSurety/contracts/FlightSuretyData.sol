pragma solidity ^0.5.16;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Struct used to hold registered airlines
    struct Airline {
        bool isRegistered;
        bool isFunded;
    }

    struct Flight {
        bool isRegistered;
        uint timestamp;
        uint8 status;
        address airline;
        string code;
        uint price;
        string from;
        string to;
        mapping(address => uint) insurances;
    }

    // Account used to deploy contract
    address private contractOwner;

    // Blocks all state changes throughout the contract if false
    bool private operational = true;

    // Counts to know registered airlines and flights
    uint256 public registeredAirlinesCount;
    uint256 public registeredFlightsCount;

    // lists
    address[] internal passengers;
    bytes32[] public flightKeys;
    mapping(address => uint256) private authorizedCallers;
    mapping(address => Airline) public registeredAirlines;
    mapping(bytes32 => Flight) public flights;
    mapping(address => uint) public withdrawals;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event Paid(address recipient, uint amount);
    event Funded(address airline);
    event AirlineRegistered(address origin, address newAirline);
    event FlightRegistered(bytes32 flightKey);
    event FlightStatusUpdated(bytes32 flightKey, uint8 status);
    event Credited(address passenger, uint amount);

    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner.
    *      Register first airline at deployment.
    */
    constructor(address _firstAirline) public {
        contractOwner = msg.sender;

        registeredAirlines[_firstAirline] = Airline({
            isRegistered: true,
            isFunded: false
        });

        registeredAirlinesCount = 1;
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
        require(operational, "Contract is currently not operational");
        _;
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /**
    * @dev Modifier that restrict function calls to previously authorized addresses
    */
    modifier requireIsCallerAuthorized() {
        require(authorizedCallers[msg.sender] == true, "Caller is not authorized");
        _;
    }

    /**
    * @dev Modifier to avoid spending gas trying to put the contract in a state it already is in
    */
    modifier requireIsNotCurrentState(bool status) {
        require(status != operational, "Contract already in the state requested");
        _;
    }

    /**
    * Modifier to check if is a airline registered
    */
    modifier requireIsAirlineNotRegistered(address _airline) {
        require(!registeredAirlines[_airline].isRegistered, "Airline is registered");
        _;
    }

    /**
    * @dev Modifier to check if flight is registered
    */
    modifier requireIsFlightRegistered(bytes32 _flightKey) {
        require(flights[_flightKey].isRegistered, "This flight isn't exist");
        _;
    }

    /**
    * @dev Modifier to avoid the passengers being credited their insurance amount twice
    */
    modifier requireIsFlightProcessed(bytes32 _flightKey) {
        require(flights[_flightKey].status == 0, "Flight already processed");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */
    function isOperational() public view returns(bool)
    {
        return operational;
    }

    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */
    function setOperatingStatus (bool mode) external requireContractOwner requireIsNotCurrentState(mode)
    {
        operational = mode;
    }

    /**
    * @dev Function to authorize addresses to call functions from Fligh Surety Data contract
    */
    function authorizeCaller(address _contractAddress) external requireContractOwner{
        authorizedCallers[_contractAddress] = true;
    }

    /**
    * @dev Function to remove authorization addresses to call functions from Fligh Surety Data contract
    */
    function deauthorizeCaller(address _contractAddress) external requireContractOwner{
        delete authorizedContracts[_contractAddress];
    }

    /**
    * @dev Function to return fund of one airline
    */
    function isAirlineFunded(address _airlineAddress) external view returns (bool _hasFunded)
    {
        _hasFunded = registeredAirlines[_airlineAddress].funded;
    }

    /**
    * @dev Function to return airline register status
    */
    function isAirlineRegistered(address _airline) external view returns(bool) {
        return registeredAirlines[_airline].isRegistered;
    }

    /**
    * @dev Function flight key from code and destination
    */
    function getFlightKey(string _flightCode, string _destination, uint _timestamp) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_flightCode, _destination, _timestamp));
    }

    /**
    * @dev Function to return a price of one flight
    */
    function getFlightPrice(bytes32 _flightKey) external view returns(uint) {
        return flights[_flightKey].price;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */
    function registerAirline (address _airline, address _sender) external
    requireIsOperational
    requireIsCallerAuthorized
    requireIsAirlineNotRegistered(_airline)
    {
        registeredAirlines[_airline] = Airline({
            isRegistered: true,
            isFunded: false
        });

        registeredAirlinesCount += 1;

        emit AirlineRegistered(_sender, _airline);
    }

    /**
    * @dev Generate a flightkey and add a flight in the flight list
    */
    function registerFlight(
    string _flightCode,
    uint _timestamp,
    uint _price,
    string _departure,
    string _destination,
    address _airline
  ) external
    requireIsOperational
    requireIsCallerAuthorized {

      bytes32 flightKey = keccak256(abi.encodePacked(_flightCode, _destination, _timestamp));

      flights[flightKey] = Flight({
        isRegistered: true,
        timestamp: _timestamp,
        status: 0,
        airline: _airline,
        code: _flightCode,
        price: _price,
        departure: _departure,
        destination: _destination
      });

      flightKeys.push(flightKey);

      emit FlightRegistered(flightKey);
  }

   /**
    * @dev Passanger can Buy insurance (book) for a flight
    *
    */
    function book(bytes32 _flightCode, uint _amount, address _passenger) external payable
    requireIsOperational
    requireIsCallerAuthorized
    requireIsFlightRegistered(_flightCode)
    {
        flights[_flightCode].insurances[_passenger] = _amount;
        withdrawals[flights[_flightCode].airline] = flights[_flightCode].price;

        passengers.push(_passenger);
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(bytes32 _flightCode) internal
    requireIsOperational
    requireIsFlightRegistered(_flightCode)
    {
        Flight storage flight = flights[_flightCode];

        for (uint i = 0; i < passengers.length; i++) {
            withdrawals[passengers[i]] = flight.insurances[passengers[i]];
            emit Credited(passengers[i], flight.insurances[passengers[i]]);
        }
    }

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address _originAddress) external
    requireIsOperational
    requireIsCallerAuthorized
    {
        require(withdrawals[_originAddress] > 0, "No amount available for withdrawal");

        uint amount = withdrawals[_originAddress];
        withdrawals[_originAddress] = 0;
        _originAddress.transfer(amount);
        emit Paid(_originAddress, amount);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */
    function fund(address _airline) external payable
    requireIsOperational
    requireIsCallerAuthorized
    {
        registeredAirlines[_airline].isFunded = true;
        emit Funded(_airline);
    }

    function processFlightStatus(bytes32 _flightKey, uint8 _status) external
    requireIsOperational
    requireIsCallerAuthorized
    requireIsFlightRegistered(_flightKey)
    requireIsFlightProcessed(_flightKey) {
        flights[_flightKey].status = _status;

        if (_status == 20) {
        creditInsurees(_flightKey);
        }

        emit FlightStatusUpdated(_flightKey, _status);
    }


    function() external payable requireIsCallerAuthorized {
        require(msg.data.length == 0, "");
        fund(msg.sender);
    }
}

