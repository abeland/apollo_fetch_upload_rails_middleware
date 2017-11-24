# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'apollo_fetch_upload_rails_middleware/version'

Gem::Specification.new do |spec|
  spec.name          = 'apollo_fetch_upload_rails_middleware'
  spec.version       = ApolloFetchUploadRailsMiddleware::VERSION
  spec.authors       = ['Abe Land']
  spec.email         = ['abe@lostfoundlabs.com']

  spec.summary       = 'Rails middleware for using the apollo-fetch-upload npm package on the client.'
  spec.homepage      = 'https://github.com/abeland/apollo-fetch-upload-rails-middleware'
  spec.license       = 'MIT'

  spec.add_dependency 'rails', '~> 5'
  spec.required_ruby_version = '>= 2.2.2'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
end
