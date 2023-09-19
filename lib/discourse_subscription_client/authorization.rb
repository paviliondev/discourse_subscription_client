# frozen_string_literal: true

module DiscourseSubscriptionClient
  class Authorization
    SCOPE ||= "discourse-subscription-server:user_subscription"

    # default the final landing path of an authorisation loop to the subscriptions client plugin location,
    # but allow this to be changed by inclusion of a parameter in the authorize method of the Suppliers Controller
    # to tailor it for each individual plugin leveraging the gem.
    @@completed_authorisation_callback_final_landing_path = "/admin/plugins/subscription-client/subscriptions"

    def self.request_id(supplier_id)
      "#{supplier_id}-#{SecureRandom.hex(32)}"
    end

    def self.url(user, supplier, request_id)
      keys = generate_keys(user.id, request_id)
      params = {
        public_key: keys.public_key,
        nonce: keys.nonce,
        client_id: client_id(user.id),
        auth_redirect: "#{Discourse.base_url}/admin/plugins/subscription-client/suppliers/authorize/callback",
        application_name: SiteSetting.title,
        scopes: SCOPE
      }
      uri = URI.parse("#{supplier.url}/user-api-key/new")
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end

    def self.process_response(request_id, payload)
      data = decrypt_payload(request_id, payload)
      return false unless data.is_a?(Hash) && data[:key] && data[:user_id]

      data
    end

    def self.generate_keys(user_id, request_id)
      rsa = OpenSSL::PKey::RSA.generate(2048)
      nonce = SecureRandom.hex(32)
      set_keys(request_id, user_id, rsa, nonce)
      OpenStruct.new(nonce: nonce, public_key: rsa.public_key)
    end

    def self.decrypt_payload(request_id, payload)
      keys = get_keys(request_id)

      return false unless keys.present? && keys.pem

      delete_keys(request_id)

      rsa = OpenSSL::PKey::RSA.new(keys.pem)
      decrypted_payload = rsa.private_decrypt(Base64.decode64(payload))

      return false unless decrypted_payload.present?

      begin
        data = JSON.parse(decrypted_payload).symbolize_keys
      rescue JSON::ParserError
        return false
      end

      return false unless data[:nonce] == keys.nonce

      data[:user_id] = keys.user_id
      data
    end

    def self.get_keys(request_id)
      raw = PluginStore.get(DiscourseSubscriptionClient::PLUGIN_NAME, "#{keys_db_key}_#{request_id}")
      OpenStruct.new(
        user_id: raw && raw["user_id"],
        pem: raw && raw["pem"],
        nonce: raw && raw["nonce"]
      )
    end

    def self.revoke(supplier)
      url = "#{supplier.url}/user-api-key/revoke"
      request = DiscourseSubscriptionClient::Request.new(:supplier, supplier.id)
      headers = { "User-Api-Key" => supplier.api_key }
      result = request.perform(url, headers: headers, body: nil, opts: { method: "POST" })
      result && result[:success] == "OK"
    end

    def self.client_id(user_id)
      "#{Discourse.current_hostname}:#{user_id}:#{SecureRandom.hex(8)}"
    end

    def self.keys_db_key
      "keys"
    end

    def self.set_keys(request_id, user_id, rsa, nonce)
      PluginStore.set(DiscourseSubscriptionClient::PLUGIN_NAME, "#{keys_db_key}_#{request_id}",
                      user_id: user_id,
                      pem: rsa.export,
                      nonce: nonce)
    end

    def self.delete_keys(request_id)
      PluginStore.remove(DiscourseSubscriptionClient::PLUGIN_NAME, "#{keys_db_key}_#{request_id}")
    end

    def self.completed_authorisation_callback_final_landing_path
      @@completed_authorisation_callback_final_landing_path
    end

    def self.completed_authorisation_callback_final_landing_path=(path)
      @@completed_authorisation_callback_final_landing_path = path
    end
  end
end
