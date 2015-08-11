# Pretty-print Ruby objects; attempt to make them look like JSON
#
class Pretty

  def initialize(object)
    @object = object
    @description = nil
  end

  def self.print(object)
    Pretty.new(object).to_s
  end

  def to_s
    if !@description
      if false # About to refactor to use this
        require 'json'
        @description =JSON.pretty_generate(@object)
      else
        @description = ''
        @indent_stack = []
        @indent = 0
        dump(@object)
      end
    end
    @description
  end


  private


  def push(amt = 2)
    @indent_stack << @indent
    @indent += amt
  end

  def pop
    @indent = @indent_stack.pop
  end

  def pad
    @description << ' ' * @indent
  end

  def dump(arg)
    if !arg
      @description << 'null'
    elsif arg.is_a?(Array)
      dump_array(arg)
    elsif arg.is_a?(Hash)
      dump_hash(arg)
    elsif arg.class == FalseClass || arg.class == TrueClass
      dump_boolean(arg)
    elsif arg.is_a?(Set)
      # There's no 'set' in JSON, so approximate with an array
      dump_array(arg)
    else
      @description << arg.inspect
    end
  end

  def dump_array(array)
    @description << '['
    push
    array.each_with_index do |x,index|
      @description << "\n"
      pad
      push
      dump(x)
      @description << ',' if index + 1 < array.size
      pop
    end
    pop
    @description << " ]"
  end

  def dump_hash(hash)
    @description << '{'
    push
    hash.each_with_index do |(key,val),index|
      s2 = key.to_s
      @description << "\n"
      pad
      @description << '"' << s2.chomp << '" => '
      push 6
      dump(val)
      @description << ',' if index + 1 < hash.size
      pop
    end
    @description << ' }'
    pop
  end

  def dump_boolean(flag)
    @description << (flag ? "true" : "false")
    @description << ' '
  end

end
