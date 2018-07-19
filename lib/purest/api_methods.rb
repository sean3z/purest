# frozen_string_literal: true

module Purest
  class APIMethods < Purest::Rest

    def append_path(url, options)
      options.each do |path|
        new_path = path.to_s.gsub('show_', '')
        url.map!{|u| u + "/#{new_path}"} if !@options.nil? && @options[path]
      end
    end

    def get(options = nil, path = nil, params = nil, appended_paths = nil)
      @options = options
      create_session unless authenticated?

      raw_resp = @conn.get do |req|
        url = ["/api/#{Purest.configuration.api_version}/#{path}"]

        # Name is pretty universal, since most endpoints allow you to query
        # specific items, e.g. /hosts/host1 or /volume/volume1
        # where host1 and volume1 are names
        url.map!{|u| u + "/#{@options[:name]}"} if !@options.nil? && @options[:name]

        # Here we append the various paths, based on available GET endpoints
        append_path(url, appended_paths) unless appended_paths.nil?

        # Generate methods for url building based on
        # params passed in, e.g. [:pending, :action] becomes
        # use_pending and use_action
        params.each do |param|
          self.class.send(:define_method, :"use_#{param}") do |options|
            options ? use_named_parameter(param, options[param]) : []
          end
        end

        # Generate array, consisting of url parts, to be built
        # by concat_url method below
        params.each do |param|
          url += self.send(:"use_#{param}",@options)
        end

        req.url concat_url url
      end

      JSON.parse(raw_resp.body, :symbolize_names => true)
    end
  end

end