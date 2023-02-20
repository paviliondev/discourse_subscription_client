# frozen_string_literal: true

module Jobs
  def self.enqueue(job, opts = {}); end

  class Base
  end

  class Scheduled < Base
    extend MiniScheduler::Schedule
  end
end
