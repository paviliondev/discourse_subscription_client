# frozen_string_literal: true

module DiscourseSubscriptionClient
  class Request
    SUPPLIER_ERROR_LIMIT = 3
    RESOURCE_ERROR_LIMIT = 5
    VALID_TYPES = %w[resource supplier].freeze

    attr_reader :type,
                :id

    def initialize(type, id)
      @type = type.to_s
      @id = id
    end

    def perform(url, headers: {}, body: nil, opts: { method: "GET" })
      return nil unless VALID_TYPES.include?(type)

      if body
        uri = URI.parse(url)
        uri.query = CGI.unescape(body.to_query)
        url = uri.to_s
      end

      headers.merge!({ "Origin" => Discourse.base_url_no_prefix })

      connection = Excon.new(url, headers: headers)

      begin
        response = connection.request(opts)
      rescue Excon::Error::Socket, Excon::Error::Timeout
        response = nil
      end

      if response && response.status == 200
        expire_error

        begin
          data = JSON.parse(response.body).deep_symbolize_keys
        rescue JSON::ParserError
          return nil
        end

        data
      else
        create_error(url, response)
        nil
      end
    end

    def current_error(query_only: false)
      @current_error ||= begin
        query = SubscriptionClientRequest
                .where("request_id = :request_id AND request_type = :request_type AND expired_at IS NULL", request_id: id, request_type: type)

        return nil unless query.exists?
        return query if query_only

        query.first
      end
    end

    def self.current_error(type, id)
      new(type, id).current_error
    end

    def limit
      send("#{@type}_limit")
    end

    def create_error(url, response)
      if (error = current_error)
        error.count = error.count.to_i + 1
      else
        error = SubscriptionClientRequest.new(
          request_id: id,
          request_type: type,
          message: I18n.t("subscription_client.notices.connection_error", url: url),
          count: 1
        )
      end

      if response.present?
        begin
          body = JSON.parse(response.body)
        rescue JSON::ParserError
          body = nil
        end

        error.response = {
          status: response.status,
          body: body
        }

        error.message = body["error"] if body && body["error"]
      end

      error.save

      @current_error = nil

      return unless reached_limit?

      SubscriptionClientNotice.notify_connection_error(type, id)
    end

    def expire_error
      if (query = current_error(query_only: true))
        record = query.first
        record.expired_at = Time.now
        record.save
      end

      SubscriptionClientNotice.expire_connection_error(type, id)
    end

    def supplier_limit
      SUPPLIER_ERROR_LIMIT
    end

    def resource_limit
      RESOURCE_ERROR_LIMIT
    end

    def reached_limit?
      return false unless current_error.present?

      current_error.count.to_i >= limit
    end
  end
end
