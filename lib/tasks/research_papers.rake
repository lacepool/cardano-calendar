require 'research_papers/scraper'
require 'research_papers/data_collector'

namespace :research_papers do
  desc "Sync Research Paper Dates"
  task sync: :environment do
    ResearchPapers::DataCollector.run
  end
end