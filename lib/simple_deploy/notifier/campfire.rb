require 'tinder'

module SimpleDeploy
  class Notifier
    class Campfire

      def initialize(args)
        @stack_name = args[:stack_name]
        @environment = args[:environment]
        @config = args[:config]
        @logger = @config.logger

        attributes = stack.attributes
        @subdomain = attributes['campfire_subdomain']
        @room_ids = attributes['campfire_room_ids'] ||= ''
        @logger.debug "Campfire subdomain '#{@subdomain}'."
        @logger.debug "Campfire room ids '#{@room_ids}'."

        if @subdomain
          @token = @config.notifications['campfire']['token']
          @campfire = Tinder::Campfire.new @subdomain, :token => @token,
                                                       :ssl_options => { :verify => false }
        end
      end

      def send(message)
        begin
        @logger.info "Sending Campfire notifications."
        @room_ids.split(',').each do |room_id|
          @logger.debug "Sending notification to Campfire room #{room_id}."
          room = @campfire.find_room_by_id room_id.to_i
          room.speak message
        end
        @logger.info "Campfire notifications complete."
        rescue
          @logger.warn "Failed to send notification to Campfire room #{room_id}."
        end
      end

      private

      def stack
        @stack ||= Stackster::Stack.new :environment => @environment,
                                        :name        => @stack_name,
                                        :config      => @config.environment(@environment),
                                        :logger      => @logger
      end
    end
  end
end
