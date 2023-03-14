# frozen_string_literal: true

module Jobs
  cattr_accessor :enqueued do
    {}
  end
  cattr_accessor :enqueued_in do
    {}
  end

  def self.enqueue(job, opts = {})
    @@enqueued[job] = opts
  end

  def self.enqueue_in(delay, job, opts = {})
    @@enqueued_in[job] = { delay: delay, opts: opts }
  end

  class Base
  end

  class Scheduled < Base
    extend MiniScheduler::Schedule
  end
end
