namespace :software do
  desc "Sync software releases"
  task sync: :environment do
    Events::Software.fetch_releases
  end
end