module FileUtils

  module_function

  # Write a string to a text file
  #
  def write_text_file(path, contents, only_if_changed = false)
    if only_if_changed
      if File.file?(path) && read_text_file(path) == contents
        return
      end
    end
    File.open(path, "wb") {|f| f.write(contents) }
  end

  # Read a file's contents as a string; if file doesn't exist, and
  # default contents supplied, returns it instead
  #
  def read_text_file(path,default_contents=nil)
    contents = default_contents
    if !contents || File.file?(path)
      File.open(path,"rb") {|f| contents = f.read }
    end
    contents
  end

  # Get directory entries, omitting '.' and '..'
  #
  def directory_entries(dir, directory_must_exist = false)
    entries = []
    if directory_must_exist || File.directory?(dir)
       entries = Dir.entries(dir).select{|x| x != '.' && x != '..'}
    end
    entries
  end

  # Remove extension from a path, if it has one
  # Returns the modified path
  #
  def remove_extension(path)
    path2 = path.dup
    ext = File.extname(path2)
    if ext.length != 0
      path2.slice!(-ext.length..-1)
    end
    path2
  end

  # Add an extension to a path, which must not currently have an extension
  # Returns the modified path
  #
  def add_extension(path,ext)
    raise ArgumentError,"path already has extension" if File.extname(path) != ''
    if !ext.start_with?('.')
      ext = '.' + ext
    end
    raise ArgumentError,"bad or missing extension" if ext.length == 1
    path + ext
  end

  # Change path's extension, or adds extension if it doesn't already have one.
  # Returns the modified path
  #
  def change_extension(path, ext)
    add_extension(remove_extension(path),ext)
  end

  # Walk a directory tree, calling a block for each file of a particular extension encountered
  #
  def process_directory_tree(root_path,extension,&block)
    die("bad argument") if !extension.start_with?(".")
    stack = []
    stack << root_path
    while !stack.empty?
      path = stack.pop
      entries = directory_entries(path)
      entries.each do |basename|
        file = File.join(path,basename)
        if File.directory?(file)
          stack << file
        else
          next if !basename.end_with?(extension)
          yield(file)
        end
      end
    end
  end

end
