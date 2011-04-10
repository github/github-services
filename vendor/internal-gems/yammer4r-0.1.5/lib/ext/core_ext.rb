class String
  def to_boolean
    case self
    when 'true'
      true
    when 'false'
      false
    else
      nil
    end
  end
end

class Hash
  def symbolize_keys
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end

  def symbolize_keys!
    self.replace(self.symbolize_keys)
  end

  def assert_has_keys(*valid_keys)
    missing_keys = [valid_keys].flatten - keys
    raise(ArgumentError, "Missing Option(s): #{missing_keys.join(", ")}") unless missing_keys.empty?
  end
end
