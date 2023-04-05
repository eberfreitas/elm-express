const elmExpress = require("../src-js/elm-express");

const { Elm } = require("./build/main");

const port = 3000;
const app = Elm.Main.init();
const secret = "p4ssw0rd";
const server = elmExpress({ app, secret, port });

app.ports.requestReverse.subscribe((data) => {
  const reversed = data.text.split("").reverse().join("");
  app.ports.gotReverse.send({ id: data.requestId, reversed });
});

server.start(() => {
  console.log(`Example app listening on port ${port}`);
});

