class Learndot::Events
  def initialize(api)
    @api = api
  end

  def retrieve(conditions, options = {orderBy: 'startTime', asc: true})
    classes = @api.search(:public_course_event, conditions, options)

    if !classes.empty?
      course_ids    = classes.collect { | k, c | c['courseId']    }.uniq
      location_ids  = classes.collect { | k, c | c['locationId']  }.uniq
      organizer_ids = classes.collect { | k, c | c['organizerId'] }.uniq

      courses    = @api.search(:course,   { 'id' => course_ids    })
      locations  = @api.search(:location, { 'id' => location_ids  })
      organizers = @api.search(:contact,  { 'id' => organizer_ids })

      classes.each do | class_id, klass |
        location = locations[klass['locationId']]

        klass[:city]             = location['online'] ? location['name'] : location['address']['city']
        klass[:course_name]      = courses[klass['courseId']]['name']
        klass[:organizer]        = organizers[klass['organizerId']] ? organizers[klass['organizerId']]['_displayName_'] : ''
        klass[:enrollment_count] = enrollment_count(class_id)
        klass[:start_time]       = Date.parse(klass['startTime'])
      end
    end
  end

  def enrollment_count(class_id)
    sessions = @api.search(:course_session, { 'eventId' => [class_id] })

    if ! sessions.empty?
      enrolment_ids         = sessions.collect { | k, cs | cs['enrolmentId'] }
      enrollment_conditions = {
        'id'     => enrolment_ids,
        'status' => ['TENTATIVE', 'APPROVED', 'CONFIRMED']
      }
      count = @api.count('enrolment', enrollment_conditions)
    end

    return count || 0
  end

  def enrolled(class_id)
    sessions = @api.search(:course_session, { 'eventId' => [class_id] })
    return [] if sessions.empty?

    conditions = {
      'id'     => sessions.collect { | k, cs | cs['enrolmentId'] },
      'status' => ['TENTATIVE', 'APPROVED', 'CONFIRMED']
    }
    enrollments = @api.search(:enrolment, conditions)
    return [] if enrollments.empty?

    conditions = {
      'id'     => enrollments.collect { | k, cs | cs['contactId'] },
    }
    contacts = @api.search(:contact, conditions)

    contacts.collect do | k, cs |
      { :id => cs['id'], :name => cs['_displayName_'], :email => cs['email'] }
    end
  end

end

class Learndot
  def events
    Learndot::Events.new(self.api)
  end
end
