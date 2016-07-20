#! /usr/bin/env ruby
require 'learndot'
require 'learndot/events'

class String
  def trim(size)
    if self.size > size
      "#{self[0...(size - 1)]}…"
    else
      self
    end
  end
end

conditions = {
  'startTime' => [Learndot.timestamp(), Learndot.timestamp(1*7*24*60*60)],
  'status'    => ['CONFIRMED', 'TENTATIVE'],
}

ld     = Learndot.new(true)
events = ld.events.retrieve(conditions)

puts '   Date    |         Course                 |      Location               |  #'
puts '------------------------------------------------------------------------------'
events.each do |delivery|
  printf("%10s | %-30s | %-27s | %2s\n",
      delivery[:start_time],
      delivery[:course_name].trim(30),
      delivery[:city],
      delivery[:enrollment_count])
end
