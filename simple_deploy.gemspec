# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "simple_deploy/version"

Gem::Specification.new do |s|
  s.name        = "simple_deploy"
  s.version     = SimpleDeploy::VERSION
  s.authors     = ["Brett Weaver"]
  s.email       = ["brett@weav.net"]
  s.homepage    = ""
  s.summary     = %q{I help with deployments}
  s.description = %q{I am designed to deploy artifacts uploaded by Heirloom}

  s.rubyforge_project = "simple_deploy"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", '= 2.11.0'

  s.add_runtime_dependency "capistrano", '= 2.13.4'
  s.add_runtime_dependency "stackster", '= 0.3.1'
  s.add_runtime_dependency "tinder", '= 1.9.1'
  s.add_runtime_dependency "trollop", '= 2.0'
end
