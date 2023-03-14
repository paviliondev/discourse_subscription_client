# frozen_string_literal: true

require "spec_helper"

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("support/discourse/config/environment", __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "fabrication"
require "rspec/active_model/mocks"
require "webmock/rspec"

Dir["spec/helpers/*.rb"].each { |f| require_relative ".#{f.split("spec")[1]}" }
Dir["spec/fabricators/*.rb"].each { |f| require_relative ".#{f.split("spec")[1]}" }
Dir["spec/support/*.rb"].each { |f| require_relative ".#{f.split("spec")[1]}" }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

ActiveRecord::Schema.verbose = false
load "support/discourse/db/schema.rb"

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include DiscourseHelper
  config.include DiscourseSubscriptionClientHelper

  def test_multisite_connection(name)
    RailsMultisite::ConnectionManagement.with_connection(name) do
      ActiveRecord::Base.transaction(joinable: false) do
        yield
        raise ActiveRecord::Rollback
      end
    end
  end

  config.before(:each) do
    Jobs.enqueued = {}
    Jobs.enqueued_in = {}
  end
end

class TrackTimeStub
  def self.stubbed
    false
  end
end

def freeze_time(now = Time.now)
  time = now
  datetime = now

  case now
  when Time
    datetime = now.to_datetime
  when DateTime
    time = now.to_time
  else
    datetime = DateTime.parse(now.to_s)
    time = Time.parse(now.to_s)
  end

  raise "nested freeze time not supported" if block_given? && TrackTimeStub.stubbed

  DateTime.stub(:now) { datetime }
  Time.stub(:now) { time }
  Date.stub(:today) { datetime.to_date }
  TrackTimeStub.stub(:stubbed) { true }

  if block_given?
    begin
      yield
    ensure
      unfreeze_time
    end
  else
    time
  end
end

def unfreeze_time
  DateTime.unstub(:now)
  Time.unstub(:now)
  Date.unstub(:today)
  TrackTimeStub.unstub(:stubbed)
end
