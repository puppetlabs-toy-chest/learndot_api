class Learndot::Entity
  def initialize(api)
    @api = api
  end

  def retrieve(entity_name, conditions, options = {orderBy: 'Name', asc: true})
    entity = @api.search(entity_name, conditions, options)
  end

  def create(entity_name, conditions)
    @api.create(entity_name, conditions)
  end

  def update(entity_name, component_id, conditions={})
    @api.update(entity_name, conditions, component_id)
  end
end

class Learndot
  def entity
    Learndot::Entity.new(self.api)
  end
end
