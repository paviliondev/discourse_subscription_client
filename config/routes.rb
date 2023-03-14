# frozen_string_literal: true

DiscourseSubscriptionClient::Engine.routes.draw do
  get "" => "admin#index"
  get ".json" => "admin#index"
  get "no-access" => "admin#index"

  get "suppliers" => "suppliers#index"
  get "suppliers/authorize" => "suppliers#authorize"
  get "suppliers/authorize/callback" => "suppliers#authorize_callback"
  delete "suppliers/authorize" => "suppliers#destroy"

  get "subscriptions" => "subscriptions#index"
  post "subscriptions" => "subscriptions#update"

  get "notices" => "notices#index"
  put "notices/:notice_id/dismiss" => "notices#dismiss"
  put "notices/:notice_id/hide" => "notices#hide"
  put "notices/:notice_id/show" => "notices#show"

  get "no-access" => "no_access#index"
end
