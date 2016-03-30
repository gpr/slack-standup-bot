
require 'standupbot/logger'

Standupbot.logger = Log4r::Logger['lib']

def time_in_ms(start, finish)
  return ( ((finish - start).to_f * 100000).round / 100.0 ).to_s
end

ActiveSupport::Notifications.subscribe("process_action.action_controller") do |name, start, finish, id, payload|

  logger = Log4r::Logger['rails']

  controller_format = "@method @status @path @durationms"

  duration = time_in_ms(start, finish)

  if !payload[:exception].nil? || payload[:status] == 500
    logger.error {
      message = controller_format.clone
      message.sub!(/@status/, payload[:status].to_s)
      message.sub!(/@method/, payload[:method])
      message.sub!(/@path/, payload[:path])
      message.sub!(/@duration/, duration)
      message += " EXCEPTION: #{payload[:exception]}"
      message
    }
  end

  if payload[:status] != 200 && payload[:status] != 500 && !payload[:exception].nil?
    logger.warn {
      message = controller_format.clone
      message.sub!(/@status/, payload[:status].to_s)
      message.sub!(/@method/, payload[:method])
      message.sub!(/@path/, payload[:path])
      message.sub!(/@duration/, duration)
      message += " EXCEPTION: #{payload[:exception]}"
      message
    }
  end

  if payload[:status] == 200
    if duration.to_f >= 500
      logger.warn {
        message = controller_format.clone
        message.sub!(/@status/, payload[:status].to_s)
        message.sub!(/@method/, payload[:method])
        message.sub!(/@path/, payload[:path])
        message.sub!(/@duration/, duration)
        message
      }
    else
      logger.info {
        message = controller_format.clone
        message.sub!(/@status/, payload[:status].to_s)
        message.sub!(/@method/, payload[:method])
        message.sub!(/@path/, payload[:path])
        message.sub!(/@duration/, duration)
        message
      }
    end
  end

  logger.dev0 { "PARAMS: #{payload[:params].to_json }" }
  logger.debug {
    db = (payload[:db_runtime] * 100).round/100.0 rescue "-"
    view = (payload[:view_runtime] * 100).round/100.0 rescue "-"
    "TIMING[ms]: sum:#{duration} db:#{db} view:#{view}"
  }

end

ActiveSupport::Notifications.subscribe "sql.active_record" do |name, start, finish, id, payload|
  logger = Log4r::Logger["db"]
  logger.debug { "(#{time_in_ms(start,finish)}) #{payload[:sql]}" }
end


ActiveSupport::Notifications.subscribe "exception.action_controller" do |name, start, finish, id, payload|
  logger = Log4r::Logger['rails']
  logger.exception { "msg:#{payload[:message]} - inspect:#{payload[:inspect]} - backtrace:#{payload[:backtrace].to_json}" }
end