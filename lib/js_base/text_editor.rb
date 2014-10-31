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
    pth = "\"#{@path}\""

    case editor
    when 'vi','vim'
      cmd << " +#{@line_number}" if @line_number
      cmd << " #{pth}"
    when 'subl'
      cmd << " #{pth}"
      cmd << ":#{@line_number}" if @line_number
      cmd << ' -n -w'
    else
      cmd << " #{pth}"
    end
    system(cmd)
  end
end
