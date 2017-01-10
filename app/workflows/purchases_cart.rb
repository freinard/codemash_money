class PurchasesCart

  attr_accessor :user, :purchase_amount_cents,
      :purchase_amount, :success,
      :payment, :expected_ticket_ids,
      :stripe_token, :stripe_charge

  def initialize(user:, stripe_token:, purchase_amount_cents:,
      expected_ticket_ids:)
    @user = user
    @purchase_amount = Money.new(purchase_amount_cents)
    @success = false
    @continue = true
    @expected_ticket_ids = expected_ticket_ids.split(" ").map(&:to_i).sort
    @stripe_token = stripe_token
  end

  def run
    Payment.transaction do
      pre_purchase
      purchase
      post_purchase
      @success = @continue
    end
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("ACTIVE RECORD ERROR IN TRANSACTION")
    Rails.logger.error(e)
  end

  def pre_purchase
    unless pre_purchase_valid?
      @continue = false
      return
    end
    purchase_tickets
    create_payment
    @continue = true
  end

  def pre_purchase_valid?
    purchase_amount == tickets.map(&:price).sum &&
        expected_ticket_ids == tickets.map(&:id).sort
  end

  def tickets
    @tickets ||= @user.tickets_in_cart
  end

  def purchase_tickets
    tickets.each(&:purchased!)
  end

  def create_payment
    self.payment = Payment.create!(payment_attributes)
    payment.create_line_items(tickets)
  end

  def payment_attributes
    {user_id: user.id, price_cents: purchase_amount.cents,
     status: "created", reference: Payment.generate_reference,
     payment_method: "stripe"}
  end

  def purchase
    return unless @continue
    @stripe_charge = StripeCharge.new(token: stripe_token, payment: payment)
    @stripe_charge.charge
    payment.update!(@stripe_charge.payment_attributes)
    reverse_purchase if payment.failed?
  end

  def charge
    charge = StripeCharge.charge(token: stripe_token, payment: payment)
    payment.update!(
        status: charge.status, response_id: charge.id,
        full_response: charge.to_json)
  end

  def calculate_success
    payment.succeeded?
  end

  def post_purchase
    return unless @continue
    @continue = calculate_success
  end

  def calculate_success
    payment.succeeded?
  end

  def post_purchase
    return unless @continue
    @continue = calculate_success
  end

  def unpurchase_tickets
    tickets.each(&:waiting!)
  end

  def reverse_purchase
    unpurchase_tickets
    @continue = false
  end

end
