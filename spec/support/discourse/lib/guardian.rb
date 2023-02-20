# frozen_string_literal: true

class Guardian
  def initialize(current_user = nil); end

  def method_missing(method, *args, &block)
    if method.to_s =~ /\Aensure_(.*)!\z/
      can_method = :"#{Regexp.last_match[1]}?"

      if respond_to?(can_method)
        raise Discourse::InvalidAccess, "#{can_method} failed" unless send(can_method, *args, &block)

        return
      end
    end

    super.method_missing(method, *args, &block)
  end

  def respond_to_missing?(name, include_private = false); end

  def is_admin?; end

  def is_staff?; end
end
