#!/usr/bin/env ruby

class TextEditor

  attr_accessor :path
  attr_accessor :line_number

  def initialize(path = nil)
    @path = path
    @line_number = nil
  end

  def edit(path = nil)
    @path = path if path

    raise ArgumentError if !@path

    editor = (ENV['EDITOR'] || 'vi').dup

    cmd = editor

    case editor
    when 'vi','vim'
      cmd << " +#{@line_number}" if @line_number
      cmd << " #{@path}"
    when 'subl'
      cmd << " #{@path}"
      cmd << ":#{@line_number}" if @line_number
      cmd << ' -n -w'
    else
      cmd << " #{@path}"
    end
    system(cmd)
  end
end
