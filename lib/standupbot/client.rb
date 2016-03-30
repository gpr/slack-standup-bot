require_relative 'sync'

module Standupbot

  require 'standupbot/logger'

  class Client

    include Standupbot::Logger

    # @param [String] channel_id The slack channel id.
    def initialize(channel_id)
      @client       = ::Slack::Web::Client.new(token: Setting.first.try(:api_token))
      @channel_sync = Sync.new(channel_id)
    end

    # @override
    def valid?
      @channel_sync.valid?
    end

    # @override
    def errors
      @channel_sync.errors
    end

    # Initiaties a new realtime slack client to do the standup.
    #
    def start!
      logger.debug("Starting realtime session")
      realtime = ::Slack::RealTime::Client.new(token: Setting.first.try(:api_token))
      channel  = @channel_sync.create!

      if channel.nil? || channel.active?
        logger.error("Unable to get active channel")
        return
      end

      channel.start!

      realtime.on :hello do
        logger.debug("Hello received")
        if channel.complete?
          logger.debug("Standup already completed")
          channel.message('Today\'s standup is already completed.')
          realtime.stop!
        elsif channel.today_standups.any?
          logger.info("Standup already up")
          channel.message('Standup is up again!!! Here you have the previous status of the standup:')

          IncomingMessage::Status.new({}, channel.today_standups.first).execute
        else
          logger.info("Standup ready to start")
          channel.message('Welcome to standup! Type "-Start" to get started.')
        end
      end

      realtime.on :message do |data|
        if data['channel'] == channel.slack_id && data['text'].present?
          message = IncomingMessage.new(data)

          message.execute

          realtime.stop! if message.standup_finished?
        end
      end

      realtime.on :close do
        channel.stop! if channel.active?
      end

      # HOTFIX: Heroku sends a SIGTERM signal when shutting down a node, this is the only way
      #   I found to change the state of the channel in that edge case.
      at_exit do
        channel.stop! if channel.active?
        channel.message(I18n.t('incoming_message.bot_died')) unless channel.complete?
      end

      realtime.start_async

    rescue => exception
      logger.error exception
      channel.stop! if channel.try(:active?)
    end

  end
end
