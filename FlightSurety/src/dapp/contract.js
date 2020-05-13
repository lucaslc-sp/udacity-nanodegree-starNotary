import FlightSuretyApp from "../../build/contracts/FlightSuretyApp.json";
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json'
import Config from "./config.json";
import Web3 from "web3";

export default class Contract {
  constructor(network, callback) {
    let config = Config[network];

    this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));

    this.flightSuretyApp = new this.web3.eth.Contract(
      FlightSuretyApp.abi,
      config.appAddress
    );

    this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.appAddress)

    this.initialize(callback);

    this.owner = null;
    this.airlines = [];
  }

  initialize(callback) {
    this.web3.eth.getAccounts((error, accts) => {
      this.owner = accts[1];
      callback();
    });
  }

  isOperational(callback) {
    let self = this;
    self.flightSuretyApp.methods
      .isOperational()
      .call({ from: self.owner }, callback);
  }

  fetchFlightStatus(flightCode, destination, callback) {
    let self = this;
    const timestamp = Math.floor(Date.now() / 1000);

    self.flightSuretyApp.methods
      .fetchFlightStatus(flightCode, destination, timestamp)
      .send({ from: self.owner }, (error, result) => {
        callback(error, result);
      });
  }

  async registerAirline(airline, callback) {
    let self = this;
    await self.flightSuretyApp.methods
      .registerAirline(airline)
      .send({ from: self.owner }, callback);
  }

  async fundAirline(amount, callback) {
    let self = this;
    const price = this.web3.utils.toWei(amount.toString(), "ether");

    await self.flightSuretyApp.methods
      .fund()
      .send({ from: self.owner, value: price }, callback);
  }

  async registerFlight(flightCode, price, departure, destination, callback) {
    let self = this;
    let timestamp = Math.floor(Date.now() / 1000);
    let value = this.web3.utils.toWei(price.toString(), "ether");
    try {
      await self.flightSuretyApp.methods.registerFlight(
        flightCode,
        timestamp,
        value,
        departure,
        destination
      ).send({ from: self.owner }, callback);
    } catch (ex) {
      console.log(ex)
    }
  }

  async book(flightCode, destination, price, callback) {
    let self = this;
    const timestamp = Math.floor(Date.now() / 1000);
    const value = this.web3.utils.toWei(price.toString(), "ether");
    
    await self.flightSuretyApp.methods.book(
      flightCode,
      destination,
      timestamp
    ).send({
        from: self.owner,
        value: this.web3.utils.toWei(price.toString(), 'ether')
    });
  }

  withdraw(callback) {
    self.flightSuretyApp.methods
      .withdraw()
      .send({ from: self.owner }, callback);
  }
}