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

end
