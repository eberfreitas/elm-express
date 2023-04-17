# elm-express

`elm-express` is a simple library to enable the usage of Elm in the backend through Express.js. It tries to do as little
as possible to empower the developer to use both Elm and Express.js in the way that makes the most sense for each
project.

Because this library aims to integrate a Node.js library with Elm, it has two parts:

- The Elm library and;
- The JavaScript bridge.

To better understand how to use the Elm library, please refer to its documentation [here](http://example.com).

You can find the documentation for the JavaScript bridge in this README file.

## Creating an `elm-express` application

So you want to write Elm in the backend. You have already created your application using the `elm-express` Elm library
and now you need to wire the JavaScript side. Here is what you need to do:

### Install the bridge

Run the following command in you application root:

```bash
npm install elm-express
```

### Create your entry point

Now you can create a file called `index.js` or `server.js` or whatever you fill like is the best name for your
entry point:

```js
const elmExpress = require("elm-express");
const { Elm } = require("./main");

const port = 3000;
const secret = "p4ssw0rd";
const app = Elm.Main.init();

const sessionConfig = {
  resave: false,
  saveUninitialized: true,
};

const server = elmExpress({ app, secret, port, sessionConfig, requestCallback });

server.start(() => {
  console.log(`Example app listening on port ${port}`);
});
```

This is the smallest possible `elm-express` application. You will probably have to wire some ports if you wanna make
things interesting. The way to call ports is exactly the same as you would with any normal Elm application and you can
do that directly using the `app` constant.

Also, this example assumes that you have compiled your Elm application into a `main.js` file. `elm-express` does not
have any opinions on how you should build or bundle your application, so feel free to use whatever processes you fill
the most comfortable with.

In the same way that you can define ports an manipulate your Elm `app` freely, the `elm-express` bridge just exposes a
regular Express.js application. You can use the `server` const as any regular Express.js application. That means that
you can define routes outside your Elm application, apply middleware and whatnot.

Notice that calling `server.start()` is akin as calling `server.listen()` if this was a pure Express.js. The `start()`
method will call `listen()` automatically while setting up all that is needed for our Elm application to properly
catch requests and send responses.

### Parameters

This is a table of the params you can pass to `elmExpress` in order to create your application:

| Parameter | Required? | Default | Description |
| --- | --- | --- | --- |
| `app` | ✔️ | - | Should be a reference to your initialized Elm application |
| `secret` | ✔️ | - | A random string to be used by the cookie parser an session management libraries |
| `sessionConfig` | ✔️ | - | An object with the necessary keys for session config. Check [Express.js docs](http://expressjs.com/en/resources/middleware/session.html) to better understand what is possible to inform here. **Note:** whatever `secret` you pass in this config, it will be overwritten by the top-level `secret` to keep consistency. |
| `requestCallback` | ❌ | - | This is a callback function that will be called at every request. Check the `/example` folder to see it in action. |
| `errorCallback` | ❌ | `console.error` | If there is any internal error, `elm-express` will call this with a `string` describing the issue. If this callback is not informed, we just call `console.error` with the message. |
| `timeout` | ❌ | `5000` | If by any reason a request takes more than the `timeout` time (in milliseconds) than we kill that request. |
| `port` | ❌ | `3000` | Port to bind the server. |
| `moutingRoute` | ❌ | `/` | Tells Express.js where to mount our Elm application. |

## How it works?

When we call `server.start()`, `elm-express` will setup a route `server.all()` using the `moutingRoute`. For a
`moutingRoute` of `/`, the call will be like `server.all("/*")`. That means that any sub-path will be caught by
`elm-express` and sent to your Elm application to be handled. `elm-express` does not have a router in place. You can
use pattern matching to properly build your model using the request's URL as well as other information (like the
request's method), just like you could do if you were building a client-side SPA.