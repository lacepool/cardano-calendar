class Events::ResearchPaper < ::Event
  Events::ResearchPaper.select("date_part('year', start_time)::Int AS year").group("year").order("year DESC").each do |paper|
    filter category: "Research Papers", param: "research-#{paper.year}", label: "Published in #{paper.year}", default: "on"
  end

  def self.count_by_filter(filter, between)
    year = filter.split("research-").last
    where("date_part('year', start_time)::varchar(255) = ?", year).between(between).count
  end
end