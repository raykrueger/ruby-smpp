# Basic SMS class for sample gateway

class Sms
  attr_accessor :id, :from, :to, :body
  
  def initialize(body)
    self.body = body
  end
end