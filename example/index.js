const elmExpress = require("../src-js/elm-express");

const { Elm } = require("./build/main");

const port = 3000;
const app = Elm.Main.init();
const secret = "p4ssw0rd";

const sessionConfig = {
  resave: false,
  saveUninitialized: true,
};

const reqCallback = (req) => {
  console.log(`[${req.method}] ${new Date().toString()} - ${req.originalUrl}`);
}

const server = elmExpress({ app, secret, port, sessionConfig, reqCallback });

app.ports.requestReverse.subscribe((data) => {
  app.ports.gotReverse.send({
    requestId: data.requestId,
    reversed: data.text.split("").reverse().join(""),
  });
});

server.start(() => {
  console.log(`Example app listening on port ${port}`);
});

