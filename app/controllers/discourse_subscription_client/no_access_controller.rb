# frozen_string_literal: true

module DiscourseSubscriptionClient
  class NoAccessController < ApplicationController
    def index
      head :ok
    end
  end
end
