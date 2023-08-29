class Events::Meetup < ::Event
  GROUPS = JSON.parse(File.read(Rails.root.join("config", "meetup_groups.json")))

  GROUPS.each do |name, slug|
    filter category: "Meetups", param: slug, label: name, default: "off"
  end
end