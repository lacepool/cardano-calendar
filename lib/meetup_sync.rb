class MeetupSync
  Client = GQLi::Client.new("https://api.meetup.com/gql", validate_query: false)

  def past_events_by_group_query(group)
    GQLi::DSL.query {
      groupByUrlname(urlname: group) {
        id
        urlname
        city

        pastEvents(input: {last: 100}) {
          count
          edges {
            node {
              id
              title
              description
              dateTime
              endTime
              eventUrl
            }
          }
        }
      }
    }
  end

  def upcoming_events_by_group_query(group)
    GQLi::DSL.query {
      groupByUrlname(urlname: group) {
        id
        urlname
        city

        upcomingEvents(input: {first: 100}) {
          count
          edges {
            node {
              id
              title
              description
              dateTime
              endTime
              eventUrl
            }
          }
        }
      }
    }
  end

  def edges_from_results(past:, upcoming:)
    past.data.groupByUrlname.pastEvents.edges.concat(
      upcoming.data.groupByUrlname.upcomingEvents.edges
    )
  end

  def sync(groups: Events::Meetup::GROUPS)
    groups.values.each do |group|
      past_result = Client.execute(past_events_by_group_query(group))
      upcoming_result = Client.execute(upcoming_events_by_group_query(group))

      edges = edges_from_results(past: past_result, upcoming: upcoming_result)

      meetup_ids = edges.map {|e| e.node.id }
      existing_meetup_ids = Events::Meetup.select(:extras).where("extras->'meetup_event_id' ?| array[:ids]", ids: meetup_ids).map { |e| e.extras["meetup_event_id"] }

      group_data = past_result.data.groupByUrlname
      group_id = group_data.id
      city = group_data.city

      edges.each do |e|
        next if existing_meetup_ids.include?(e.node.id)

        Events::Meetup.new.tap do |event|
          event.name = e.node.title
          event.start_time = e.node.dateTime
          event.end_time = e.node.endTime
          event.description = e.node.description
          event.category = :meetup
          event.extras = { meetup_group_id: group_id, meetup_event_id: e.node.id, city: city, group_urlname: group }

          event.save
        end
      end
    end
  end
end