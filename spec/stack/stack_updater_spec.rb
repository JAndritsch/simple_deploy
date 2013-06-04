require 'spec_helper'
require 'json'

describe SimpleDeploy::StackUpdater do
  include_context 'stubbed config'
  include_context 'double stubbed logger'

  before do
    @template_body = '{ "Parameters": 
                        { 
                          "param1" : 
                            {
                              "Description" : "param-1"
                            },
                          "param2" : 
                            {
                              "Description" : "param-2"
                            }
                        }
                      }'

    @template_file_body = '{ "Parameters":
                        {
                          "param1" :
                            {
                              "Description" : "new-param-1"
                            },
                          "param2" :
                            {
                              "Description" : "new-param-2"
                            }
                        }
                      }'
  end

  it "should update the stack when parameters change and stack is stable" do
    attributes = { "param1" => "value1", "param3" => "value3" }
    entry_mock = mock 'entry mock'
    status_mock = mock 'status mock'
    cloud_formation_mock = mock 'cloud formation mock'
    SimpleDeploy::AWS::CloudFormation.should_receive(:new).
                                      and_return cloud_formation_mock
    entry_mock.should_receive(:attributes).and_return attributes
    cloud_formation_mock.should_receive(:update).
                         with(:name      => 'test-stack', 
                              :parameters => { 'param1' => 'value1' },
                              :template   => @template_body).
                         and_return true
    SimpleDeploy::Status.should_receive(:new).
                      with(:name   => 'test-stack').
                      and_return status_mock
    status_mock.should_receive(:wait_for_stable).and_return true
    stack_updater = SimpleDeploy::StackUpdater.new :name          => 'test-stack',
                                                   :template_body => @template_body,
                                                   :entry         => entry_mock

    stack_updater.update_stack_if_parameters_changed( [ { 'param1' => 'new-value' } ] ).
                  should == true
  end

  it "should raise an error when parameters change and stack is not stable" do
    attributes = { "param1" => "value1", "param3" => "value3" }
    entry_mock = mock 'entry mock'
    status_mock = mock 'status mock'
    cloud_formation_mock = mock 'cloud formation mock'
    SimpleDeploy::AWS::CloudFormation.should_receive(:new).
                                      exactly(0).times
    SimpleDeploy::Status.should_receive(:new).
                         with(:name   => 'test-stack').
                         and_return status_mock
    status_mock.should_receive(:wait_for_stable).and_return false
    stack_updater = SimpleDeploy::StackUpdater.new :name          => 'test-stack',
                                                   :template_body => @template_body,
                                                   :entry         => entry_mock

    lambda {stack_updater.update_stack_if_parameters_changed( [ { 'param1' => 'new-value' } ] ) }.
                  should raise_error
  end

  it "should not update the stack when parameters don't change" do
    attributes = { "param3" => "value3" }
    entry_mock = mock 'entry mock'
    SimpleDeploy::AWS::CloudFormation.should_receive(:new).exactly(0).times
    stack_updater = SimpleDeploy::StackUpdater.new :name          => 'test-stack',
                                                   :template_body => @template_body,
                                                   :entry         => entry_mock

    stack_updater.update_stack_if_parameters_changed( [ { 'another-param' => 'new-value' } ] ).
                  should == false
  end

  describe "stack templates" do
    subject { SimpleDeploy::StackUpdater }
    let (:entry_mock) { mock 'entry mock' }
    let (:cloud_formation_mock) { mock 'cloud formation' }
    let (:template_file) { mock 'new template', :body => @template_file_body }

    before do
      subject.any_instance.stub(:read_template_from_file).and_return(template_file.body)
      subject.any_instance.stub(:parameter_updated?).and_return(true)
      SimpleDeploy::Status.any_instance.stub(:wait_for_stable).and_return(true)
      subject.any_instance.stub(:cloud_formation).and_return(cloud_formation_mock)
      entry_mock.stub(:attributes).and_return({})
    end

    context "when no template file is passed in" do
      it "should not read any template file" do
        subject.any_instance.should_not_receive(:read_template_from_file)
        subject.new(
          :name          => 'test-stack',
          :template_body => @template_body,
          :entry         => entry_mock
        )
      end

      it "uses the default template" do
        stack_updater = subject.new(
          :name          => 'test-stack',
          :template_body => @template_body,
          :entry         => entry_mock
        )
        cloud_formation_mock.should_receive(:update).with(
          :name       => 'test-stack',
          :parameters => {},
          :template   => @template_body
        )
        stack_updater.update_stack_if_parameters_changed({})
      end
    end

    context "when a template file is provided" do
      it "should read the provided template" do
        subject.any_instance.should_receive(:read_template_from_file)
        subject.new(
          :name          => 'test-stack',
          :template_body => @template_body,
          :template_file => template_file,
          :entry         => entry_mock
        )
      end

      it "uses the new template body" do
        stack_updater = subject.new(
          :name          => 'test-stack',
          :template_body => @template_body,
          :template_file => template_file,
          :entry         => entry_mock
        )
        cloud_formation_mock.should_receive(:update).with(
          :name       => 'test-stack',
          :parameters => {},
          :template   => @template_file_body
        )
        stack_updater.update_stack_if_parameters_changed({})
      end
    end
  end

end
