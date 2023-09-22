class Events::ResearchPaper < ::Event
  Events::ResearchPaper.select("date_part('year', start_time)::Int AS year").group("year").order("year DESC").each do |paper|
    filter category: "Research Papers", param: "research-#{paper.year}", label: "Published in #{paper.year}", default: "on"
  end
end