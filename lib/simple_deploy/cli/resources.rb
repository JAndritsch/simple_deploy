require 'trollop'

module SimpleDeploy
  module CLI

    class Resources

      include Shared

      def show
        @opts = Trollop::options do
          version SimpleDeploy::VERSION
          banner <<-EOS

Show resources of a stack.

simple_deploy resources -n STACK_NAME -e ENVIRONMENT

EOS
          opt :help, "Display Help"
          opt :environment, "Set the target environment", :type => :string
          opt :log_level, "Log level:  debug, info, warn, error", :type    => :string,
                                                                  :default => 'info'
          opt :name, "Stack name to manage", :type => :string
        end

        valid_options? :provided => @opts,
                       :required => [:environment, :name]

        SimpleDeploy.create_config @opts[:environment]
        SimpleDeploy.logger @opts[:log_level]
        stack = Stack.new :name        => @opts[:name],
                          :environment => @opts[:environment]

        rescue_exceptions_and_exit do
          jj stack.resources
        end
      end

      def command_summary
        'Show resources of a stack'
      end

    end

  end
end
