# frozen_string_literal: true

module Discourse
  class NotLoggedIn < StandardError; end
end

module Discourse
  class InvalidAccess < StandardError; end
end

class ApplicationController < ActionController::Base
  before_action :check_xhr
  before_action :preload_json

  protect_from_forgery

  def self.requires_login(arg = {}); end

  def ensure_logged_in
    raise Discourse::NotLoggedIn unless current_user.present?
  end

  def check_xhr; end

  def preload_json; end

  def current_user; end

  rescue_from Discourse::InvalidAccess do |_e|
    render json: {}, status: 403
  end
end
