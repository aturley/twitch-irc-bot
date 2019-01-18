use "buffered"
use "debug"
use "net"

primitive IRCMessageString
  fun apply(msg: String): String =>
    msg + "\r\n"

class TwitchChatConnectionNotify is TCPConnectionNotify
  let _nick: String
  let _password: String
  let _channels: Array[String] val
  let _reader: Reader
  let _irc_message_responder: IRCMessageResponder

  new iso create(nick: String, password: String, channels: Array[String] val,
    irc_message_responder: IRCMessageResponder iso)
  =>
    _nick = nick
    _password = password
    _channels = channels
    _reader = Reader
    _irc_message_responder = consume irc_message_responder

  fun ref connected(conn: TCPConnection ref) =>
    Debug("CONNECTED!")
    conn.write(IRCMessageString("PASS " + _password))
    conn.write(IRCMessageString("NICK " + _nick))

  fun ref received(
    conn: TCPConnection ref,
    data: Array[U8] iso,
    times: USize)
    : Bool
  =>
    Debug("RECEIVED DATA!")

    let data': Array[U8] val = consume data

    Debug(String.from_array(data'))

    _reader.append(data')

    try
      while true do
        let msg: String = _reader.line()?
        _process_message(msg, conn)
      end
    end

    true

  fun ref connect_failed(conn: TCPConnection ref) =>
    Debug("CONNECT FAILED!")

  fun ref _process_message(msg: String, conn: TCPConnection ref) =>
    if msg.contains("You are in a maze of twisty passages, all alike.") then
      for c in _channels.values() do
        conn.write(IRCMessageString("JOIN :#" + c))
      end
    end

    try
      // look for the prefix

      var rest = msg

      (let prefix: String, rest) = if rest(0)? == ':' then
        try
          let end_prefix = rest.find(" ")?
          (rest.substring(1, end_prefix), rest.substring(end_prefix + 1))
        else
          ("", rest)
        end
      else
        ("", rest)
      end

      // look for the command

      (let command: String, rest) = try
        let end_command = rest.find(" ")?
        (rest.substring(0, end_command), rest.substring(end_command + 1))
      else
        (rest, "")
      end

      // look for "param1 param2 ... :param_trailing"

      let params = Array[String]

      while rest != "" do
        Debug("rest='" + rest + "'")
        try
          if rest(0)? == ':' then
            params.push(rest.substring(1))
            rest = ""
          else
            try
              let param_end = rest.find(" ")?
              params.push(rest.substring(0, param_end))
              rest = rest.substring(param_end + 1)
            else
              params.push(rest)
              rest = ""
            end
          end
        end
      end

      Debug("RECEIVED")
      Debug("  prefix='" + prefix + "'")
      Debug("  command='" + command + "'")
      Debug("  [" + " ".join(params.values()) + "]")

      match command
      | "366" =>
        Debug("FOUND 366")
        conn.write(IRCMessageString("PRIVMSG #aturls :Wilbur!"))
      | "PING" =>
        Debug("GOT PING")
        Debug("SENDING PONG " + params(1)?)
        conn.write(IRCMessageString("PONG " + params(1)?))
      | "PRIVMSG" =>
        _irc_message_responder.privmsg(conn, params(0)?, params(1)?)
      end
    end

interface IRCMessageResponder
  fun privmsg(conn: TCPConnection, chan: String, msg: String)
