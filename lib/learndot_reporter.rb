$LOAD_PATH.unshift File.dirname(__FILE__)
require 'sinatra'
require 'json'
require 'learndot_api'
require 'models'

configure do
  set :root, File.join(File.dirname(__FILE__), '..')
  set :views, Proc.new { File.join(root, 'views') }
end

get '/' do
  @title = :Dashboard
    
  from_date = Time.new.strftime('%Y-%m-%d %H:%M:%S')
  to_date = (Time.new + (2*7*24*60*60)).strftime('%Y-%m-%d %H:%M:%S') # because adding seconds is less work than getting another gem 
  
  conditions = {
    'startTime' => [from_date, to_date],
    'status'    => ['CONFIRMED', 'TENTATIVE'],
  }
      
  @classes =  getClasses(conditions)
  
  @total_enrollments = 0
  @classes.each_value do | klass |
    @total_enrollments = @total_enrollments + klass[:enrollment_count]
  end
  
  @today = Time.new.strftime('%B %d, %Y')
    
  erb :dashboard
end

get '/enrollments' do
  @title = :Enrollments
  
  from_date = (Time.new - (24*60*60)).strftime('%Y-%m-%d %H:%M:%S') #last 24 hours
  to_date = Time.new.strftime('%Y-%m-%d %H:%M:%S')
  
  conditions = { 
    'modified'    => [from_date, to_date],
    'componentId' => ['1', '2', '3', '5', '44', '45', '160', '195', '196', '197', '201'] 
  }
  
  @enrollments = getEnrollments(conditions).to_json
  erb :enrollments
end

get '/test' do
  conditions = {
    'id' => ['38']
  }

  @results = callAPI(:contact, conditions)

  erb :json_view
end
