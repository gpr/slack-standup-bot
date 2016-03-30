module Standupbot
  mattr_accessor :logger

  module Logger
    def logger
      Standupbot.logger
    end
  end
end