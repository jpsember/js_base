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

  def pretty_pr_map(map,dest,indent)
    indent += 2
    key_set = map.keys.sort
    same_line = (key_set.length < 2)
    dest << '{ '
    initial_adjustment = -indent
    longest_key = ''
    key_set.each do |key|
      longest_key = key if key.length  > longest_key.length
    end
    i = -1
    key_set.each do |key|
      i += 1
      extraIndent = longest_key.length - key.length
      tab(dest,dest.length +  indent + extraIndent + initial_adjustment)
      dest << '"' << key << '" : '
      extraIndent += 5 + key.length
      value = map[key]
      pretty_pr_aux(value,dest,indent + extraIndent)
      initial_adjustment = 0
      dest << ",\n" if (!same_line and i + 1 < key_set.length)
    end
    indent -= 2
    if (!same_line)
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
