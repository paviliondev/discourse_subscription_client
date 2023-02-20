# frozen_string_literal: true

%w[
  ./discourse_subscription_client/version
  ./discourse_subscription_client/engine
].each do |path|
  require_relative path
end
