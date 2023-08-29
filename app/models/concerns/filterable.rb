module Filterable
  extend ActiveSupport::Concern

  def filter(category:, param:, label:, default:, dependencies: [])
    filter = {
      klass: self.name,
      category: category,
      param: param,
      label: label,
      default: default,
      dependencies: dependencies
    }

    ::EventFilterRegistry.register(**filter)
  end
end