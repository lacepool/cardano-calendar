# Support PreProd and other testnets currently unsupported in the ruby lib
class CardanoTestNet < Blockfrostruby::CardanoMainNet
  def initialize(project_id, config = {})
    super
    @url = ENV.fetch("BLOCKFROST_BASE_URL")
  end
end

class Blockfrost
  PER_PAGE = 100 # This is default, but I like being explicit

  def self.client
    if ENV.fetch("CARDANO_NETWORK") == "MAINNET"
      @client = Blockfrostruby::CardanoMainNet.new(
        ENV.fetch("BLOCKFROST_PROJECT_ID"),
        default_count_per_page: PER_PAGE
      )
    else
      @client = CardanoTestNet.new(
        ENV.fetch("BLOCKFROST_PROJECT_ID"),
        default_count_per_page: PER_PAGE
      )
    end
  end

  class ResponseError < StandardError; end
end
