
var Test = require('../config/testConfig.js');

contract('Oracles', async (accounts) => {
    let config;
    const TEST_ORACLES_COUNT = 10;
    const STATUS_CODE_ON_TIME = 10;
    const departure = "ABC";
    const destination = "DEF";
    const flightCode = "AA123";
    const timestamp = (Date.now() / 1000) | 0;
    const price = web3.utils.toWei("0.3", "ether");
    const insurancePrice = web3.utils.toWei("1", "ether");
    const passenger = accounts[8];

    before('setup contract', async () => {
    config = await Test.Config(accounts);

    await config.flightSuretyData.authorizeCaller(
        config.flightSuretyApp.address
    );

    await config.flightSuretyApp.fund({ from: config.firstAirline, value: web3.utils.toWei('10', 'ether') });

    await config.flightSuretyApp.registerFlight(
        flightCode,
        timestamp,
        price,
        departure,
        destination,
        { from: config.firstAirline });

    await config.flightSuretyApp.book(
        flightCode,
        destination,
        timestamp,
        { from: passenger, value: insurancePrice });

    });


    it('can register oracles', async () => {
        let fee = await config.flightSuretyApp.REGISTRATION_FEE.call();
        let eventEmitted = false

        for (let a = 1; a < TEST_ORACLES_COUNT; a++) {
            try {
                await config.flightSuretyApp.registerOracle({
                from: accounts[a],
                value: fee
                });
                
                await config.flightSuretyApp.OracleRegistered(function(error, event){
                    eventEmitted = true 
                });
            } catch (error) {
                console.log(error.toString());
            }

            const result = await config.flightSuretyApp.getMyIndexes.call({
                from: accounts[a]
            });

            console.log(`Oracle Registered: ${result[0]}, ${result[1]}, ${result[2]}`);
        }
        assert.equal(eventEmitted, true, 'Invalid event emitted');
    });

  it('can request flight status', async () => {
    let eventEmitted = false
    const tx = await config.flightSuretyApp.fetchFlightStatus(
                flightCode,
                destination,
                timestamp);
    
    await config.flightSuretyApp.OracleRegistered(function(error, event){
        eventEmitted = true 
    });
    assert.equal(eventEmitted, true, 'Invalid event emitted');
    
    // Since the Index assigned to each test account is opaque by design
    // loop through all the accounts and for each account, all its Indexes (indices?)
    // and submit a response. The contract will reject a submission if it was
    // not requested so while sub-optimal, it's a good test of that feature
    for(let a=1; a<TEST_ORACLES_COUNT; a++) {
        let eventReportEmitted = false
        let eventFlightStatusEmitted = false

        // Get oracle information
        let oracleIndexes = await config.flightSuretyApp.getMyIndexes.call({ from: accounts[a]});
        for(let idx=0;idx<3;idx++) {

            try {
                // Submit a response...it will only be accepted if there is an Index match
                await config.flightSuretyApp.submitOracleResponse(
                    oracleIndexes[idx],
                    flightCode,
                    destination,
                    timestamp,
                    STATUS_CODE_ON_TIME,
                    { from: accounts[a]
                });
                
                await config.flightSuretyApp.OracleReport(function(error, event){
                    eventReportEmitted = true 
                });

                await config.flightSuretyApp.FlightStatusInfo(function(error, event){
                    eventFlightStatusEmitted = true 
                });
                assert.equal(eventReportEmitted, true, 'Invalid event (OracleReport) emitted')
                assert.equal(eventFlightStatusEmitted, true, 'Invalid event (FlightStatusInfo) emitted')
            }
            catch(e) {
            // Enable this when debugging
            console.log('\nError', idx, oracleIndexes[idx].toNumber(), flightCode, timestamp);
            console.log(e);
            }

        }
    }
  });
});
