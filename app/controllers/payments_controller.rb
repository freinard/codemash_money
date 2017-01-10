class PaymentsController < ApplicationController

  def show
    @payment = Payment.find_by(reference: params[:id])
  end

  def create
    workflow = PurchasesCart.new(
        user: current_user, stripe_token: params[:stripe_token],
        purchase_amount_cents: params[:purchase_amount_cents],
        expected_ticket_ids: params[:ticket_ids])
    workflow.run
    if workflow.success
      redirect_to payment_path(id: workflow.payment.reference)
    else
      redirect_to shopping_cart_path
    end
  end

end
