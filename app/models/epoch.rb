class Epoch < OpenStruct
  SHELLY_UNIX = 1596491091
  SHELLY_SLOT = 4924800
  SHELLEY_EPOCH = 209
  SLOTS_PER_EPOCH = 432000

  def self.slot_from_timestamp(timestamp)
    (timestamp - SHELLY_UNIX + SHELLY_SLOT).to_i
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

  # extend the given time range by the time from the beginning of the range
  # and the start of the first epoch within that range to never cut off any epochs.
  def self.epoch_range_from_time_range(time_range)
    first_epoch = epoch_from_timestamp(time_range.first.to_i)
    last_epoch = epoch_from_timestamp(time_range.last.to_i)

    timestamp_from_epoch(first_epoch)..timestamp_from_epoch(last_epoch + 1)
  end

  def self.all(between: Time.at(SHELLY_UNIX).utc..Time.current.utc, with_events: [])
    Montrose.every(SLOTS_PER_EPOCH.seconds, between: epoch_range_from_time_range(between)).events.map do |date|
      new.tap do |e|
        e.epoch_number = epoch_from_timestamp(date.to_i)
        e.name = "Epoch #{e.epoch_number}"
        e.start_time = timestamp_from_epoch(e.epoch_number)
        e.end_time = e.start_time + (SLOTS_PER_EPOCH-1).seconds
        e.start_slot = slot_from_timestamp(e.start_time)
        e.end_slot = slot_from_timestamp(e.end_time)

        e.events = with_events.select do |event|
          (e.start_time..e.end_time).overlaps?(event[:start_time]..event[:end_time])
        end
      end
    end
  end

  def slot_range
    start_slot..end_slot
  end

  def id
    Digest::MD5.hexdigest(name)
  end

  def current?
    current_slot = self.class.slot_from_timestamp(Time.current.to_i)
    slot_range.include?(current_slot)
  end
end