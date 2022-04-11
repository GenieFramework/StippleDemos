using Stipple, StippleUI

@reactive mutable struct FormComponent <: ReactiveModel
  name::R{String} = ""
  age::R{Int} = 0
  objects::R{Vector} = ["Dog", "Cat", "Beer"]
  warin::R{Bool} = true
end

myform() = xelem(
  :div,
  class = "q-pa-md",
  style = "max-width: 400px",
  [
    StippleUI.form(
      [
        textfield(
          "What's your name *",
          :client_name,
          @iif(:warin),
          :filled,
          hint = "Name and surname",
          "lazy-rules",
          rules = "[val => val && val.length > 0 || 'Please type something']",
        ),
        numberfield(
          "Your age *",
          :client_age,
          "filled",
          :lazy__rules,
          rules = """[
                val => val !== null && val !== '' || 'Please type your age',
                val => val > 0 && val < 100 || 'Please type a real age'
            ]""",
        ),
        toggle("I accept the license and terms", :accept),
        Stipple.Html.div(
          [
            btn("Submit", type = "submit", color = "primary")
            btn("Reset", type = "reset", color = "primary", :flat, class = "q-ml-sm")
          ],
        ),
        p(
          "Bad stuff's about {{object}} to happen",
          class = "warning",
          @recur(:"object in objects")
        ),
      ],
      @on(:submit, "onSubmit"),
      @on(:reset, "onReset"),
      class = "q-gutter-md",
    ),
  ],
)

import Stipple.js_methods
js_methods(m::FormComponent) = raw"""
    onSubmit () {
      if (this.accept !== true) {
        this.$q.notify({
          color: 'red-5',
          textColor: 'white',
          icon: 'warning',
          message: 'You need to accept the license and terms first'
        })
      }
      else {
        this.$q.notify({
          color: 'green-4',
          textColor: 'white',
          icon: 'cloud_done',
          message: 'Submitted'
        });
        this.name = this.client_name;
        this.age = this.client_age;
      }
    },
    onReset () {
      console.log(this.client_name)  // Hit F12 open console and you should see name
      console.log(this.client_age)  // Hit F12 open console tab and you should see age
      this.client_name = null
      this.client_age = null
      this.accept = false
    }
  """

import Stipple.client_data
client_data(m::FormComponent) =
  client_data(client_name = js"null", client_age = js"null", accept = false)

function ui(model)
  page(model, class = "container", title = "Hello Stipple", myform())
end

# Using Genie Route to serve ui
route("/") do
  hs_model = FormComponent |> init |> ui
end

up()
