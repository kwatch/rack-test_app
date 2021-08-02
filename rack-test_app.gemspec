# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/test_app'

Gem::Specification.new do |spec|
  spec.name          = "rack-test_app"
  spec.version       = Rack::TestApp::VERSION
  spec.authors       = ["kwatch"]
  spec.email         = ["kwatch@gmail.com"]
  spec.summary       = "more intuitive testing helper library for Rack app"
  spec.description   = <<END
Rack::TestApp is another testing helper library for Rack application.
IMO it is more intuitive than Rack::Test.
END
  spec.homepage      = "https://github.com/kwatch/rack-test_app"
  spec.license       = "MIT-LICENCE"
  spec.files         = Dir[*%w[
                         README.md MIT-LICENSE.txt Rakefile.rb rack-test_app.gemspec
                         lib/rack/test_app.rb
			 test/test_helper.rb
			 test/rack/**/*_test.rb
			 test/rack/test_app/data/**/*.*
                       ]]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 2.0'
  spec.add_runtime_dependency "rack"
  spec.add_development_dependency "minitest"
end
