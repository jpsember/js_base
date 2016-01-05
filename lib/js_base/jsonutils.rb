module JsonUtils

  module_function

  def pretty_pr_aux(obj,dest,indent)
    if obj.nil?
      dest << 'null'
    elsif obj.is_a? Hash
      pretty_pr_map(obj,dest,indent)
    elsif obj.is_a? Array
      pretty_pr_list(obj,dest,indent)
    else
      dest << obj.to_json
    end
  end

  def clamped_key_length(key_length)
    [18,key_length].min
  end

  def length_of_longest_string(set)
    len = 0
    set.each do |string|
      len = [len,string.length].max
    end
    len
  end

  def pretty_pr_map(map,dest,indent)
    indent += 2
    key_set = map.keys.sort
    dest << '{ '

    longest_length = clamped_key_length(length_of_longest_string(key_set))

    first_key = true
    key_set.each do |key|
      effective_key_length = clamped_key_length(key.length)

      key_indent = longest_length
      if first_key
        # Cursor is already indented for first key
        first_key = false
      else
        dest << ",\n"
        key_indent += indent
      end

      tab(dest, dest.length + key_indent - effective_key_length)

      dest << '"' << key << '" : '

      val_indent = indent + longest_length + 5

      # If the key we just printed was longer than our maximum,
      # print the value on the next line (indented to the appropriate column)
      if key.length > longest_length
        dest << "\n"
        tab(dest, dest.length + val_indent)
      end

      pretty_pr_aux(map[key],dest,val_indent)
    end

    indent -= 2
    if (key_set.length >= 2)
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
      pretty_pr_aux(value, dest, indent)
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

end
