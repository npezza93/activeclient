# ActiveClient

Basic API client interface

## Example OpenAI client

```ruby
class OpenAI < ActiveClient::Base
  class BadRequestError < StandardError
  end

  def initialize(model = "gpt-4o-mini-2024-07-18")
    @model = model
    super()
  end

  def response(input, name, schema, tools = [])
    response = post "responses", **request_params(input, name, schema, tools)

    raise BadRequestError, response unless response.success?

    JSON.parse(response.body.to_h["output"].
      find { it["type"] == "message" }.dig("content", 0, "text"))
  end

  def create_vector_store(name, *file_ids)
    post("vector_stores", name:, file_ids:,
                          expires_after: { days: 1, anchor: :last_active_at })
  end

  def vector_store(id)
    get("vector_stores/#{id}")
  end

  def vector_stores
    get("vector_stores")
  end

  def files
    get("files")
  end

  def upload_file(name, content)
    multipart_post("files", [%w(purpose user_data),
                             ["file", StringIO.new(content),
                              { filename: name, content_type: "text/plain" }]])
  end

  private

    attr_reader :model

    def default_headers = super.merge("Authorization" => token_header)
    def base_url = "https://api.openai.com/v1"
    def token_header = "Bearer #{credentials.dig(:open_ai, :token)}"

    def request_params(input, name, schema, tools)
      { input:, model:, store: false, top_p: 1.0, tools:, text: { format: {
        type: :json_schema, name:, schema:, strict: true
      } } }
    end
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem "activeclient_api"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install activeclient_api
```

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
