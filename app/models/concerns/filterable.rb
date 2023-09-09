module Filterable
  extend ActiveSupport::Concern

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
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

  def filter_param
    extras.try(:[], "filter_param")
  end

  def filter_default
    EventFilter.default_for(filter_param)
  end
end