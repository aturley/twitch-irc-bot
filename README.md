# twitch-irc-bot

A library for creating Twitch IRC bots in Pony.

This library was initially created across a series of livestreams, which you can watch on [YouTube](https://www.youtube.com/watch?v=W1Q9Igm9heU&list=PLLhCH5zYT00GiUs8iM0S-coXHh-_P_bDS).

## How to Use It

In order to use this library you will need to have [the Pony compiler](https://github.com/ponylang/ponyc) and [the Pony package manager](https://github.com/ponylang/pony-stable) installed.

### Building the Example

There is an example bot in the `example` directory. The bot gets login credentials from environment variables and connects to the channels specified as a comma-separated list on the command line. When it connects it does a few things:

* It says "Wilbur!" immediately after joining a channel.
* Every 5 minutes, if there has been no chat activity, it says "Let's make some noise in here!"
* When someone says "famous_mister_ed" it will say hello to that person.
* When someone sends the command `!namecount` it will print out a count of how many times different people have said "famous_mister_ed".

This is intended as a simple way to show some of the things you can do when building a bot.

You can go into that directory and build it by running:

```bash
stable env ponyc
```

This will build an executable called `example`.

### Running the Example

In order to run the example you will need a Twitch username and [oauth token](https://twitchapps.com/tmi/). You should export an environment variable with your username called `TWITCH_USERNAME` and another one with your oauth token called `TWITCH_PASSWORD`. For example if your username is `bumblebee666` and your oauth token is `abcd1234efgh5678ijkl9012mnop34`, and your channel is called `bumblebeehome` then you can run the bot with the following commands:

```bash
export TWITCH_USERNAME=bumblebee666
export TWITCH_PASSWORD=oauth:abcd1234efgh5678ijkl9012mnop34

./example bumblebeehome
```

### Using the Library

You can use the library by telling `stable` to include it as a dependency like this:

```bash
stable add github aturley/twitch-irc-bot
```

Then you can build your bot and build it with `stable`.
