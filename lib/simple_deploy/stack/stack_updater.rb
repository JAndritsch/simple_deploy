require 'json'

module SimpleDeploy
  class StackUpdater

    def initialize(args)
      @config = SimpleDeploy.config
      @logger = SimpleDeploy.logger
      @entry = args[:entry]
      @name = args[:name]
      if args[:template_file]
        raise "OH HAI"
        @template_body = read_template_from_file args[:template_file]
      else
        @template_body = args[:template_body]
      end
    end

    def update_stack_if_parameters_changed(attributes)
      if parameter_updated?(attributes)
        @logger.debug "Updated parameters found."
        update
      else
        @logger.debug "No Cloud Formation parameters require updating."
        false
      end
    end

    private

    def update
      if status.wait_for_stable
        @logger.info "Updating Cloud Formation stack #{@name}."
        response = cloud_formation.update :name => @name,
                               :parameters => read_parameters_from_entry_attributes,
                               :template => @template_body
      else
        raise "#{@name} did not reach a stable state."
      end
    end

    def read_template_from_file(template_file)
      file = File.open template_file
      file.read
    end

    def parameter_updated?(attributes)
      (template_parameters - updated_parameters(attributes)) != template_parameters
    end

    def template_parameters
      json = JSON.parse @template_body
      json['Parameters'].nil? ? [] : json['Parameters'].keys
    end

    def updated_parameters attributes
      (attributes.map { |s| s.keys }).flatten
    end

    def read_parameters_from_entry_attributes
      h = {}
      entry_attributes = @entry.attributes
      template_parameters.each do |p|
        h[p] = entry_attributes[p] if entry_attributes[p]
      end
      h
    end

    def cloud_formation
      @cloud_formation ||= AWS::CloudFormation.new
    end

    def status
      @status ||= Status.new :name => @name
    end
  end
end
