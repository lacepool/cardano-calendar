require 'gqli'
require 'meetup_sync'

namespace :meetups do
  desc "Pull and store cardano events from meetup.com"
  task sync: :environment do
    MeetupSync.new.sync
  end
end