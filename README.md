# Apollo Fetch Upload Rails Middleware

NOTE: This does not support batching!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apollo_fetch_upload_rails_middleware'
```

And then do:

    $ bundle install

Or install it yourself as:

    $ gem install apollo_fetch_upload_rails_middleware

## Usage

Using `Railtie`, this gem installs its middleware in your application. It will populate the GraphQL mutation inputs with the appropriate file metadata as described in the [apollo-fetch-upload](https://github.com/apollographql/apollo-fetch/tree/master/packages/apollo-fetch-upload) documentation.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/apollo_fetch_upload_rails_middleware.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
