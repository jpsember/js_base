require 'js_base/js_test'

# Set up some examples of the different types of methods


# Define a top-level method

def gamma
  'toplevel gamma'
end


module OurModule

  def self.our_module_function
    'blue'
  end

  def self.gamma
    'OurModule gamma'
  end

  def our_method
    'blue'
  end

end


class Alpha

  def our_method
    'blue'
  end

  def our_method_with_args(x,y)
    x + y
  end

  def self.our_class_method
    'blue'
  end

  def gamma
    'Alpha gamma'
  end

end


class Beta

  include OurModule

end


class TestSwizzler < JSTest

  def has_instance_method(the_class,method_name)
    begin
      body = the_class.instance_method(method_name)
    rescue Exception
    end
    body != nil
  end

  def explore_class(the_class,class_type,method_name,&block)
    puts " #{class_type}: '#{the_class}'"
    body = nil

    f_public = the_class.public_method_defined? method_name
    f_protected = the_class.protected_method_defined? method_name
    f_private = the_class.private_method_defined? method_name
    puts "        pub:#{f_public} prot:#{f_protected} priv:#{f_private}"
    begin
      body = the_class.instance_method(method_name)
    rescue Exception
      puts "        exception getting instance method"
    end


    if body
      puts "        has instance method"
      begin
        puts "        ---- before ------>   '#{block.call}'"
        the_class.send(:remove_method,method_name)
        the_class.send(:define_method,method_name,Proc.new{'red'})
        puts "        ---- after ------->   '#{block.call}'"
        the_class.send(:remove_method,method_name)
        the_class.send(:define_method,method_name,body)
      rescue Exception => e
        puts "Caught exception: #{e}"
      end
    end
    puts
  end

  def explore(class_name,method_name,&block)
    puts
    puts "Exploring class '#{class_name}', method '#{method_name}'"

    the_class = Kernel.const_get(class_name)
    meta_class = class << the_class; self; end

    explore_class(the_class,'class',method_name,&block)
    explore_class(meta_class,'meta ',method_name,&block)
  end


  def recursive_calls(depth_remaining)
    if depth_remaining == 0
      raise IllegalStateException,"throwing exception after recursive calls"
    else
      recursive_calls(depth_remaining - 1)
    end
  end

  def _test_100_explore
    alpha = Alpha.new
    beta = Beta.new
    explore('Alpha','our_method'){alpha.our_method}
    explore('Alpha','our_class_method'){Alpha.our_class_method}

    # 'our_method' is being reported as a public method of Beta;
    # but an exception is thrown when :remove_method is called.  This is because
    # it inherites this from the mixin
    explore('Beta','our_method'){beta.our_method}

    explore('OurModule','our_module_function'){OurModule.our_module_function}

    explore('Object','gamma'){gamma}
  end

  def test_200_instance_methods
    a = Alpha.new

    assert(a.our_method == 'blue')
    assert(a.our_method_with_args(5,12) == 17)

    self.swizzler.add('Alpha','our_method') do
      'red'
    end
    self.swizzler.add('Alpha','our_method_with_args') do |x,y|
      x * y
    end
    assert(a.our_method == 'red')
    assert(a.our_method_with_args(5,12) == 60)

    self.swizzler.remove('Alpha','our_method')
    assert(a.our_method == 'blue')
    assert(a.our_method_with_args(5,12) == 60)

    self.swizzler.remove('Alpha','our_method_with_args')
    assert(a.our_method == 'blue')
    assert(a.our_method_with_args(5,12) == 17)
  end

  def test_950_remove_all
    a = Alpha.new

    self.swizzler.add('Alpha','our_method'){'red'}
    self.swizzler.add('Alpha','our_method_with_args'){|x,y| x*y}
    self.swizzler.add_meta('Alpha','our_class_method'){'red'}
    self.swizzler.add(nil,'gamma'){'red'}

    assert_equal(a.gamma,'Alpha gamma')

    assert_equal(gamma(),'red')

    self.swizzler.remove_all

    assert_equal(Alpha.our_class_method(), 'blue')
    assert_equal(a.our_method, 'blue')
    assert_equal(a.our_method_with_args(5,12), 17)
    assert_equal(gamma(),'toplevel gamma')
  end

  def test_400_class_methods
    assert(Alpha.our_class_method() == 'blue')
    self.swizzler.add_meta('Alpha','our_class_method'){'red'}
    assert(Alpha.our_class_method() == 'red')
    self.swizzler.remove_all
    assert(Alpha.our_class_method() == 'blue')
  end

  def test_500_top_level
    assert(gamma() == 'toplevel gamma')
    self.swizzler.add(nil,'gamma'){'red'}
    assert(__original__gamma() == 'toplevel gamma')
    assert(gamma() == 'red')
    self.swizzler.remove(nil,'gamma')
    assert(gamma() == 'toplevel gamma')
  end

  def test_600_module_stuff
    assert_equal('blue',OurModule.our_module_function)
    self.swizzler.add_meta('OurModule','our_module_function'){'red'}
    assert_equal('red',OurModule.our_module_function)
    self.swizzler.remove_all
    assert_equal('blue',OurModule.our_module_function)
  end

  def test_955_class_calling_mixedin_module_function
    a = Alpha.new
    b = Beta.new
    assert_equal('blue',a.our_method)
    assert_equal('blue',b.our_method)
    self.swizzler.add('OurModule','our_method'){'red'}
    assert_equal('blue',a.our_method) # Alpha's method is distinct from Beta's
    assert_equal('red',b.our_method)

    self.swizzler.remove_all
    assert_equal('blue',b.our_method)
  end

  def test_700_kernel_method
    assert_equal('17',String(17))
    self.swizzler.add('Kernel','String'){|arg| 'ZZZ'}
    assert_equal('ZZZ',String(17))
  end


  def test_800_shortened_backtraces
    sizes = []
    for pass in 0...3 do
      if pass == 1
        self.swizzler.shorten_backtraces
      else
        self.swizzler.remove_all
      end

      begin
        recursive_calls(20)
      rescue IllegalStateException => e
        sizes << e.backtrace.size
      end
    end

    assert(sizes[0] == sizes[2] && sizes[0] > 5 && sizes[1] <= 5, "backtrace sizes #{sizes}")
  end

end

