require "active_support/version"
require "active_support/deprecation"
require "active_support/deprecator"
require "active_support/log_subscriber"
require "active_support/isolated_execution_state"

module ActiveClient
  class LogSubscriber < ActiveSupport::LogSubscriber
    def self.runtime=(value)
      Thread.current[:active_client_runtime] = value
    end

    def self.runtime
      Thread.current[:active_client_runtime] ||= 0
    end

    # :nocov:
    def self.reset_runtime
      rt, self.runtime = runtime, 0
      rt
    end
    # :nocov:

    def request(event)
      self.class.runtime += event.duration
      return unless logger.debug?

      log_name = color("#{event.payload[:name]} (#{event.duration.round(1)}ms)",
                       YELLOW, bold: true)

      debug "  #{log_name}  #{color(event.payload[:uri], YELLOW, bold: true)}"
    end
  end
end
