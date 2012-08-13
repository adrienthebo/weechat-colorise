# Automatically apply color to messages sent to a given channel.

COLORISED_BUFFERS = {}

def weechat_init
  name    = "colorise"
  author  = "Adrien Thebo <contact@somethingsinistral.net>"
  version = '0.0.1'
  license = "Apache 2.0"
  desc    = "Apply color to all messages sent to a given channel. For those extra flamboyant channels."

  usage = "add <channel> <color> | rm <channel>"

  long_usage = <<-EOD
add <buffer> <color> : Add the <color> color code to all messages to <buffer>
list                 : Display currently colorised channels.
rm  <buffer>         : Remove color from a channel. Only do this if you hate unicorns.

Buffer names need to be full names, not just a channel or private message name.
Given an irc server of freenode and a channel named #fairies, the channel name
needs to be freenode.#fairies, not just #fairies.

EXAMPLES:

/colorise add freenode.#fairies 09
/colorise add freenode.#angermanagement 01,05
/colorise rm freenode.#ihateunicorns
  EOD

  Weechat.register(name, author, version, license, desc, "", "")
  Weechat.hook_command("colorise", desc, usage, long_usage, "", "colorise_command", "")
  Weechat.hook_command_run("/input return", "colorise_callback", "")

  Weechat::WEECHAT_RC_OK
end

def colorise_command(data, ptr, cmd)

  subcommand, *args = cmd.split(' ')

  case subcommand
  when "add"
    colorise_add(args)
  when "list"
    colorise_list
  when "rm"
    colorise_rm(args)
  else
    Weechat.print "", "Unrecognized command '#{subcommand}', see /help colorise"
    Weechat::WEECHAT_RC_ERROR
  end
end

def colorise_add(args)
  unless args.length == 2 and args[0].match /\S+/ and args[1].match /\d+/
    Weechat.print "", "Invalid input for /colorise add, see /help colorise"
    return Weechat::WEECHAT_RC_ERROR
  end

  Weechat.print "", "Colorising #{args[0]}"
  COLORISED_BUFFERS[args[0]] = args[1]

  Weechat::WEECHAT_RC_OK
end

def colorise_list

  output = "Colorised channels\n==================\n"

  channel_max = COLORISED_BUFFERS.keys.max   {|a, b| a.length <=> b.length}.length
  code_max    = COLORISED_BUFFERS.values.max {|a, b| a.length <=> b.length}.length

  COLORISED_BUFFERS.each do |(channel, code)|
    channel_padding = ' ' * (channel_max - channel.length)
    output << "#{channel + channel_padding} | #{code}\n"
  end

  Weechat.print "", output

  Weechat::WEECHAT_RC_OK
end

def colorise_rm(args)
  unless args.length == 1 and args[0].match /\S+/
    Weechat.print "", "Invalid input for /colorise add, see /help colorise"
    return Weechat::WEECHAT_RC_ERROR
  end

  Weechat.print "", "Decolorising #{args[0]}, and stabbing a unicorn."
  COLORISED_BUFFERS.delete(args[0])

  Weechat::WEECHAT_RC_OK
end

def colorise_callback(data, ptr, cmd)
  buffer_name = Weechat.buffer_get_string(ptr, "name")
  input       = Weechat.buffer_get_string(ptr, "input")

  if input.match %r{^/[^/].*}
    # Don't colorise messages that are weechat commands.
    Weechat::WEECHAT_RC_OK
  elsif COLORISED_BUFFERS[buffer_name]
    colorise_message(ptr)
  else
    Weechat::WEECHAT_RC_OK
  end
end

def colorise_message(buffer_ptr)

  buffer_name  = Weechat.buffer_get_string(buffer_ptr, "name")
  input        = Weechat.buffer_get_string(buffer_ptr, "input")

  newput = "\x03#{COLORISED_BUFFERS[buffer_name]}#{input}"
  Weechat.buffer_set(buffer_ptr, "input", newput)

  Weechat::WEECHAT_RC_OK
end
