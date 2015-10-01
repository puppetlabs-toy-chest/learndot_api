@@ldapi = LearndotAPI.new

def fieldFromEntity(field, entity)
  field_values = []
  
  entity.each_value do | item |
    field_values << item[field]
  end
  
  return field_values
end

def getClasses(conditions)
  classes = @@ldapi.getRecords(:public_course_event, conditions)

  course_ids = fieldFromEntity('courseId', classes)
  courses = @@ldapi.getRecords(:course, { 'id' => course_ids.uniq })

  location_ids = fieldFromEntity('locationId', classes)
  locations = @@ldapi.getRecords(:location, { 'id' => location_ids.uniq})
  
  total_enrollments = 0
  
  classes.each do | class_id, klass |
    course = courses[klass['courseId']]
    klass[:course_name] = course['name']
    klass['startTime'] = Date.parse(klass['startTime'])
    klass[:enrollment_count] = @@ldapi.getEnrollmentNumbers(class_id)

    location = locations[klass['locationId']]   
    if location['online']
      klass[:city] = location['name']
    else 
      klass[:city] = location['address']['city']
    end
  end
  
  return classes
end

def getEnrollments(enrollment_conditions)
  enrollments = @@ldapi.getRecords(:enrolment, enrollment_conditions)
  
  student_ids = fieldFromEntity('contactId', enrollments)
  
  student_conditions = { 'id' => student_ids.uniq }
  students = @@ldapi.getRecords(:contact, student_conditions)
  
  enrollments.each_value do | enrollment |
    student = students[enrollment['contactId']]
    enrollment[:contact_name] = student['_displayName_']
  end
  
  return enrollments
end

def @@ldapi.getEnrollmentNumbers(class_id)
  session_conditions = { 'eventId' => [class_id] }
  course_sessions = @@ldapi.getRecords(:course_session, session_conditions)
  
  if ! course_sessions.empty?
    enrolment_ids = fieldFromEntity('enrolmentId', course_sessions)
    enrollment_conditions = {
      'id' => enrolment_ids,
      'status' => ['TENTATIVE', 'APPROVED', 'CONFIRMED']
    }
    num_enrollments = getRecordCount('enrolment', enrollment_conditions)
  end
  
  return num_enrollments ? num_enrollments : 0
end

def getOrderItemEnrollments(enrollment_conditions)
  enrollments = getEnrollments(enrollment_conditions)
  order_item_ids = fieldFromEntity('orderItemId', enrollments).uniq.shift
  puts order_item_ids
  
  # do not run this until figure out why it returned 2247 pages of records
  # order_items = @@ldapi.getRecords(:order_item, { 'id' => order_item_ids }) 
  
  # enrollments.each_value do | enrollment |
  #   puts enrollment['orderItemId']
  # end
  
  return enrollments
end

def getCourseCatalog()
  courses = @@ldapi.getRecords(:course)
  
  primary_category_ids = fieldFromEntity('primaryCategoryId', courses).uniq
  categories = @@ldapi.getRecords(:knowledge_category, { 'id' => primary_category_ids })
  
  courses.each_value do | course |
    category = categories[course['primaryCategoryId']]
    course[:category] = category['_displayName_']
  end
  
  return courses.group_by{ |k, v| v[:category] }
end
