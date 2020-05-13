pragma solidity ^0.4.25;

interface IFlightSuretyData {

    /* ============================================================================================== */
    /*                                        ABSTRACT FUNCTIONS                                      */
    /* ============================================================================================== */

    // :: PUBLIC UTILITY FUNCTIONS
    function isOperational() external view returns(bool);
    function isAirlineFunded(address _airline) external view returns (bool);
    function isAirlineRegistered(address _airline) external view returns (bool);
    function setOperatingStatus (bool _mode) external;
    function authorizeCaller(address callerAddress) external;
    function getFlightPrice(bytes32 _flightKey) external view returns(uint);
    function getRegisteredAirlinesCount() external view returns(uint);
    function getRegisteredFlightsCount() external view returns(uint);
    function isFlightRegistered(bytes32 _flightKey) external view returns(bool);
    function getPassengerPaidAmount(bytes32 _flightKey, address _passenger) external view returns(uint);

    // :: SMART CONTRACT FUNCTIONS
    function registerAirline (address _airline, address _sender) external;
    function book(bytes32 _flightCode, uint _amount, address _passenger) external payable;
    function pay(address _originAddress) external;
    function fund(address _airline) external payable;
    function processFlightStatus(bytes32 _flightKey, uint8 _status) external;
    function registerFlight(string _flightCode, uint _timestamp, uint _price, string _departure, string _destination, address _airline) external;

}