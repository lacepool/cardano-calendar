class Events::Meetup < ::Event
  GROUPS = JSON.parse(File.read(Rails.root.join("config", "meetup_groups.json")))
end