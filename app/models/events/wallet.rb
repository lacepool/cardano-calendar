class Events::Wallet < ::Event
  def self.filters
    {
      "delegations" => {
        "filter_label" => "Pool Delegations",
        "filter_default_value" => "on"
      }
    }
  end
end