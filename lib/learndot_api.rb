require 'httparty'
require 'json'

class LearndotAPI
  attr_writer :debug

  def initialize(token = nil, url = nil, debug = false)
    token ||= get_token

    @debug    = debug
    @base_url = url ? url : "https://learn.puppet.com/api/rest/v2"
    @headers  = {
      "TrainingRocket-Authorization"      => token,
      "Learndot Enterprise-Authorization" => token,
      "Content-Type" => "application/json",
      "Accept"       => "application/json; charset=utf-8"
    }
  end

  # Private methods
  def debug(message)
    puts message if @debug
  end

  def get_token
    token_path  = File.expand_path('~/.learndot_token')
    legacy_path = 'config/.my_token'

    path   = token_path if File.exists?(token_path)
    path ||= legacy_path if File.exists?(legacy_path)

    defined?(path) ? File.read(path).strip : (ENV['LEARNDOT_TOKEN'] || ENV['MY_TOKEN'])
  end

  def api_post(endpoint, conditions = {}, query = {})
    url = @base_url + endpoint
    debug "post to: #{url} & #{query.inspect}"

    response = HTTParty.post(url, {
      headers: @headers,
      query: query,
      body: conditions.to_json,
    })
    raise response.message unless response.code == 200

    sleep 1 # dear god learndot
    response
  end

  def api_get(endpoint, query = {})
    url = @base_url + endpoint
    debug "get to: #{url}"
    response = HTTParty.get(url, { headers: @headers, query: query })
    raise response.message unless response.code == 200

    sleep 1 # dear god learndot
    response
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

  # Call a method provided as a block until there's no more data to get back
  def page
    raise 'page() requires a block' unless block_given?

    response    = yield(1)
    num_records = response['size']

    if num_records.is_a?(Integer) && num_records > 25
      pages = (num_records / 25) + 1
      # start at 2 since first call returned first page
      for counter in 2..pages
        debug "retrieving page #{counter} of #{pages}"
        results = yield(counter)['results']
        response['results'].concat(results) if results
      end
    end

    hash_response(response)
  end

  def search(entity, conditions = {}, query = {})
    endpoint        = "/manage/#{entity}/search"
    query['asc']  ||= false
    query['or']   ||= false

    if query.include? 'page'
      api_post(endpoint, conditions, query)
    else
      page do |count|
        query['page'] = count
        api_post(endpoint, conditions, query)
      end
    end
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
    api_get('/credit', {email: email})
  end

  def create_training_credit_account(conditions)
    api_post('/credit', conditions)
  end

  def adjust_training_credits(tc_account_id, conditions)
    api_post("credit/#{tc_account_id}/adjust", conditions)
  end

  def training_credit_account_history(tc_account_id)
    endpoint = "/credit/#{tc_account_id}/transactions"

    page do |count|
      api_get(endpoint, {page: count})
    end
  end

  private :api_post, :api_get, :hash_response, :get_token, :debug, :page

end
