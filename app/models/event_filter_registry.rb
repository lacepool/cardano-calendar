class EventFilterRegistry
  def self.register(klass:, category:, param:, label:, default:, dependencies: [])
    registered[category] = {} if registered[category].nil?
    registered[category][param] = {
      param: param,
      label: label,
      default: default,
      dependencies: dependencies,
      class: klass
    }
  end

  def self.registered
    @registered ||= {}
  end
end