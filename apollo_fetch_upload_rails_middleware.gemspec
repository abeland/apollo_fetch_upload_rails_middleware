require_relative './lib/version'

Gem::Specification.new do |s|
  s.name = 'apollo_fetch_upload_rails_middleware'
  s.version = ApolloFetchUploadRailsMiddleware::VERSION
  s.platform = Gem::Platform::RUBY
  s.author = 'Abe Land'
  s.email = 'abe@lostfoundlabs.com'
  s.homepage = 'https://github.com/abeland/apollo-fetch-upload-rails-middleware'
  s.summary = 'Rails middleware for using the apollo-fetch-upload npm package on the client.'
  s.description = ''
  s.license = 'MIT'
  s.files = `git ls-files`.split("\n")
  s.require_paths = ['lib']
end
