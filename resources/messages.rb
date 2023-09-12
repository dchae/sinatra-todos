class Message
  attr_reader :type, :text

  def initialize(type, text)
    @type = type
    @text = text
  end
end

class ErrorMessage < Message
  def initialize(text)
    super("error", text)
  end
end


class SuccessMessage < Message
  def initialize(text)
    super("success", text)
  end
end