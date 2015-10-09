@@ldapi = LearndotAPI.new

def field_from_entity(field, entity)
  field_values = []
  
  entity.each_value do | item |
    field_values << item[field]
  end
  
  return field_values
end

def get_classes(conditions)
  classes = @@ldapi.get_records(:public_course_event, conditions)

  course_ids = field_from_entity('courseId', classes)
  courses = @@ldapi.get_records(:course, { 'id' => course_ids.uniq })

  location_ids = field_from_entity('locationId', classes)
  locations = @@ldapi.get_records(:location, { 'id' => location_ids.uniq})
  
  total_enrollments = 0
  
  classes.each do | class_id, klass |
    course = courses[klass['courseId']]
    klass[:course_name] = course['name']
    klass['startTime'] = Date.parse(klass['startTime'])
    klass[:enrollment_count] = @@ldapi.get_enrollment_numbers(class_id)

    location = locations[klass['locationId']]   
    if location['online']
      klass[:city] = location['name']
    else 
      klass[:city] = location['address']['city']
    end
  end
  
  return classes
end

def get_enrollments(enrollment_conditions)
  enrollments = @@ldapi.get_records(:enrolment, enrollment_conditions)
  
  student_ids = field_from_entity('contactId', enrollments)
  
  student_conditions = { 'id' => student_ids.uniq }
  students = @@ldapi.get_records(:contact, student_conditions)
  
  enrollments.each_value do | enrollment |
    student = students[enrollment['contactId']]
    enrollment[:contact_name] = student['_displayName_']
  end
  
  return enrollments
end

def @@ldapi.get_enrollment_numbers(class_id)
  session_conditions = { 'eventId' => [class_id] }
  course_sessions = @@ldapi.get_records(:course_session, session_conditions)
  
  if ! course_sessions.empty?
    enrolment_ids = field_from_entity('enrolmentId', course_sessions)
    enrollment_conditions = {
      'id' => enrolment_ids,
      'status' => ['TENTATIVE', 'APPROVED', 'CONFIRMED']
    }
    num_enrollments = get_record_count('enrolment', enrollment_conditions)
  end
  
  return num_enrollments ? num_enrollments : 0
end

def get_order_item_enrollments(enrollment_conditions)
  enrollments = get_enrollments(enrollment_conditions)
  order_item_ids = field_from_entity('orderItemId', enrollments).uniq.shift
  puts order_item_ids
  
  # do not run this until figure out why it returned 2247 pages of records
  # order_items = @@ldapi.get_records(:order_item, { 'id' => order_item_ids }) 
  
  # enrollments.each_value do | enrollment |
  #   puts enrollment['orderItemId']
  # end
  
  return enrollments
end

def get_course_catalog
  courses = @@ldapi.get_records(:course)
  
  primary_category_ids = field_from_entity('primaryCategoryId', courses).uniq
  categories = @@ldapi.get_records(:knowledge_category, { 'id' => primary_category_ids })
  
  courses.each_value do | course |
    category = categories[course['primaryCategoryId']]
    course[:category] = category['_displayName_']
  end
  
  return courses.group_by{ |k, v| v[:category] }
end
