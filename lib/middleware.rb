module ApolloFetchUploadRailsMiddleware
  class Foo
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      if request.content_type.try(:start_with?, 'multipart/form-data') && request.params.key?('operations')
        gql_operations = JSON.parse(request.params['operations'])
        request.update_param('query', gql_operations['query'])
        request.update_param('variables', gql_operations['variables'])
        request.update_param('operationName', gql_operations['operationName'])

        # Gather the param key/value pairs for which the values are File instances (sent as part
        # of the Form POST from apollo fetch upload client-side middleware,
        # cf. https://github.com/apollographql/apollo-fetch/blob/master/packages/apollo-fetch-upload/src/index.ts).
        file_kv_pairs = []
        request.params.each do |k, v|
          next unless k.start_with?('variables.') &&
                      v.is_a?(Hash) &&
                      v.key?(:tempfile) &&
                      v[:tempfile].is_a?(Tempfile)

          file_kv_pairs << [k, v]
        end

        variables_wrapper = ActiveSupport::HashWithIndifferentAccess.new(
          variables: gql_operations['variables'],
        )

        file_kv_pairs.each do |kv_pair|
          path, file = kv_pair

          file_info = {
            name: file[:filename],
            path: file[:tempfile].path,
            size: file[:tempfile].size,
            type: file[:type],
          }

          pathset(
            variables_wrapper,
            path.split('.'), # path_components
            file_info,
          )
        end

        request.update_param('variables', variables_wrapper[:variables])
      end

      @app.call(env)
    end

    private

    def pathset(h, path_components, val_h)
      if path_components.blank?
        h.merge!(val_h)
        return
      end

      curr_path_component = path_components.shift
      if h.key?(curr_path_component)
        raise 'Invalid path' unless h[curr_path_component].is_a?(Hash)
      else
        h[curr_path_component] = {}
      end

      pathset(h[curr_path_component], path_components, val_h)
    end
  end
end
