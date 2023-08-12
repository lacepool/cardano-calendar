class Events::LeaderlogCheck < OpenStruct
  def self.all(between: Time.at(Epoch::SHELLY_UNIX).utc..Time.current.utc)
    Montrose.every(Epoch::SLOTS_PER_EPOCH.seconds, between: Epoch::epoch_range_from_time_range(between)).events.map do |date|
      new.tap do |e|
        e.current_epoch = Epoch::epoch_from_timestamp(date.to_i)
        e.for_epoch = e.current_epoch + 1
        e.name = "Leaderlogs for epoch #{e.for_epoch}"
        e.description = "As a stake pool operator, it is possible to run queries to determine whether your pool is scheduled to mint blocks. Leaderlog information for the next epoch is available within 1.5 days from the end of the current epoch."
        e.categories = ["Stake Pool Operator"]
        e.start_time = Epoch::timestamp_from_epoch(e.current_epoch) + 3.5.days
        e.end_time = e.start_time
      end
    end
  end

  def time_range
    start_time..end_time
  end

  def id
    Digest::MD5.hexdigest(name)
  end
end