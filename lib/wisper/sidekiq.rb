require 'yaml'
require 'wisper'
require 'sidekiq'

require 'wisper/sidekiq/version'

module Wisper
  class SidekiqBroadcaster
    class Worker
      include ::Sidekiq::Worker

      sidekiq_options queue: 'events'

      def perform(yml)
        (subscriber, event, args) = ::YAML.load(yml)
        subscriber.public_send(event, *args)
      end
    end

    def broadcast(subscriber, publisher, event, args)
      Worker.perform_async(::YAML.dump([subscriber, event, args]))
    end

    def self.register
      Wisper.configure do |config|
        config.broadcaster :sidekiq, SidekiqBroadcaster.new
        config.broadcaster :async,   SidekiqBroadcaster.new
      end
    end
  end
end

Wisper::SidekiqBroadcaster.register
