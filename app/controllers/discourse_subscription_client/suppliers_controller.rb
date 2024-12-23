# frozen_string_literal: true

module DiscourseSubscriptionClient
  class SuppliersController < AdminController
    before_action :ensure_can_manage_suppliers
    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token, only: %i[authorize authorize_callback]
    before_action :find_supplier, only: %i[authorize destroy]

    def index
      suppliers = SubscriptionClientSupplier.all
      if params[:resource]
        suppliers = suppliers
                    .joins(:resources)
                    .where(resources: { name: params[:resource] })
      end
      render_serialized(suppliers, SupplierSerializer, root: "suppliers")
    end

    def authorize
      session[:final_landing_path] = params[:final_landing_path]

      request_id = DiscourseSubscriptionClient::Authorization.request_id(@supplier.id)
      cookies[:user_api_request_id] = request_id
      redirect_to DiscourseSubscriptionClient::Authorization.url(current_user, @supplier, request_id).to_s,
                  allow_other_host: true
    end

    def authorize_callback
      payload = params[:payload]
      request_id = cookies[:user_api_request_id]
      supplier_id = request_id.split("-").first

      data = DiscourseSubscriptionClient::Authorization.process_response(request_id, payload)
      raise Discourse::InvalidParameters, :payload unless data

      supplier = SubscriptionClientSupplier.find(supplier_id)
      raise Discourse::InvalidParameters, :supplier_id unless supplier

      supplier.update(
        api_key: data[:key],
        user_id: data[:user_id],
        authorized_at: DateTime.now.iso8601(3)
      )

      DiscourseSubscriptionClient::Subscriptions.update

      if !session[:final_landing_path].blank?
        redirect_to session[:final_landing_path]
      else
        redirect_to "/admin/plugins"
      end
    end

    def destroy
      if @supplier.destroy_authorization
        render json: success_json.merge(supplier_id: @supplier.id)
      else
        render json: failed_json
      end
    end

    protected

    def find_supplier
      params.require(:supplier_id)
      @supplier = SubscriptionClientSupplier.find(params[:supplier_id])
      raise Discourse::InvalidParameters, :supplier_id unless @supplier
    end

    def ensure_can_manage_suppliers
      Guardian.new(current_user).ensure_can_manage_suppliers!
    end
  end
end
