class Events::Meetup < ::Event
  GROUPS = JSON.parse(File.read(Rails.root.join("config", "meetup_groups.json")))

  GROUPS.each do |name, slug|
    filter category: "Meetups", param: slug, label: name, default: "off"
  end

  def self.count_by_filter(group_urlname, between)
    where("extras->'group_urlname' ? :group", group: group_urlname).between(between).count
  end
end