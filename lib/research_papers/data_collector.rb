require 'research_papers/scraper'

module ResearchPapers
  class DataCollector
    attr_reader :papers

    BASE_URLS = {
      "eprint.iacr.org" => URI("https://eprint.iacr.org"),
      "api.zotero.org"  => URI("https://api.zotero.org"),
      "arxiv.org"       => URI("https://export.arxiv.org"),
    }

    def self.run
      new.tap do |collector|
        scraper = collector.scrape
        collector.enhance_data(scraper.results)
      end
    end

    def scrape
      Scraper.run
    end

    def enhance_data(papers)
      papers.each do |paper|
        Rails.logger.info "Enhancing data from #{paper.platform} for #{paper.url}"

        @current_paper = paper

        Rails.logger.tagged(paper.platform) do
          case paper.platform
          when "eprint.iacr.org" then from_eprint
          when "api.zotero.org" then from_zotero
          when "arxiv.org" then from_arxiv
          when "link.springer.com" then from_springer
          when "dl.acm.org" then from_crossref # acm doesn't have an API
          when "doi.acm.org" then from_crossref # acm doesn't have an API
          when "dx.doi.org" then from_crossref # doi doesn't have an API
          when "www.mdpi.com" then from_mdpi # web scraping
          when "drops.dagstuhl.de" then from_dagstuhl # web sraping
          else
            cannot_process && next
          end
        end
      end
    end

    def cannot_process(error=nil)
      Rails.logger.error "Can not process #{@current_paper.pdf_url} – Platform #{@current_paper.platform} probably does not provide an API, nor can we find a date elsewhere. Consider creating this paper event manually."
      Rails.logger.error error if error
    end

    def from_springer
      @current_paper.identifier = @current_paper.pdf_url.to_s.split("pdf/").last.split(".pdf").first

      params = {q: "doi:#{@current_paper.identifier}", api_key: ENV.fetch("SPRINGERNATURE_API_KEY") }
      conn = Faraday.new(url: "https://api.springernature.com") { |f| f.response :json }

      response = conn.get("/meta/v2/json", params)
      r= response.body["records"].first # can only be one since we queried for a doi

      @current_paper.created_at = DateTime.parse(r["onlineDate"]).utc

      create_event
    rescue StandardError => e
      cannot_process(e)
    end

    def from_dagstuhl
      url = @current_paper.pdf_url.to_s.split("/pdf").first

      scraper = Mechanize.new { |m| m.user_agent = Rails.application.class.module_parent }
      doc = scraper.get(url)

      published_at_str = doc.css("span[itemprop='datePublished']")&.text
      @current_paper.created_at = DateTime.parse(published_at_str)

      create_event
    rescue StandardError => e
      cannot_process(e)
    end

    def from_mdpi
      scraper = Mechanize.new { |m| m.user_agent = Rails.application.class.module_parent }

      doc = scraper.get(@current_paper.pdf_url)
      published_el = doc.css("div.pubhistory > span").detect { |span| span.text.scan(/published/i).any? }
      published_at_str = published_el.text.split(":").last.strip
      @current_paper.created_at = DateTime.parse(published_at_str)

      create_event
    rescue StandardError => e
      cannot_process(e)
    end

    def from_eprint
      @current_paper.identifier = current_eprint_identifier

      params = { verb: "GetRecord", metadataPrefix: "oai_dc", identifier: @current_paper.identifier }
      response = faraday_connection(response_format: :xml).get("/oai", params)
      xml = response.body

      if xml.dig("header", "status") == "deleted"
        Rails.logger.info "Paper is deleted: #{@current_paper.url}"
        return
      end

      record = xml.dig("OAI_PMH", "GetRecord", "record")

      unless record
        Rails.logger.info "Paper not found: #{@current_paper.url}"
        return
      end

      dates = record.dig("metadata", "dc", "date")

      Rails.logger.info "Paper has #{dates.size} updates: #{@current_paper.url}" if dates.size > 1

      @current_paper.created_at = DateTime.parse(dates.delete_at(0)).utc

      create_event

    rescue StandardError => e
      cannot_process(e)
    end

    def current_eprint_identifier
      [
        "oai",
        @current_paper.pdf_url.host,
        @current_paper.pdf_url.path.split(".")[0].sub("/", "")
      ].join(":")
    end

    def from_zotero
      group_id, item_key = @current_paper.pdf_url.path.scan(/groups\/(\d*)\/items\/(\w*)\//).flatten
      @current_paper.identifier = "/groups/#{group_id}/items/#{item_key}"

      headers = { "Zotero-API-Version": "3", "Zotero-API-Key": "PnpP8O1NApZMMF0LVNh7I4I5" }
      response = faraday_connection(headers: headers).get(@current_paper.identifier)

      json = response.body

      @current_paper.created_at = DateTime.parse(json.dig("data", "dateAdded"))

      create_event

    rescue StandardError => e
      cannot_process(e)
    end

    def from_arxiv
      @current_paper.identifier = @current_paper.pdf_url.path.split("/").last.scan(/[^\D]\d*.?\d*[^\D]/).first
      params = { search_query: ["id", @current_paper.identifier].join(":") }
      response = faraday_connection(response_format: :xml).get("/api/query", params)

      @current_paper.created_at = DateTime.parse(response.body.dig("feed", "entry", "published"))

      create_event

    rescue StandardError => e
      cannot_process(e)
    end

    def from_crossref
      @current_paper.identifier = @current_paper.pdf_url.path.split("pdf/").last

      response = Serrano.works(ids: @current_paper.identifier)

      response = response.first # wtf?

      date_parts = response.dig("message", "published-print", "date-parts")&.first ||
        response.dig("message", "issued", "date-parts")&.first ||
        response.dig("message", "event", "start", "date-parts")&.first ||
        []

      unless date_parts.size == 3
        Rails.logger.error "Date #{date_parts.inspect} is not sufficient to continue with #{@current_paper.url}"
        return
      end

      @current_paper.created_at = DateTime.parse(date_parts.join("-")).utc

      create_event

    rescue StandardError => e
      cannot_process(e)
    end

    def faraday_connection(headers: {}, response_format: :json)
      Faraday.new(
        url: BASE_URLS.fetch(@current_paper.platform),
        headers: headers
      ) do |builder|
        builder.response response_format
      end
    end

    def create_event
      if Events::ResearchPaper.where("extras->'identifier' ? :id", id: @current_paper.identifier).exists?
        Rails.logger.info "Record exists. Skipping."
        return
      end

      Rails.logger.info "Creating Event for: #{@current_paper.url}"

      extras = {
        identifier: @current_paper.identifier,
        authors: @current_paper.authors,
        website: @current_paper.url,
        pdf_url: @current_paper.pdf_url,
        platform: @current_paper.platform
      }

      Events::ResearchPaper.new.tap do |event|
        event.name = @current_paper.title
        event.description = @current_paper.abstract
        event.category = :research_papers
        event.start_time = @current_paper.created_at
        event.end_time = event.start_time
        event.extras = extras
        event.time_format = "date"

        event.save!
      end
    end
  end
end