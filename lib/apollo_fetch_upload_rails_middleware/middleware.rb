module ApolloFetchUploadRailsMiddleware
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      if request.content_type.try(:start_with?, 'multipart/form-data') &&
         request.params.key?('operations') &&
         request.params.key?('map')

        gql_operations = JSON.parse(request.params['operations'])
        file_to_variables_map = JSON.parse(request.params['map'])

        # Gather file data.
        file_to_metadata_map = {}
        file_to_variables_map.each_key do |file_index|
          file_to_metadata_map[file_index] = validate_file_info(request.params[file_index.to_s])
        end

        if gql_operations.is_a?(Hash)
          request.update_param('query', gql_operations['query'])
          request.update_param('operationName', gql_operations['operationName'])
          request.update_param(
            'variables',
            fill_in_gql_variables(
              file_to_variables_map,
              file_to_metadata_map,
              gql_operations['variables'],
            ),
          )
        elsif gql_operations.is_a?(Array)
          gql_operations.each_with_index do |gql_operation, idx|
            gql_operation['variables'] = fill_in_gql_variables(
              file_to_variables_map,
              file_to_metadata_map,
              gql_operation['variables'],
              batch_index: idx,
            )
          end

          # cf. https://github.com/rmosolgo/graphql-ruby/blob/master/
          # guides/queries/multiplex.md#apollo-query-batching
          # -> "Apollo sends the params in a _json variable when batching is enabled"
          request.update_param('_json', gql_operations)
        else
          raise 'Invalid JSON in "operations" request param.'
        end
      end

      @app.call(env)
    end

    def fill_in_gql_variables(
      file_to_variables_map,
      file_to_metadata_map,
      variables_h,
      batch_idx: nil
    )
      # file_to_variables_map is of type map<int, [string]>, mapping file indices to the GQL variables which
      # use that file (the author of apollo-upload-client does it this way to support batching more efficiently).
      #
      # request.params should have keys of file indices (as strings) mapping to metadata about the file itself, e.g.
      #
      #    "0"=> {
      #      :filename=>"f6765.pdf",
      #      :type=>"application/pdf",
      #      :name=>"0",
      #      :tempfile=>
      #        <File:/var/folders/cc/fwn8xb8s6jzdg672klspnvg40000gn/T/RackMultipart20180719-18089-y5qrhg.pdf>,
      #      :head=>
      #        "Content-Disposition: form-data; name=\"0\"; filename=\"f6765.pdf\"\r\n" +
      #        "Content-Type: application/pdf\r\n"
      #    }
      #
      # So, what we need to do is go through all of the files, and for each GQL variable which uses that file,
      # set it (using pathset, set below) to have that File instance.

      variables_wrapper = { variables: variables_h }.with_indifferent_access

      file_to_variables_map.each do |file_index, variable_paths|
        file_info = file_to_metadata_map[file_index]

        variable_paths.each do |variable_path|
          variable_path_components = variable_path.split('.')

          unless batch_idx.nil?
            # We only care about this variable path if it matches the given batch_idx.
            # Otherwise, it doesn't apply to this operation.
            variable_path_batch_idx = variable_path_components.shift
            next unless batch_idx == variable_path_batch_idx
          end

          pathset(
            variables_wrapper,
            variable_path_components,
            file_info,
          )
        end
      end

      variables_wrapper[:variables]
    end

    private

    def pathset(variables_h, path_components, file_info)
      # Find the immediate parent, and then set file info on parent's field
      # named path_components.last.

      raise 'Not deep enough' unless path_components.size >= 2

      h_or_a = variables_h
      while path_components.size > 1
        path_component = path_components.shift
        if h_or_a.is_a?(Array)
          h_or_a = h_or_a[path_component.to_i]
        elsif h_or_a.is_a?(Hash)
          h_or_a = h_or_a[path_component]
        else
          raise 'Unexpected type in variables path.'
        end
      end

      # Now the last path component is the field we want to set.
      raise 'Bad path components.' unless path_components.size == 1
      field_name = path_components.first

      if h_or_a.is_a?(Hash)
        h_or_a[field_name] = file_info
      elsif h_or_a.is_a?(Array)
        h_or_a[field_name.to_i] = file_info
      else
        raise 'Unexpected type in variables path.'
      end
    end

    def validate_file_info(file_data)
      [:filename, :tempfile, :type].each do |k|
        raise "Missing key '#{k.to_s}' in file data." unless file_data[k].present?
      end

      raise 'Expected Tempfile in file_data[:tempfile]' unless file_data[:tempfile].is_a?(Tempfile)

      {
        name: file_data[:filename],
        path: file_data[:tempfile].path,
        size: file_data[:tempfile].size,
        type: file_data[:type],
      }
    end
  end
end
