const elmExpress = require("../src-js/elm-express");

const { Elm } = require("./build/main");

const port = 3000;
const app = Elm.Main.init();
const secret = "p4ssw0rd";

const sessionConfig = {
  resave: false,
  saveUninitialized: true,
};

const server = elmExpress({ app, secret, port, sessionConfig });

app.ports.requestReverse.subscribe((data) => {
  app.ports.gotReverse.send({
    id: data.requestId,
    reversed: data.text.split("").reverse().join(""),
  });
});

server.start(() => {
  console.log(`Example app listening on port ${port}`);
});

