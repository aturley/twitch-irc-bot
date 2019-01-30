use "collections"
use "debug"
use "net"
use "time"
use "twitch_irc_bot"

class SpamTimerNotify is TimerNotify
  let _irc_message_responder: MyIRCMessageResponder

  new iso create(mimr: MyIRCMessageResponder) =>
    _irc_message_responder = mimr

  fun apply(timer: Timer, count: U64): Bool =>
    Debug("spam")
    _irc_message_responder.spam()
    true

actor MyIRCMessageResponder is IRCMessageResponder
  let _name_map: Map[String, USize]
  let _channels: Array[String] val

  let _timers: Timers

  var _conn: (None | TCPConnection)

  var _has_been_chat: Bool

  new create(channels: Array[String] val) =>
    _name_map = Map[String, USize]
    _channels = channels
    _timers = Timers
    _conn = None
    _has_been_chat = false

  be connected(conn: TCPConnection) =>
    _conn = conn
    let timer = Timer(SpamTimerNotify(this), 1_000_000_000 * 60 * 5,
      1_000_000_000 * 60 * 5)
    _timers(consume timer)

  be privmsg(conn: TCPConnection, prefix: String, chan: String,
    msg: String)
  =>
    _has_been_chat = true

    let nick = SplitPrefix(prefix)._1

    Debug("chan=" + chan)

    if msg.contains("famous_mister_ed") then
      IRCCommand.privmsg(conn, chan, "hello, " + nick + "!")

      _name_map(nick) = _name_map.get_or_else(nick, 0) + 1
    elseif msg == "!namecount" then
      Debug("processing !namecount")

      var repr = "{"

      for (n, c) in _name_map.pairs() do
        repr = repr + " " + n + ":" + c.string()
      end

      repr = repr + "}"

      Debug("namecount:" + repr)

      IRCCommand.privmsg(conn, chan, repr)
    end

  be command(conn: TCPConnection, prefix: String, command_name: String,
    params: Array[String] val)
  =>
    match command_name
    | "366" =>
      Debug("FOUND 366")
      try
        let chan = params(params.size() - 2)?
        Debug("chan=" + chan)
        IRCCommand.privmsg(conn, chan, "Wilbur!")
      end
    end

  be spam() =>
    if not _has_been_chat then
      match _conn
      | let conn: TCPConnection =>
        for c in _channels.values() do
          IRCCommand.privmsg(conn, "#" + c, "Let's make some noise in here!")
        end
      end
    end

    _has_been_chat = false

actor Main
  new create(env: Env) =>
    var twitch_nick = ""
    var twitch_password = ""

    try
      for x in env.vars.values() do
        let parts = x.split("=")
        if parts(0)? == "TWITCH_USERNAME" then
          twitch_nick = parts(1)?
        end
        if parts(0)? == "TWITCH_PASSWORD" then
          twitch_password = parts(1)?
        end
      end
    else
      env.err.print("couldn't get nickname and password")
      return
    end

    let channels: Array[String] val = try
      // expect 2nd argument to be "chan1,chan2,chan3,..."
      env.args(1)?.split(",")
    else
      env.err.print("first argument should be a comma-separated list of channels to join.")
      return
    end

    if twitch_nick.size() == 0 then
      env.err.print("could not get nickname, please set the nickname in the TWITCH_USERNAME environment variable.")
      return
    else
      env.out.print("nick=" + twitch_nick)
    end

    if twitch_password.size() == 0 then
      env.err.print("could not get password, please set the nickname in the TWITCH_PASSWORD environment variable.")
      return
    else
      env.out.print("got password")
    end

    try
      TCPConnection(env.root as AmbientAuth,
        TwitchChatConnectionNotify(twitch_nick, twitch_password, channels,
          MyIRCMessageResponder(channels)),
        "irc.chat.twitch.tv", "6667")
    end
