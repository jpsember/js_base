require 'js_base/js_test'

class TestFileUtils < JSTest

  def setup
    enter_test_directory
  end

  def teardown
    leave_test_directory
  end

  def test_write_missing_text_file
    filename = 'x'
    content = 'y'
    FileUtils.write_text_file(filename,content,false)
    assert_equal(content,FileUtils.read_text_file(filename))
  end

  def test_write_unchanged_text_file_ifchanged
    filename = 'x'
    content = 'y'
    FileUtils.write_text_file(filename,content,false)
    scall("touch -t 201310310500 #{filename}")
    mtime = File.mtime(filename)
    FileUtils.write_text_file(filename,content,true)
    assert_equal(mtime,File.mtime(filename))
  end

  def test_write_unchanged_text_file
    filename = 'x'
    content = 'y'
    FileUtils.write_text_file(filename,content,false)
    scall("touch -t 201310310500 #{filename}")
    mtime = File.mtime(filename)
    FileUtils.write_text_file(filename,content,false)
    assert_not_equal(mtime,File.mtime(filename))
  end

  def test_write_changed_text_file_ifchanged
    filename = 'x'
    content = 'y'
    new_content = 'z'
    FileUtils.write_text_file(filename,content,false)
    FileUtils.write_text_file(filename,new_content,true)
    assert_equal(new_content,FileUtils.read_text_file(filename))
  end

  def test_write_changed_text_file
    filename = 'x'
    content = 'y'
    new_content = 'z'
    FileUtils.write_text_file(filename,content,false)
    FileUtils.write_text_file(filename,new_content,false)
    assert_equal(new_content,FileUtils.read_text_file(filename))
  end

  def test_read_missing_text_file_returns_default
    filename = 'x'
    content = 'y'
    new_content = FileUtils.read_text_file(filename,content)
    assert_equal(content,new_content)
  end

  def test_read_existing_text_file_doesnt_return_default
    filename = 'x'
    content = 'y'
    default_content = 'z'
    FileUtils.write_text_file(filename,content)
    new_content = FileUtils.read_text_file(filename,default_content)
    assert_equal(content,new_content)
  end

  def test_read_missing_text_file
    filename = 'x'
    assert_raise Errno::ENOENT do
      FileUtils.read_text_file(filename)
    end
  end

  def test_read_without_permissions
    # Choose a (perhaps non-existent) file that lies within a directory
    # that we don't have permissions for.  On my Mac, this will do:
    path = "/private/etc/master.passwd"
    assert_raise Errno::EACCES do
      FileUtils.read_text_file(path,"...")
    end
  end

  def test_dir_entries
    FileUtils.write_text_file("alpha","...")
    FileUtils.mkdir_p("subdir/beta")
    ents = FileUtils.directory_entries(".").sort
    assert_equal(ents,['alpha','subdir'])
  end

  def test_dir_entries_nonexistent_directory
    ents = FileUtils.directory_entries('nosuchdir').sort
    assert_equal(ents,[])
  end

  def test_dir_entries_nonexistent_directory_disallowed
    # ErrNo::ENOENT doesn't seem to be a subclass of SystemCallError as advertised
    assert_raise Errno::ENOENT do
      FileUtils.directory_entries('nosuchdir',true)
    end
  end

  def test_remove_ext1
    assert_equal(FileUtils.remove_extension('a/b_c.b/d'),'a/b_c.b/d')
  end

  def test_remove_ext2
    assert_equal(FileUtils.remove_extension('a/b_c.b/d.txt'),'a/b_c.b/d')
  end

  def test_add_ext1
    assert_equal(FileUtils.add_extension('a/b_c.b/d','txt'),'a/b_c.b/d.txt')
  end

  def test_add_ext2
    assert_equal(FileUtils.add_extension('a/b_c.b/d','.txt'),'a/b_c.b/d.txt')
  end

  def test_change_ext1
    assert_equal(FileUtils.change_extension('a/b_c.b/d','txt'),'a/b_c.b/d.txt')
  end

  def test_change_ext2
    assert_equal(FileUtils.change_extension('a/b_c.b/d.bin','.txt'),'a/b_c.b/d.txt')
  end

  def test_change_ext3
    assert_equal(FileUtils.change_extension('a/b_c.b/d.bin','txt'),'a/b_c.b/d.txt')
  end

  def test_add_extension_error1
    assert_raise ArgumentError do
      FileUtils.add_extension('a/b.txt','txt')
    end
  end

  def test_add_extension_error2
    assert_raise ArgumentError do
      FileUtils.add_extension('a/b.txt','.')
    end
  end

  def test_add_extension_error3
    assert_raise ArgumentError do
      FileUtils.add_extension('a/b.txt','')
    end
  end

end

