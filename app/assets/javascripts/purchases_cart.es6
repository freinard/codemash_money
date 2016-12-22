class CheckoutForm {

  form() { return $("#payment-form") }

  button() { return this.form().find(".btn") }

  disableButton() { this.button().prop("disabled", true) }

  isButtonDisabled() { return this.button().prop("disabled") }

  submit() { this.form().get(0).submit() }

  appendHidden(name, value) {
    const field = $("<input>")
      .attr("type", "hidden")
      .attr("name", name)
      .val(value)
    this.form().append(field)
  }
}

class StripeForm {

  constructor() {
    this.checkoutForm = new CheckoutForm()
    this.initSubmitHandler()
  }

  initSubmitHandler() {
    this.checkoutForm.form().submit((event) => { this.handleSubmit(event) })
  }

  handleSubmit(event) {
    event.preventDefault()
    if (this.checkoutForm.isButtonDisabled()) {
      return false
    }
    this.checkoutForm.disableButton()
    this.checkoutForm.submit()
    return false
  }
}

$(() => new StripeForm())
