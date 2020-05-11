pragma solidity ^0.5.16;

interface IFlightSuretyData {

    /* ============================================================================================== */
    /*                                        ABSTRACT FUNCTIONS                                      */
    /* ============================================================================================== */

    // :: PUBLIC UTILITY FUNCTIONS
    function isOperational() external view returns(bool);
    function isAirlineFunded(address airline) external view returns (bool);
    function isAirlineRegistered(address airline) external view returns (bool);
    function setOperatingStatus (bool mode) external;
    function authorizeCaller(address _contractAddress) external;
    function deauthorizeCaller(address _contractAddress) external;
    function getFlightPrice(bytes32 _flightKey) external view returns(uint);
    function getRegisteredAirlinesCount() external view returns(uint);

    // :: SMART CONTRACT FUNCTIONS
    function registerAirline (address _airline, address _sender) external;
    function book(bytes32 _flightCode, uint _amount, address _passenger) external payable;
    function pay(address _originAddress) external;
    function fund(address _airline) external payable;
    function processFlightStatus(bytes32 _flightKey, uint8 _status) external;
    function registerFlight(
    string _flightCode,
    uint _timestamp,
    uint _price,
    string _departure,
    string _destination,
    address _airline
  ) external;

}