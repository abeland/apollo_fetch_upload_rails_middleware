module ApolloFetchUploadRailsMiddleware
  class Railtie < Rails::Railtie
    initializer 'apollo_fetch_upload_rails_middleware.insert_middleware' do |app|
      app.middleware.use ApolloFetchUploadRailsMiddleware::Middleware
    end
  end
end
