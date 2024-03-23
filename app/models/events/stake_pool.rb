class Events::StakePool < Event
  extend ActionView::Helpers::NumberHelper

  scope :by_poolid, ->(poolid) { where("extras->'poolid' ? :poolid", poolid: poolid) }

  # ::StakePool.all.each do |pool|
  #   filter category: "Stake Pools", param: pool.poolid, label: pool.full_name, default: "off"
  # end

  def self.count_by_filter(filter, between)
    where("extras->'poolid' ? :poolid", poolid: filter).between(between).count
  end

  def self.create_anniversary_events
    events_until = DateTime.current.utc + 1.month

    ::StakePool.all.each do |pool|
      #
    end
  end

  # def self.create_registrations
  #   ::StakePool.all.each do |pool|
  #     # only the very first is probably the initial registration
  #     response = Blockfrost.client.get_pool_updates(pool.poolid)
  #     response.dig(:body).each do |u|
  #       puts u

  #       if u[:action] == "registered"
  #         puts "create pool registration #{pool.ticker}"

  #         # request tx to get timestamp:
  #         response = Blockfrost.client.get_specific_transaction(u["tx_hash"])

  #         response.dig(:body)[:pool_update_count]

  #         new.tap do |event|

  #           event.name = "Stake Pool #{pool.ticker} registered"
  #           event.start_time = response.dig(:body)["block_time"]
  #           event.end_time = event.start_time
  #           event.time_format = "date"
  #         end
  #       end
  #     end
  #   end
  # end

  def self.create_update_events
    koios_client = KoiosRuby::Client.new

    ::StakePool.all.each do |pool|
      latest_existing_time = by_poolid(pool.poolid).order("start_time DESC").pick(:start_time)

      # get all updates starting with the oldest (register)
      response = koios_client.pool_updates(
        pool.poolid,
        fields: relevant_keys_for_updates,
        order: "block_time.asc"
      )

      previous_update = nil
      updates = response.parsed

      updates.each_with_index do |u, index|
        break if u["block_time"] < latest_existing_time.to_i

        # koios has a bug resulting in not including deregistrations in pool updates
        # so at the moment we can not collect these. Once koios returns them (supposedly in api v1)
        # we need to detect them here as well.
        # https://github.com/cardano-community/koios-artifacts/issues/240
        if index > 0
          category = "pool_update"
        else
          category = "pool_registration"
        end

        update_type = category.sub('pool_', '')
        # active_at_text = "The #{update_type} will take effect in epoch #{u['active_epoch_no']}"

        unless metadata = u['meta_json']
          # metadata is not stored on chain, therefore not yet available at registration tx or early updates
          # We check next updates until we find the first available metadata
          pointer = index + 1

          until metadata || pointer > updates.size
            metadata = updates[pointer].dig('meta_json')
            pointer += 1
          end
        end

        current_update = u.slice(*relevant_keys_for_update_diffs)
        previous_update = updates[[0, index-1].max].slice(*relevant_keys_for_update_diffs)

        hash_diff = HashDiff::Comparison.new(previous_update, current_update)
        diff = hash_diff.diff

        next if diff.blank? && category == "pool_update"

        left_diff = hash_diff.left_diff
        right_diff = hash_diff.right_diff

        homepage = metadata['homepage']
        ticker = metadata['ticker']
        pool_name = metadata['name']
        desc = metadata['description']

        if left_diff.dig('meta_json', 'description') != desc
          description = "<span class='prev'>#{left_diff.dig('meta_json', 'description')}<span><span class='current'>#{desc}</span>"
        else
          description = "<span class='current'>#{desc}</span>"
        end

        description_row = "<tr><th>Description</th><td>#{description}</td></tr>" if desc

        full_name = "[#{metadata['ticker']}] #{metadata['name']}"

        if left_diff.dig('meta_json', 'ticker') != ticker || left_diff.dig('meta_json', 'name') != pool_name
          prev_name = "[#{left_diff.dig('meta_json', 'ticker')}] #{left_diff.dig('meta_json', 'name')}"
          full_name = "<span class='prev'>#{prev_name}<span><span class='current'>#{full_name}</span>"
        else
          full_name = "<span class='current'>#{full_name}</span>"
        end

        pledge = formatted_pledge(right_diff['pledge'])

        if diff["pledge"]
          pledge = "<span class='prev'>#{formatted_pledge(left_diff['pledge'])}<span><span class='current'>#{pledge}</span>"
        else
          pledge = "<span class='current'>#{pledge}</span>"
        end

        fixed_fee = formatted_fixed_fee(right_diff['fixed_fee'])

        if diff["fixed_fee"]
          fixed_fee = "<span class='prev'>#{formatted_fixed_fee(left_diff['fixed_fee'])}<span><span class='current'>#{fixed_fee}</span>"
        else
          fixed_fee = "<span class='current'>#{fixed_fee}</span>"
        end

        margin = formatted_margin(right_diff['margin'])

        if diff["margin"]
          margin = "<span class='prev'>#{formatted_margin(left_diff['margin'])}<span><span class='current'>#{margin}</span>"
        else
          margin = "<span class='current'>#{margin}</span>"
        end

        description = <<~MULTILINE
          <table class="pool_details">
            <tbody>
              <tr>
                <th>Name</th>
                <td>#{full_name}</td>
              </tr>
              #{description_row}
              <tr>
                <th>Pledge</th><td>#{pledge}</td>
              </tr>
              <tr>
                <th class="info">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="currentColor" class="bi bi-info-circle-fill" viewBox="0 0 16 16">
                    <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16zm.93-9.412-1 4.705c-.07.34.029.533.304.533.194 0 .487-.07.686-.246l-.088.416c-.287.346-.92.598-1.465.598-.703 0-1.002-.422-.808-1.319l.738-3.468c.064-.293.006-.399-.287-.47l-.451-.081.082-.381 2.29-.287zM8 5.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2z"/>
                  </svg>
                </th>
                <td>
                  <small>
                    <p>Stake pool operators can optionally pledge some or all of their stake to their pool to make their pool more attractive.</p>
                  </small>
                </td>
              </tr>
              <tr>
                <th>Fixed fee</th>
                <td>#{fixed_fee}</td>
              </tr>
              <tr>
                <th>Margin fee</th>
                <td>#{margin}</td>
              </tr>
              <tr>
                <th class="info">
                  <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="currentColor" class="bi bi-info-circle-fill" viewBox="0 0 16 16">
                    <path d="M8 16A8 8 0 1 0 8 0a8 8 0 0 0 0 16zm.93-9.412-1 4.705c-.07.34.029.533.304.533.194 0 .487-.07.686-.246l-.088.416c-.287.346-.92.598-1.465.598-.703 0-1.002-.422-.808-1.319l.738-3.468c.064-.293.006-.399-.287-.47l-.451-.081.082-.381 2.29-.287zM8 5.5a1 1 0 1 1 0-2 1 1 0 0 1 0 2z"/>
                  </svg>
                </th>
                <td>
                  <small>
                    <p>You are not charged these fees to stake your ADA.</p>
                    <p>
                      From the total amount of ADA that a pool of delegators is awarded,
                      the stake pool operator (SPO) first takes the fixed fee.
                      The SPO is then also awarded the margin fee that they have set,
                      this is a percentage of the ADA that remains after the fixed fee is taken.
                      The ADA that is left after these fees is then shared between all delegators
                      in the stake pool, weighted towards how much ADA they have delegated.
                    <p>
                    <p>All of this happens automatically by the protocol, and is therefore trustless.</p>
                  </small>
                </td>
              </tr>
            </tbody>
          </table>
        MULTILINE

        new.tap do |event|
          event.category = category
          event.description = description
          event.name = "Stake Pool #{update_type} [#{ticker}]"
          event.start_time = Time.at(u["block_time"]).utc
          event.end_time = event.start_time
          event.extras = u.merge(poolid: pool.poolid)

          event.save!
        end
      end

      if updates.last["meta_json"]
        pool.update!(
          ticker: updates.last.dig("meta_json", "ticker"),
          name: updates.last.dig("meta_json", "name"),
          homepage: updates.last.dig("meta_json", "homepage")
        )
      end
    end
  end

  def self.formatted_margin(margin)
    "#{margin.to_f * 100}%"
  end

  def self.formatted_fixed_fee(fixed_fee)
    number_to_currency((fixed_fee.to_i / 1e6).to_i, unit: "ADA", format: "%n %u", strip_insignificant_zeros: true)
  end

  def self.formatted_pledge(pledge)
    number_to_currency(number_to_human(pledge.to_i / 1e6), unit: "ADA", format: "%n %u")
  end

  def self.relevant_keys_for_update_diffs
    ["margin", "fixed_cost", "pledge", "meta_json"]
  end

  def self.relevant_keys_for_updates
    relevant_keys_for_update_diffs + ["tx_hash", "block_time", "active_epoch_no", "pool_status"]
  end
end
