class ActiveClient::Base
  Response = Struct.new(:body, :success?)

  def get(path, skip_parsing: false, **query)
    make_request(Net::HTTP::Get, path, skip_parsing:, query:)
  end

  def post(path, **body)
    make_request(Net::HTTP::Post, path, body:)
  end

  def delete(path)
    make_request(Net::HTTP::Delete, path)
  end

  def multipart_post(path, body, skip_parsing: false)
    instrument(klass: Net::HTTP::Post, path:, query: nil,
               body: nil) do |http, request|
      request.set_form(body, "multipart/form-data")

      response = http.request(request)

      Response.new(parse_response(response.body, skip_parsing),
                   response.is_a?(Net::HTTPSuccess))
    end
  end

  private

    def instrument(klass:, path:, query:, body:)
      uri, http, request = construct_request(klass:, path:, query:)

      set_body(request, body)

      loggable = loggable_uri(uri)
      args = { name: self.class.name.demodulize, uri: loggable }

      ActiveSupport::Notifications.
        instrument("request.active_client", args) { yield http, request }
    end

    def make_request(klass, path, skip_parsing: false, query: {}, body: {})
      instrument(klass:, path:, query:, body:) do |http, request|
        response = http.request(request)

        Response.new(parse_response(response.body, skip_parsing),
                     response.is_a?(Net::HTTPSuccess))
      end
    end

    def parse_response(body, skip_parsing)
      if skip_parsing
        body
      else
        deep_inheritable_options(ActiveSupport::JSON.decode(body))
      end
    end

    def construct_request(klass:, path:, query:)
      uri = construct_uri(path:, query:)

      http = Net::HTTP.new(uri.host, uri.port).tap do
        it.use_ssl = uri.instance_of?(URI::HTTPS)
        it.read_timeout = 1200
      end

      [uri, http, klass.new(uri.request_uri, default_headers(klass))]
    end

    def construct_uri(path:, query:)
      if base_url.present?
        URI(URI::DEFAULT_PARSER.escape(File.join(base_url, path)))
      else
        URI(URI::DEFAULT_PARSER.escape(path))
      end.tap { |uri| build_query(uri, query) }
    end

    def build_query(uri, query)
      return unless query.present? || default_query.present?

      uri.query = URI.encode_www_form(default_query.merge(query))
    end

    def default_headers(_klass)
      { "Accept" => "application/json",
        "Content-Type" => "application/json" }
    end

    def default_query
      {}
    end

    def default_body
      {}
    end

    def base_url
    end

    def token_header
      raise NotImplementedError
    end

    def credentials
      Rails.application.credentials
    end

    def all_credentials
      credentials.to_h.values.flat_map do |cred|
        cred.try(:values).presence || cred
      end
    end

    def loggable_uri(uri)
      uri.to_s.tap do |loggable|
        all_credentials.each do |s|
          loggable.gsub!(s, "[FILTERED]")
        end
      end
    end

    def deep_inheritable_options(obj) # rubocop:disable Metrics/MethodLength
      case obj
      when Hash
        inherited = ActiveSupport::InheritableOptions.new
        obj.each do |key, value|
          inherited[key] = deep_inheritable_options(value)
        end
        inherited
      when Array
        obj.map { |v| deep_inheritable_options(v) }
      else
        obj
      end
    end

    def set_body(request, body)
      if body.present? &&
        request["Content-Type"] == "application/x-www-form-urlencoded"
        set_form_data(request, body)
      elsif body.present?
        request.body = default_body.merge(body).to_json
      end
    end

    def set_form_data(request, body)
      request.set_form_data(default_body.merge(body))
    end
end
