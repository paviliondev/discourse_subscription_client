# frozen_string_literal: true

module DiscourseHelper
  def create_discourse_user(admin: false, moderator: false)
    mock_model(User,
               name: "Bruce Wayne",
               username: "batman",
               email: "darkknight@wayneenterprises.com",
               password: "batcave101",
               trust_level: 1,
               admin: admin,
               moderator: moderator)
  end

  def sign_in(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(Guardian).to receive(:is_admin?).and_return(true) if user.admin
    allow_any_instance_of(Guardian).to receive(:is_staff?).and_return(true) if user.moderator || user.admin
  end
end
