module Search
  # Search client (uses Elasticsearch as a backend)
  class Client
    class << self
      # adapted from https://api.rubyonrails.org/classes/Module.html#method-i-delegate_missing_to
      def method_missing(method, *args, &block)
        if target.respond_to?(method, false)
          request do
            target.public_send(method, *args, &block)
          end
        else
          super
        end
      end

      # adapted from https://api.rubyonrails.org/classes/Module.html#method-i-delegate_missing_to
      def respond_to_missing?(method, _include_all = false)
        target.respond_to?(method, false) || super
      end

      private

      TRANSPORT_EXCEPTIONS = [
        Elasticsearch::Transport::Transport::Errors::BadRequest,
        Elasticsearch::Transport::Transport::Errors::NotFound,
      ].freeze

      def request
        yield
      rescue *TRANSPORT_EXCEPTIONS => e
        class_name = e.class.name.demodulize

        DatadogStatsClient.increment("elasticsearch.errors", tags: ["error:#{class_name}"], message: e.message)

        # raise specific error if known, generic one if unknown
        error_class = "::Search::Errors::Transport::#{class_name}".safe_constantize
        raise error_class, e.message if error_class

        raise ::Search::Errors::TransportError, e.message
      end

      def target
        @target ||= Elasticsearch::Client.new(
          url: ApplicationConfig["ELASTICSEARCH_URL"],
          retry_on_failure: 5,
          request_timeout: 30,
          adapter: :typhoeus,
          log: Rails.env.development?,
        )
      end
    end
  end
end
