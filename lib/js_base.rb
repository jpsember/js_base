require 'fileutils'
require 'pathname'
require 'set'
require 'trollop'
require 'json'

class IllegalStateException < Exception; end
class SystemCallException < Exception; end

# Print a message and exit the script;
# note, this should be considered deprecated; raise an ArgumentError or
# some other type of exception instead
#
def die(msg=nil)
  msg ||= "Unknown problem"
  puts msg
  exit(false)
end

# Print a 'warning' alert, one time only
# @param args if present, calls sprintf() with these
def warning(*args)
  RubyBase.one_time_alert("warning",0, *args)
end

# Print an 'unimplemented' alert, one time only
# @param args if present, calls sprintf() with these
def unimp(*args)
  RubyBase.one_time_alert("unimplemented", 0, *args)
end

$assertions_found = false

# Die if a condition isn't true (note this is distinct from Test:Unit assertions)
#
def assert!(condition,*args)
  if !$assertions_found
      RubyBase.one_time_alert("performing assertion",0,*args)
      $assertions_found = true
  end
  if !condition
    msg = 'Assertion failure'
    if args && !args.empty?
      msg << ': ' << sprintf(args[0], *args[1..-1])
    end
    die(msg)
  end
end

# Make a system call
#
# @param cmd command to execute
# @param abort_if_problem if return code is nonzero, raises SystemCallException
# @return [captured output, success flag] (where success is true if return code was zero)
#
def scall(cmd, abort_if_problem = true)
  require 'open3'
  res = nil
  status = false
  begin
    res,status = Open3.capture2e(cmd)
  rescue Exception => e
    status = 1
    res = e.to_s
  end

  success = (status == 0)

  if !success && abort_if_problem
    raise SystemCallException,"Failed system call (status=#{status}): '#{cmd}'\n"+res
  end

  [res, success]
end

# Make a number of system calls
#
# @param cmds commands to execute, delimited by linefeeds; those beginning with '#' are comments
# @param abort_if_problem if any commands unsuccessful, raises SystemCallException
# @return [captured output, return code], where return code is true iff all calls were successful
#
def scalls(cmds, abort_if_problem = true)
  cmd_string = ''
  cmds.lines.each do |cmd|
    cmd.chomp!
    cmd.lstrip!
    next if cmd == '' || cmd.start_with?('#')
    cmd_string << ' && ' if cmd_string.length != 0
    cmd_string << cmd
  end
  scall(cmd_string, abort_if_problem)
end

# Convenience method to perform 'require_relative' on a set of files
#
# Example:
#   req('plotter stats')            # require_relative('plotter'), require_relative('stats')
#   req('plotter stats','tools')    # require_relative('tools/plotter'), require_relative('tools/stats')
#
# @param fileListStr  space-delimited items
# @param subdir  optional path to prepend to each of the items
#
def req(fileListStr,subdir = nil)

  # Determine absolute path of caller
  c = caller()[0]
  c = c[0...c.index(':')]

  base_path = File.absolute_path(File.dirname(c))
  if subdir
    base_path = File.join(base_path,subdir)
  end

  fileListStr.split(' ').each do |x|
    require(File.join(base_path,x))
  end
end

# A 'do { ... } while false' loop structure, so 'break' can be done to jump to the end
#
def once_only
  yield
end

# Switch to the calling script's directory to run a block
def from_our_dir(depth = 0)
  die "Missing block" if !block_given?
  caller_info = caller[depth]
  caller_file = caller_info.split(':')[0]
  caller_dir = File.dirname(caller_file)

  Dir.chdir(caller_dir){ yield }
end

# Do a 'pretty print' of a json value, with deterministic ordering of map keys
#
def pretty_pr(obj,dest='',indent=0)
  if obj.nil?
    dest << 'null'
  elsif obj.is_a? Hash
    pretty_pr_map(obj,dest,indent)
  elsif obj.is_a? Array
    pretty_pr_list(obj,dest,indent)
  else
    dest << obj.to_json
  end
  dest
end

def pretty_pr_map(map,dest,indent)
  indent += 2
  key_set = map.keys.sort
  same_line = (key_set.length < 2)
  dest << '{ '
  initial_adjustment = -indent
  longest_key = ''
  key_set.each do |key|
    longest_key = key if key.length  > longest_key.length
  end
  i = -1
  key_set.each do |key|
    i += 1
    extraIndent = longest_key.length - key.length
    tab(dest,dest.length +  indent + extraIndent + initial_adjustment)
    dest << '"' << key << '" : '
    extraIndent += 5 + key.length
    value = map[key]
    pretty_pr(value,dest,indent + extraIndent)
    initial_adjustment = 0
    dest << ",\n" if (!same_line and i + 1 < key_set.length)
  end
  indent -= 2
  if (!same_line)
    dest << "\n"
    tab(dest,dest.length + indent)
  else
    dest << ' '
  end
  dest << '}'
end

def pretty_pr_list(list,dest,indent)
  initial_adjustment = 0
  indent += 2
  initial_adjustment = -indent
  dest << '[ '
  size = list.size
  row_length = 0
  size.times do |i|
    value = list[i]
    start_cursor = dest.length
    pretty_pr(value, dest, indent)
    row_length += dest.length - start_cursor
    initial_adjustment = 0
    if i + 1 < size
      dest << ','
      if row_length > 40
        dest << "\n"
        row_length = 0
        tab(dest, dest.length + indent + initial_adjustment)
      end
    end
  end
  indent -= 2
  dest << ' ]'
end

# Append spaces, if necessary, to make string no shorter than length
#
def tab(dest,length)
  dest << ' ' * [0,length - dest.length].max
end


# This module contains less frequently used methods, to avoid
# polluting the top-level namespace.
#
module RubyBase

  module_function

  # Wait for user to press a key.
  # Optionally converts ctrl-c to other characters; otherwise,
  # raises an Interrupt.
  #
  def get_user_char(replacement_for_ctrl_c = nil)
    begin
      require 'io/console'
      char = $stdin.getch
    end
    if char.ord == 3
      if !replacement_for_ctrl_c
        raise Interrupt
      end
      char = replacement_for_ctrl_c
    end
    char
  end

  # Set of alert strings that have already been reported
  # (to avoid printing anything on subsequent invocations)
  #
  ALERT_STRINGS = Set.new

  # Print a message to $stderr if it hasn't yet been printed,
  # which includes the caller's location
  #
  # @param alert_name  e.g., "warning", "unimplemented"
  # @param depth_within_caller_stack    the number of levels deep that the caller is in the stack
  # @param args if present, calls sprintf(...) with these to append to the message
  #
  def one_time_alert(alert_name, depth_within_caller_stack, *args)
    loc = get_caller_location(depth_within_caller_stack + 2)
    msg = '*** ' << alert_name << ': ' << loc
    if args && !args.empty?
      msg << ' ' << sprintf(args[0], *args[1..-1])
    end

    if ALERT_STRINGS.add?(msg)
      $stderr.puts msg
    end
  end

  # Get a concise description of the file and line
  # of some caller within the stack.
  #
  def get_caller_location(depth_within_caller_stack = 2)

    filename = nil
    linenumber = nil

    if depth_within_caller_stack >= 0 && depth_within_caller_stack < caller.size
      info = caller[depth_within_caller_stack]

      i = info.index(':')
      j = nil
      if i
        j = info.index(':',i+1)
      end
      if j
        path = info[0,i].split('/')
        if !path.empty?
          filename = path[-1]
        end
        linenumber = info[i+1,j-i-1]
      end
    end
    if filename && linenumber
      RubyBase.get_filename_linenumber_description(filename,linenumber)
    else
      "(UNKNOWN LOCATION)"
    end
  end

  # This is a separate method so unit tests can replace it with something that
  # is not sensitive to line number changes due to minor source edits
  #
  def get_filename_linenumber_description(filename,linenumber)
    "#{filename} (#{linenumber})"
  end

end # module

# Add other utility files as well

req 'file_utils array_utils hash_utils', 'js_base'

# I'm disabling this warning nag message, since I've been using some third party libraries
# that seem riddled with warnings, and it's creating too much noise.
#
if false && !$-w
  warning "Ruby warnings are DISABLED; please set the RUBYOPT environment variable to '-w'"
end

die "Unexpected Ruby version number" if !RUBY_VERSION.start_with?("2.")
