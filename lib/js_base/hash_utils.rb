class Hash

  if !Hash.method_defined?(:reverse_merge)

    def reverse_merge(other_hash)
      other_hash.merge(self)
    end

    def reverse_merge!(other_hash)
      replace(reverse_merge(other_hash))
    end


  end

  # Store a key/value, or remove key if new value is nil
  #
  def store_or_delete(key,value_or_nil)
    if value_or_nil
      store(key,value_or_nil)
    else
      delete(key)
    end
  end

end
