class Array

  # Find index of first element that returns true for a block.
  #
  # Assumes that of the k elements in the array, the block returns false
  # only for the first n (<= k).
  #
  # Returns n.
  #
  def binary_search
    min = 0
    max = self.size
    while min < max
      mid = (min+max)/2
      result = yield(at(mid))
      if !result
        min = mid + 1
      else
        max = mid
      end
    end
    max
  end

end

