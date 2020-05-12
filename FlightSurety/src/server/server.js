import express from "express";
import bodyParser from "body-parser";
import cors from "cors";

import { Controller } from "./app/base_controller";
import { oracleController } from "./app/oracle_controller";

const app = express();
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

const corsOptions = {
  origin: "*",
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));

app.get("/", (req, res) => {
  res.send({
    message: "An API for use with your Dapp!"
  });
});

app.get("/flights", async (req, res) => {
  const flights = await Controller.getFlights().flights;
  res.send(flights);
});

(() => {
  Controller.init();
  oracleController.init();
})();

export default app;