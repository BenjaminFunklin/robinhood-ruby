module Robinhood
  module REST
    class Client < API
      attr_accessor :token, :options, :private, :headers

      def initialize(*args)
        @options = args.last.is_a?(Hash) ? args.pop : {}

        @options[:username] = args[0] || Robinhood.username
        @options[:password] = args[1] || Robinhood.password
        @options[:client_id] = args[2] || Robinhood.client_id
        # @options[:username] = (args.size > 2 && args[2].is_a?(String) ? args[2] : args[0]) || Robinhood.username

        if @options[:username].nil? || @options[:password].nil?
          raise ArgumentError, "Account username and password are required"
        end

        setup_headers
        configuration
        login
      end

      def inspect # :nodoc:
        "<Robinhood::REST::Client @username=#{@options[:username]}>"
      end

      ##
      # Delegate account methods from the client. This saves having to call
      # <tt>client.account</tt> every time for resources on the default
      # account.
      def method_missing(method_name, *args, &block)
        if account.respond_to?(method_name)
          account.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to?(method_name, include_private=false)
        if account.respond_to?(method_name, include_private)
          true
        else
          super
        end
      end

      def configuration()
        @api_url = "https://api.robinhood.com/"

        @is_init = false

        @private = {
          "session":     {},
          "account":     nil,
          "username":    nil,
          "password":    nil,
          "headers":     nil,
          "auth_token":  nil
        }

        @api = {}
      end

      def setup_headers
        @headers ||= {
          "Accept" => "*/*",
          "Connection" => "keep-alive",
          # "Accept-Encoding" => "gzip, deflate",
        }
      end

      def login
        @private[:username] = @options[:username]
        @private[:password] = @options[:password]
        @private[:client_id] = @options[:client_id]

        if @private[:auth_token].nil?
          raw_response = HTTParty.post(
            @api_url + "oauth2/token/",
            body: {
              "password" => @private[:password],
              "username" => @private[:username],
              grant_type: 'password',
              client_id: @private[:client_id]
            }.as_json,
            headers: @headers
          )
          response = JSON.parse(raw_response.body)
          puts response.inspect

          if response["non_field_errors"]
            puts response["non_field_errors"]
            false
          elsif response["access_token"]
            @private[:auth_token] = response["access_token"]
            @headers["Authorization"] = "Bearer " + @private[:auth_token].to_s
            @private[:account] = self.account["results"][0]["url"]
          end
        end
      end
    end
  end
end