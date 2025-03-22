require_relative "lib/active_client/version"

Gem::Specification.new do |spec|
  spec.name        = "activeclient"
  spec.version     = ActiveClient::VERSION
  spec.authors     = ["Nick Pezza"]
  spec.email       = ["pezza@hey.com"]
  spec.homepage    = "https://github.com/npezza93/activeclient"
  spec.summary     = "Basic client for make api classes"
  spec.license     = "MIT"

  spec.metadata["rubygems_mfa_required"] = "true"
  spec.required_ruby_version = ">= 3.4.0"
  spec.files = Dir["{app,config,db,lib,vendor}/**/*", "LICENSE.md",
                   "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 8.0"
end
