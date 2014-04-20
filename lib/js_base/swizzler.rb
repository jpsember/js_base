class Swizzler

  $within_backtrace = false

  def initialize
    @method_map = {}
  end

  def add(class_name_or_nil,method_name,&method_definition)
    class_name = class_name_or_nil || 'Object'
    the_class = Kernel.const_get(class_name)
    active_class = the_class
    add_aux(class_name,method_name,active_class,&method_definition)
  end

  # For top-level methods, pass nil as the class name.
  #
  def add_meta(class_name_or_nil,method_name,&method_definition)
    class_name = class_name_or_nil || 'Object'
    the_class = Kernel.const_get(class_name)
    active_class = class << the_class; self; end
    add_aux(class_name,method_name,active_class,&method_definition)
  end

  def remove(class_name_or_nil,method_name)
    class_name = class_name_or_nil || 'Object'
    key = MethodRecord.hash_key_for(class_name,method_name)
    record = @method_map[key]
    return if !record

    @method_map.delete(key)

    unswizzle_record(record)
  end

  def remove_all
    @method_map.values.each do |record|
      unswizzle_record(record)
    end
    @method_map.clear
  end

  def shorten_backtraces(max_length = 5)
    add('Exception','backtrace') do
      bt = __original__backtrace
      if bt && !$within_backtrace
        $within_backtrace = true
        if bt.length > max_length
          bt.slice!(max_length..-1)
        end
        $within_backtrace = false
      end
      bt
    end
  end


  private


  def add_aux(class_name,method_name,active_class,&method_definition)
    record = MethodRecord.new(class_name,method_name,active_class)
    record.original_body = active_class.instance_method(method_name)

    @method_map[record.hash_key] = record

    active_class.send(:remove_method,method_name)
    active_class.send(:define_method,method_name,method_definition)
    active_class.send(:define_method,record.name_for_original_method_body,record.original_body)
  end

  def unswizzle_record(record)
    the_class = record.active_class
    the_class.send(:remove_method,record.method_name)
    the_class.send(:define_method,record.method_name,record.original_body)
    the_class.send(:remove_method,record.name_for_original_method_body)
  end

  class MethodRecord
    attr_reader :class_name, :method_name, :active_class
    attr_accessor :original_body

    def initialize(class_name,method_name,active_class)
      @class_name = class_name
      @method_name = method_name
      @active_class = active_class
      @hash_key = nil
    end

    def hash_key
      if !@hash_key
        @hash_key = MethodRecord.hash_key_for(@class_name,@method_name)
      end
      @hash_key
    end

    def self.hash_key_for(class_name,method_name)
      "#{class_name}|#{method_name}"
    end

    def name_for_original_method_body
      '__original__'+method_name
    end

  end

end
