# elm-express example app

This is a full elm-express application that aims to demonstrate most, if not all, of its capabilities.

## Running the example app

First you need to compile the Elm code:

```bash
elm make src/Main.elm --output build/main.js
```

Now you can start the Node.js server:

```bash
node index.js
```

## Routes

You can access the following routes:

| Route | Description |
| --- | --- |
| `/` | Very simple "Hello world!" example |
| `/reverse/[string]` | Responds with the reversed string |
| `/port-reverse/[string]` | Responds with the reversed string using ports |
| `/cookies` | Sends a JSON object of all defined cookies |
| `/cookies/set/[name]/[value]` | Defines a new cookie with the name/value informed in the URL |
| `/cookies/unset/[name]` | Deletes de cookie with the name informed in the URL |
| `/session/[key]` | Reads the value of the session key informed in the URL |
| `/session/set/[key]/[value]` | Defines a new session key with the value informed in the URL |
| `/session/unset/[key]` | Deletes the session key informed in the URL |
| `/redirect` | Simple redirection to the app's root |
| `/task` | Example of the usage of tasks by fetching some txt file and responding with it's contents |
| `/html` | Example of how to use HTML |