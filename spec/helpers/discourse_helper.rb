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
    ApplicationController.any_instance.stub(:current_user) { user }
    Guardian.any_instance.stub(:is_admin?) { true } if user.admin
    Guardian.any_instance.stub(:is_staff?) { true } if user.moderator || user.admin
  end
end
