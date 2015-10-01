require 'httparty'
require 'json'

class LearndotAPI
	
	def getToken()
		token = ENV["MY_TOKEN"]
	
		token_path = "config/.my_token"
		if File.exists?(token_path)
			token = File.read(token_path).strip
		end  
		
		return token
	end
	
	def callAPI(entity, conditions = {}, page = 1, search = true)
		token = getToken()
		url = "https://learn.puppetlabs.com/api/rest/v2/manage/#{entity}"
	
		# url   = "https://puppetlabs-staging.trainingrocket.com/api/rest/v2/manage/#{entity}"
	
		headers = { "TrainingRocket-Authorization" => "#{token}", 
					"Content-Type" 				   => "application/json",
					"Accept" 					   => "application/json; charset=utf-8" }
			
		# default to search true to prevent accidental record creation
		if search
			url = url + "/search"
		end
		url = url + '?'
		if page > 1
			url = url + "page=#{page}&"
		end	
		course_entities = [:course_event, :private_course_event, :public_course_event]	
		if course_entities.include?(entity)
			url = url + "orderBy=startTime&asc=true&"
		end
		
		puts "call to: " + url 
		
		return HTTParty.post(url, {
			headers: headers,
			body: conditions.to_json })	
	end
	
	def getRecords(entity, conditions = {})
		response = callAPI(entity, conditions)
		num_records = response['size']
		
		if num_records.is_a?(Integer)
			if num_records > 25 && num_records < 500
				pages = (num_records / 25) + 1
				# start at 2 since first call returned first page
				for counter in 2..pages
					puts "retrieving page #{counter} of #{pages}"
					results = callAPI(entity, conditions, counter)
					
					results['results'].each do | result |
						response['results'] << result
					end 
				end
			end		
			
			result_hash = {}			
			response['results'].each do | result |
				result_hash[result['id']] = result
			end
		end
		
		return result_hash
	end
	
	def getRecordCount(entity, conditions = {})
		num_records = callAPI(entity, conditions)['size']
		return num_records.is_a?(Integer) ? num_records : 'no records found'
	end

end