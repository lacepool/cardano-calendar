class Events::Software < ::Event
  GITHUB_REPOS = JSON.parse(File.read(Rails.root.join("config", "github_repos.json")))

  GITHUB_REPOS.each do |name|
    filter category: "Open Source Software", param: name.parameterize, label: name, default: "off"
  end

  def self.count_by_filter(filter_param, between)
    where("extras->'filter_param' ? :param", param: filter_param).between(between).count
  end

  def self.release_exists?(repo, published_at)
    where("extras->'repo_name' ? :repo", repo: repo).where(start_time: published_at).exists?
  end

  def self.fetch_releases
    client = Octokit::Client.new(
      login: ENV['GITHUB_USERNAME'],
      password: ENV['GITHUB_TOKEN']
    )

    # last_created = self.order("created_at DESC").pick(:start_time)

    GITHUB_REPOS.each do |repo_name|
      client.repository(repo_name)
      repo = client.last_response.data

      client.releases(repo_name, per_page: 100)
      releases = client.last_response.data

      releases.each do |release|
        next if release_exists?(repo_name, release.published_at)

        if release.body.present?
          client.markdown(release.body, mode: "gfm", context: repo_name)
          description = client.last_response.data
        end

        new.tap do |event|
          event.name = "#{repo.name} – #{release.tag_name}"
          event.description = "<p><a href='#{release.html_url}' target='_blank' class='btn btn-secondary'><i class='bi bi-box-arrow-up-right me-2'></i> GitHub</a></p>#{description}"
          event.category = :software_releases
          event.start_time = release.published_at
          event.end_time = event.start_time
          event.extras = { repo_name: repo_name, filter_param: repo_name.parameterize, tag: release.tag_name, url: release.html_url, license: repo.license, topics: repo.topics, homepage: repo.homepage  }
          event.save
        end
      end
    end

  end

  def repo_name
    extras['repo_name']
  end
end
