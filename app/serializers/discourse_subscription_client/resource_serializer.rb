# frozen_string_literal: true

module DiscourseSubscriptionClient
  class ResourceSerializer < ApplicationSerializer
    attributes :id,
               :name
  end
end
