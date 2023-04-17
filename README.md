![elm-express](https://raw.githubusercontent.com/eberfreitas/elm-express/main/elm-express.png)
# elm-express

`elm-express` is a library that enables the use of Elm in the backend with Express.js. It is designed to provide minimal
functionality and allow developers to use Elm and Express.js in a way that makes the most sense for their project.

The library consists of two parts: the Elm library and a JavaScript bridge. For instructions on using the
**Elm library**, please refer to the documentation
[here](https://package.elm-lang.org/packages/eberfreitas/elm-express/latest/Express).

This README file contains documentation for the JavaScript bridge.

## Creating an `elm-express` application

If you want to write Elm in the backend and have already created your application using the `elm-express` Elm library,
you'll need to wire up the JavaScript side. Here's how to install the bridge:

### Installing the bridge

To install the `elm-express` JavaScript bridge, run the following command in your application's root directory:

```bash
npm install elm-express
```

### Create your entry point

Next, create your entry point (`index.js` or `server.js`) by requiring the `elm-express` package and initializing your
Elm application using `Elm.Main.init()`:

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

In this example, `elm-express` is initialized with an `app` instance, a `secret` key for signed cookies and session, a
port number, a session configuration object, and a `requestCallback` function. You can define your `requestCallback`
function to modify incoming requests before they are handled by your Elm application.

Note that the `app` instance is just a regular Elm application, so you can call ports and manipulate it as you would
with any normal Elm application.

Also, `elm-express` does not have any opinions on how you should build or bundle your Elm application, so you can use
any process you feel comfortable with to compile your Elm code.

### Use your server instance

Finally, you can use your `server` instance as you would with any regular Express.js application. You can define routes,
apply middleware, and more.

When you're ready to start listening for requests, call `server.start()`, which will automatically set up everything
needed for your Elm application to properly handle requests and send responses.

### Parameters

Here is a list of parameters that you can pass to the elmExpress function to create your application:

- `app`: A reference to your initialized Elm application.
- `secret`: A random string to be used by the cookie parser and session management libraries.
- `sessionConfig`: An object with the necessary keys for session configuration. Check the
  [Express.js documentation](http://expressjs.com/en/resources/middleware/session.html) for more information on what
  can be configured here. Note that whatever `secret` you pass in this configuration object will be overwritten by the
  top-level `secret` to ensure consistency.
- `requestCallback`: A callback function that will be called for every request. Check the
  [`/example`](https://github.com/eberfreitas/elm-express/tree/main/example) folder for an example of how to use this
  callback.
- `errorCallback`: A function that will be called with a string describing any internal errors. If not provided, the
  `console.error` function will be used to log the error message.
- `timeout`: The maximum time (in milliseconds) a request can take before it is terminated. The default value is `5000`.
- `port`: The port to which the server should bind. The default value is `3000`.
- `mountingRoute`: The route at which the Elm application should be mounted. The default value is `/`.

## How it works?

When `server.start()` is called in `elm-express`, a route is set up using `server.all()` and the specified
`mountingRoute`. If the `mountingRoute` is `/`, the call will be `server.all("/*")`. This means that any sub-path will
be caught by `elm-express` and passed to your Elm application for handling. There is no built-in router in
`elm-express`, but you can use pattern matching to construct your model using information from the request, such as the
URL and method, similar to how you would build a client-side SPA.

## Example

The [`/example`](https://github.com/eberfreitas/elm-express/tree/main/example) folder in the `elm-express` repository
provides a comprehensive example of how to use the library's features. It includes examples of how to use Elm and
JavaScript together to build a functional application. You can refer to this example to get a better understanding of
how to use the library and its capabilities.