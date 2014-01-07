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
      @description = ''
      @indent_stack = []
      @indent = 0
      dump(@object)
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
      @description << '<nil>'
    elsif arg.is_a?(Array)
      dump_array(arg)
    elsif arg.is_a?(Hash)
      dump_hash(arg)
    elsif arg.class == FalseClass || arg.class == TrueClass
      dump_boolean(arg)
    elsif arg.is_a?(Set)
      dump_set(arg)
    else
      @description << arg.inspect
    end
  end

  def dump_array(array)
    @description << 'Array ['
    push
    array.each do |x|
      @description << "\n"
      pad
      push
      dump(x)
      pop
    end
    pop
    @description << " ]"
  end

  def dump_hash(hash)
    @description << 'Hash {'
    push
    hash.each_pair do |key,val|
      s2 = key.to_s
      @description << "\n"
      pad
      @description << s2.chomp << ' => '
      push 4
      dump(val)
      pop
    end
    @description << ' }'
    pop
  end

  def dump_boolean(flag)
    @description << (flag ? "T" : "F")
    @description << ' '
  end

  def dump_set(set)
    @description << 'Set {'
    push
    set.each do |x|
      @description << "\n"
      pad
      push
      dump(x)
      pop
    end
    @description << ' }'
    pop
  end

end
