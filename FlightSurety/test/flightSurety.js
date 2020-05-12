
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {
  const minimumFund = web3.utils.toWei("10", "ether");
  const departure = "ABC";
  const destination = "DEF";
  const flightCode = "AA123";
  const timestamp = (Date.now() / 1000) | 0;
  const price = web3.utils.toWei("0.3", "ether");
  const insurancePrice = web3.utils.toWei("1", "ether");
  const passenger = accounts[8];

  const airline2 = accounts[2];
  const airline3 = accounts[3];
  const airline4 = accounts[4];
  const airline5 = accounts[5];

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(Multiparty) Has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(Multiparty) Can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(Multiparty) Can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(Multiparty) Can block access to functions using requireIsOperational when operating status is false`, async function () {

      let reverted = false;
      try 
      {
          await config.flightSurety.authorizeCaller({ from: config.testAddresses[0] });
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(Multiparty) Cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[0];

    // ACT
    try {
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
    }
    catch(e) {}
    
    let result = await config.flightSuretyData.isAirlineRegistered.call(newAirline);
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it('(Airline) First account is firstAirline', async () => {
    assert.equal(config.firstAirline, accounts[1])
  })

  it("(Airline) cannot register another one before providing funding", async () => {
    try {
      await config.flightSuretyApp.registerAirline(airline2, { from: config.firstAirline });
    } catch (error) {}

    const isAirlineRegistered = await config.flightSuretyData.isAirlineRegistered(airline2);

    assert.equal(isAirlineRegistered, false,
      "Airline should not be able to register another airline without providing fund"
    );
  });

  it("(Airline) can provide funding", async () => {
    try {
      await config.flightSuretyApp.fund({
        from: config.firstAirline,
        value: minimumFund
      });
    } catch (error) {
      console.log(error.toString());
    }

    const isAirlineFunded = await config.flightSuretyData.isAirlineFunded.call(
      config.firstAirline
    );

    assert.equal(isAirlineFunded, true, "Airline hasn't provided funding");
  });

  it("(Airline) Only first airline can register an airline when less than 4 airlines are registered", async () => {
    let eventEmitted = false
    
    try {
      await config.flightSuretyApp.registerAirline(airline2, { from: config.firstAirline });
      await config.flightSuretyApp.registerAirline(airline3, { from: config.firstAirline });
      await config.flightSuretyApp.registerAirline(airline4, { from: config.firstAirline });
    } catch (error) {}

    const isAirline2Registered = await config.flightSuretyData.isAirlineRegistered.call(airline2);
    const isAirline3Registered = await config.flightSuretyData.isAirlineRegistered.call(airline3);
    const isAirline4Registered = await config.flightSuretyData.isAirlineRegistered.call(airline4);

    await config.flightSuretyData.FlightRegistered(function(error, event){
      eventEmitted = true 
    });

    const count = await config.flightSuretyData.getRegisteredAirlinesCount();
    
    assert.equal(isAirline2Registered, true, "Second airline should able to be registered");
    assert.equal(isAirline3Registered, true, "Third airline should able to be registered");
    assert.equal(isAirline4Registered, true, "Fourth airline should able to be registered");
    assert.equal(count, 4);
    assert.equal(eventEmitted, true, 'Invalid event emitted');
  });

  it("(Airline) Registration of fifth airline cannot be registered without multiparty consensus", async () => {
    await config.flightSuretyApp.registerAirline(airline5, {
      from: config.firstAirline
    });

    let isAirline5Registered = await config.flightSuretyData.isAirlineRegistered(airline5);

    assert.equal(isAirline5Registered, false, "Fifth airline should not registered without minimum votes");
  });

  it("(Airline) Registration of fifth airline cannot be duplicated", async () => {
    let reverted = true;
    try {
      await config.flightSuretyApp.registerAirline(airline5, {
        from: config.firstAirline
      });
    } catch (error) {
      reverted = false;
    }

    assert.equal(reverted, false, "Airline should not be registered twice");
  });

  it('(Airline) Can register a flight', async () => {
    let eventEmitted = false
    
    try {
      await config.flightSuretyApp.registerFlight(
        flightCode,
        timestamp,
        price,
        departure,
        destination,
        { from: config.firstAirline })
      } catch (e) {}
    
    await config.flightSuretyData.FlightRegistered(function(error, event){
      eventEmitted = true 
    });

    const flightKey = await config.flightSuretyApp.getFlightKey(
      flightCode,
      destination,
      timestamp
    );

    const isFlightRegistered = await config.flightSuretyData.isFlightRegistered.call(
      flightKey
    );

    assert.equal(isFlightRegistered, true, "Flight not registered");
    assert.equal(eventEmitted, true, 'Invalid event emitted');
  });

  it('(Passenger) Can book a flight', async () => {
    await config.flightSuretyApp.book(
      flightCode,
      destination,
      timestamp,
      {
        from: passenger,
        value: insurancePrice
      }
    )
    const flightKey = await config.flightSuretyApp.getFlightKey(
      flightCode,
      destination,
      timestamp
    );

    const amount = await config.flightSuretyData.getPassengerPaidAmount.call(
      flightKey,
      passenger
    );

    assert.equal(
      amount,
      insurancePrice,
      "Passenger should be able to buy insurance correctly"
    );
  });

  it('(Passenger) Withdraw their credited amount', async () => {
    const balanceBefore = await web3.eth.getBalance(config.firstAirline);
    let eventEmitted = false
      
    try {
      await config.flightSuretyApp.withdraw({ from: config.firstAirline });
    } catch (error) {}

    const balanceAfter = await web3.eth.getBalance(config.firstAirline);

    await config.flightSuretyApp.WithdrawRequest(function(error, event){
      eventEmitted = true 
    });

    assert(+balanceBefore < +balanceAfter, "Airline withdrawal failed");
    assert.equal(eventEmitted, true, 'Invalid event emitted');
  })

});
