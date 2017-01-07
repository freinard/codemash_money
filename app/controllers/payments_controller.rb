class PaymentsController < ApplicationController

  def show
    @payment = Payment.find_by(reference: params[:id])
  end

  def create
    @tickets ||= current_user.tickets_in_cart
    @tickets.each(&:purchased!)
    @payment = Payment.create!(
        user_id: current_user.id,
        reference: Payment.generate_reference,
        price_cents: params[:purchase_amount_cents],
        status: "created")
    @payment.create_line_items(@tickets)
    redirect_to payment_path(id: @payment.reference)
  end

end
