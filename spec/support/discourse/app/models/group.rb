# frozen_string_literal: true

class Group < ActiveRecord::Base
  AUTO_GROUPS = {
    everyone: 0,
    admins: 1,
    moderators: 2,
    staff: 3,
    trust_level_0: 10,
    trust_level_1: 11,
    trust_level_2: 12,
    trust_level_3: 13,
    trust_level_4: 14
  }.freeze
end
