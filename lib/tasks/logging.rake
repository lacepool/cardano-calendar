desc "switch rails logger to stdout"
task :verbose => [:environment] do
  Rails.logger = Rails.logger.reopen(STDOUT)
end

desc "switch rails logger log level to debug"
task :debug => [:environment, :verbose] do
  Rails.logger.level = Logger::DEBUG
end