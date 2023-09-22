require 'mechanize'

module ResearchPapers
  Paper = Struct.new(:title, :abstract, :authors, :url, :pdf_url, :platform, :created_at, :identifier)

  class Scraper
    attr_reader :results, :existing


    @@conn = Mechanize.new { |m| m.user_agent = Rails.application.class.module_parent }
    @@base_url = "https://iohk.io/en/research/library".freeze

    def initialize
      @results = []
      @existing = Events::ResearchPaper.pluck(Arel.sql("extras->'website'"))
    end

    def self.run
      new.tap do |scraper|
        scraper.paper_links.each do |link|
          if scraper.existing.include?(@@conn.resolve(link.attribute("href").value).to_s)
            Rails.logger.info "Skipping existing"
            next
          end

          paper_page = @@conn.click(link)

          Rails.logger.info "Scraping #{paper_page.uri}"
          scraper.scrape(paper_page)
        end
      end
    end

    def scrape(paper_page)
      title = paper_page.css("h1 > a").text
      download_url = URI(paper_page.css("h1 > a").attribute("href").value)
      abstract = paper_page.css("main > div > div > div p").to_html
      authors = paper_page.css("h1 + div > a").map {|a| [a.text, @@conn.resolve(a.attribute("href").value)] }
      platform = download_url.hostname

      @current_result = Paper.new(title, abstract, authors, paper_page.uri, download_url, platform)
      @results << @current_result
    end

    def library_page
      @@conn.get(@@base_url)
    end

    def paper_links
      library_page.css("h3 > a")
    end
  end
end