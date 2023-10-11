namespace :amas do
  desc "Sync AMAs"
  task sync: :environment do
    Events::Ama.create_from_hosksaid
  end
end
