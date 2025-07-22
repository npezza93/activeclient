require "active_client/version"
require "active_client/railtie"
require "active_client/log_subscriber"
require "active_client/base"
require "net/http/persistent"

module ActiveClient
end

ActiveClient::LogSubscriber.attach_to :active_client
