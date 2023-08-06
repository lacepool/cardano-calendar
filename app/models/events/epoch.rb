class Events::Epoch < OpenStruct
  SHELLY_UNIX = 1596491091
  SHELLY_SLOT = 4924800
  SHELLEY_EPOCH = 209
  SLOTS_PER_EPOCH = 432000

  def self.slot_from_timestamp(timestamp)
    timestamp - SHELLY_UNIX + SHELLY_SLOT
  end

  def self.epoch_from_slot(slot)
    SHELLEY_EPOCH + ((slot - SHELLY_SLOT) / SLOTS_PER_EPOCH)
  end

  def self.epoch_from_timestamp(timestamp)
    epoch_from_slot(
      slot_from_timestamp(timestamp)
    )
  end

  def self.timestamp_from_epoch(epoch)
    seconds = (epoch - SHELLEY_EPOCH) * SLOTS_PER_EPOCH

    Time.at(SHELLY_UNIX + seconds).in_time_zone
  end

  def self.all(between: Time.at(SHELLY_UNIX).utc..Time.current.utc)
    Montrose.every(SLOTS_PER_EPOCH.seconds, between: between).events.map do |date|
      new.tap do |e|
        e.epoch_number = epoch_from_timestamp(date.to_i)
        e.name = "Epoch #{e.epoch_number}"
        e.start_time = timestamp_from_epoch(e.epoch_number)
        e.end_time = e.start_time + SLOTS_PER_EPOCH.seconds
        e.description = "#{e.epoch_name} from #{e.start_time} to #{e.end_time}"
      end
    end
  end
end