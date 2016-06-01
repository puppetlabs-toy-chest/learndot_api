require 'httparty'
require 'json'

class LearndotAPI
  def initialize(token = nil, url = nil)
    @base_url = url ? url : "https://learn.puppet.com/api/rest/v2"

    token = token || get_token
    @headers = {
      "TrainingRocket-Authorization" => "#{token}",
      "Content-Type" => "application/json",
      "Accept"       => "application/json; charset=utf-8"
    }
  end

  # Private methods
  def get_token
    token_path  = File.expand_path('~/.learndot_token')
    legacy_path = 'config/.my_token'

    path   = token_path if File.exists?(token_path)
    path ||= legacy_path if File.exists?(legacy_path)
    
    defined?(path) ? File.read(path).strip : (ENV['LEARNDOT_TOKEN'] || ENV['MY_TOKEN'])
  end

  def api_post(endpoint, conditions = {})
    url = @base_url + endpoint
    puts "post to: #{url}"
    HTTParty.post(url, {
      headers: @headers,
      body: conditions.to_json })
  end

  def api_get(endpoint)
    url = @base_url + endpoint
    puts "get to: #{url}"
    HTTParty.get(url, { headers: @headers })
  end

  def post_search(endpoint, conditions = {})
    response = api_post(endpoint, conditions)
    num_records = response['size']

    if num_records.is_a?(Integer) && num_records > 25
      pages = (num_records / 25) + 1
      # start at 2 since first call returned first page
      for counter in 2..pages
        puts "retrieving page #{counter} of #{pages}"
        api_post(endpoint + "page=#{counter}&", conditions)['results'].each do | result |
          response['results'] << result
        end
      end
    end

    hash_response(response)
  end

  def hash_response(response)
    result_hash = {}
    if response['size'].is_a?(Integer)
      response['results'].each do | result |
        result_hash[result['id']] = result
      end
    end
    return result_hash
  end
  # End of private methods

  def search(entity, conditions = {}, orderBy = nil)
    endpoint = "/manage/#{entity}/search?"
    endpoint << "orderBy=#{orderBy}&asc=true&" if orderBy

    post_search(endpoint, conditions)
  end

  def count(entity, conditions = {})
    endpoint = "/manage/#{entity}/search"

    num_records = api_post(endpoint, conditions)['size']
    num_records.is_a?(Integer) ? num_records : 0
  end

  # keep seperate from create to avoid accidental record creation
  def update(entity, conditions, id)
    endpoint = "/manage/#{entity}/#{id}"
    api_post(endpoint, conditions)
  end

  def create(entity, conditions)
    endpoint = "/manage/#{entity}"
    api_post(endpoint, conditions)
  end

  def find_training_credit_accounts(email)
    api_get("/credit?email=#{email}")
  end

  def create_training_credit_account(conditions)
    api_post("/credit", conditions)
  end

  def adjust_training_credits(tc_account_id, conditions)
    api_post("credit/#{tc_account_id}/adjust", conditions)
  end

  def training_credit_account_history(tc_account_id)
    response = api_get("/credit/#{tc_account_id}/transactions")
    num_records = response['size']

    if num_records.is_a?(Integer) && num_records > 25
      pages = (num_records / 25) + 1
      # start at 2 since first call returned first page
      for counter in 2..pages
        puts "retrieving page #{counter} of #{pages}"
        api_post(endpoint + "page=#{counter}&", conditions)['results'].each do | result |
          response['results'] << result
        end
      end
    end

    hash_response(response)
  end

  private :api_post, :api_get, :post_search, :hash_response, :get_token

end
