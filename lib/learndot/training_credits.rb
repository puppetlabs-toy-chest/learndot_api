class Learndot::TrainingCredits
  def initialize(api)
    @api = api
  end

  def find_accounts(email)
    api_get('/credit', {email: email})
  end

  def create_account(conditions)
    api_post('/credit', conditions)
  end

  def adjust(tc_account_id, conditions)
    api_post("credit/#{tc_account_id}/adjust", conditions)
  end

  def history(tc_account_id)
    endpoint = "/credit/#{tc_account_id}/transactions"

    page do |count|
      api_get(endpoint, {page: count})
    end
  end
end

class Learndot
  def training_credits
    Learndot::TrainingCredits.new(self.api)
  end
end
