module JsonUtils

  module_function

  def pretty_pr_aux(obj,options)
    if obj.nil?
      options[:dest] << 'null'
    elsif obj.is_a? Hash
      pretty_pr_map(obj,options)
    elsif obj.is_a? Array
      pretty_pr_list(obj,options)
    else
      options[:dest] << obj.to_json
    end
  end

  MAX_KEY_LENGTH = 18
  PADDING = MAX_KEY_LENGTH / 4

  def length_of_longest_string(set)
    len = 0
    padded_len = 0
    padded_possible = true
    set.each do |string|
      if padded_possible
        if string.length <= MAX_KEY_LENGTH + PADDING
          padded_len = [padded_len,string.length].max
        else
          padded_possible = false
        end
      end
      if string.length <= MAX_KEY_LENGTH
        len = [len,string.length].max
      end
    end
    if padded_possible
      padded_len
    else
      len
    end
  end

  def pretty_pr_map(map,options)
    indent = options[:indent]
    dest = options[:dest]

    indent += 2
    key_set = map.keys
    if options[:sortkeys]
      key_set = key_set.sort
    end
    dest << '{ '

    longest_length = length_of_longest_string(key_set)

    first_key = true
    key_set.each do |key|
      effective_key_length = [longest_length,key.length].min

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
      options[:indent] = val_indent
      pretty_pr_aux(map[key],options)
    end

    indent -= 2
    if (key_set.length >= 2)
      dest << "\n"
      tab(dest,dest.length + indent)
    else
      dest << ' '
    end
    dest << '}'
    options[:indent] = indent
  end

  def pretty_pr_list(list,options)
    indent = options[:indent]
    dest = options[:dest]

    initial_adjustment = 0
    indent += 2
    initial_adjustment = -indent
    dest << '[ '
    size = list.size
    row_length = 0
    size.times do |i|
      value = list[i]
      start_cursor = dest.length
      options[:indent] = indent
      pretty_pr_aux(value, options)
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
    options[:indent] = indent
  end

end
