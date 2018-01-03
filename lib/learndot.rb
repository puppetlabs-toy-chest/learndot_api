# This class serves as a "wrapper" for subclasses. Each time a subclass is
# called, it will monkeypatch itself into this one. Then you'll have a
# factory method to return a properly scoped subclass.
#
# For example:
#
# require 'learndot'
# require 'learndot/events'
#
# conditions = {
#     'startTime' => [Learndot.timestamp(), Learndot.timestamp(3*7*24*60*60)],
#     'status'    => ['CONFIRMED', 'TENTATIVE'],
# }
#
# ld = Learndot.new
# ld.events.retrieve(conditions)
#
class Learndot
  require 'learndot/api'
  attr_reader :api

  def initialize(debug = false, staging = false)
    @api = Learndot::API.new(nil, debug, staging)
  end

  def self.timestamp(time = nil)
    time ||= Time.new
    time   = Time.new + time if time.is_a? Numeric
    raise "timestamp() expects a Time object or number of seconds from now as an integer." unless time.class == Time

    time.strftime('%Y-%m-%d %H:%M:%S')
  end
end
