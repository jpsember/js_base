class Hash

  if !Hash.method_defined?(:reverse_merge)

    def reverse_merge(other_hash)
      other_hash.merge(self)
    end

    def reverse_merge!(other_hash)
      replace(reverse_merge(other_hash))
    end

  end

end
