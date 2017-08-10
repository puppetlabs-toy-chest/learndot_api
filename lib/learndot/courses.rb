class Learndot::Courses
  def initialize(api)
    @api = api
  end

  def retrieve(conditions, options = {orderBy: 'Name', asc: true})
    courses = @api.search(:learning_component, conditions, options)

    if !courses.empty?
      course_ids    = courses.collect { | k, c | c['id']    }.uniq

      courses    = @api.search(:learning_component,   { 'id' => course_ids    })

      courses.collect do | course_id, course |
        course[:id]           = course['id']
        course[:name]         = course['name']
        course[:components]   = course['components']

        course
      end
    end
  end

  def enrollment_count(course_id)
    enrollments = @api.search(:enrolment, { 'componentId' => [course_id] })

    if ! enrollments.empty?
      enrollment_ids         = enrollments.collect { | k, cs | cs['id'] }
      enrollment_conditions = {
        'id'     => enrollment_ids,
      }
      count = @api.count('enrolment', enrollment_conditions)
    end

    return count || 0
  end

  def enrolled(course_id)
    enrollments = @api.search(:enrolment, { 'componentId' => [course_id] })
    return [] if enrollments.empty?

    conditions = {
      'id'     => enrollments.collect { | k, cs | cs['id'] },
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
  def courses
    Learndot::Courses.new(self.api)
  end
end
