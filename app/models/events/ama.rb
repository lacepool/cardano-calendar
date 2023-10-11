class Events::Ama < ::Event
  # scope :by_presenter, ->(names) { where("extras->'presenter' ?| array[:presenter]", presenter: [names].flatten) }

  filter category: "YouTube", param: "hosksaid", label: "AMA with Charles Hoskinson", default: "on"
  filter category: "Twitter Spaces", param: "hosksaid", label: "AMA with Charles Hoskinson", default: "on"

  def self.count_by_filter(filter, between)
    by_category(filter).between(between).count
  end

  def self.add_summaries_from_hosksaid(ama)
    conn = Faraday.new(url: "https://www.hosksaid.com") { |f| f.response :json }
    response = conn.get("/api/video_summaries/#{ama.extras['external_id']}")
    raise if response.status > 200

    summary = response.body

    description = summary["sections"].map {|s| "<h5>#{s['topic']}</h5><p>#{s['text']}</p>" }.join
    footer_links = [
      { label: "Summary by hosksaid.com", url: summary["summary_link"] },
      { label: "Watch video on YouTube", url: summary["video_url"] }
    ]
    extras = ama.extras
    extras.merge!(
      {
        "footer_links" => footer_links,
        "summarized" => true
      }
    )

    ama.update!(
      description: description,
      extras: extras
    )
  end

  def self.create_from_hosksaid
    conn = Faraday.new(url: "https://www.hosksaid.com") { |f| f.response :json }
    response = conn.get("/api/video_index")

    response.body.each do |video|
      ama = by_category("hosksaid").where("extras->'external_id' ? :id", id: video["id"]).first

      if ama
        # add summary in case it is now available
        if !ama.extras["summarized"] && video["summarized"]
          add_summaries_from_hosksaid(ama)
        else
          next
        end
      end

      # There is no time available.
      # Making it midday UTC to not change the day for all countries behind UTC.
      start_time = Time.parse(video["posted_date"]).utc + 12.hours
      presenter = "Charles Hoskinson"

      ama = new.tap do |event|
        event.category = :hosksaid
        event.name = "#{presenter} - #{video['title']}"
        event.start_time = start_time
        event.end_time = start_time
        event.time_format = "date"
        event.extras = { "presenter" => presenter, "external_id" => video["id"], "summarized" => video["summarized"] }

        event.save!
      end

      add_summaries_from_hosksaid(ama) if video["summarized"]
    end
  end
end
