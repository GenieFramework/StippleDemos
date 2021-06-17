# this produces identical behavior to the Quasar form in https://quasar.dev/vue-components/form#example--basic
# this example was written by @hhaensel (see [here](https://github.com/GenieFramework/Stipple.jl/issues/57#issuecomment-862641950))

using Stipple, StippleUI

const NO = StippleUI.NO_WRAPPER

Stipple.@kwdef mutable struct Example <: ReactiveModel
    name::R{String} = ""
    age::R{Int} = 0
end

model = Stipple.init(Example())

myform() = xelem(:div, class="q-pa-md", style="max-width: 400px", [
    StippleUI.form([
        textfield("Your name *", :client_name,
            :filled,
            hint="Name and surname",
            "lazy-rules",
            rules = "[val => val && val.length > 0 || 'Please type something']"
        ),
        numberfield("Your age *", :client_age,
            :filled,
            :lazy__rules,
            rules="""[
                val => val !== null && val !== '' || 'Please type your age',
                val => val > 0 && val < 100 || 'Please type a real age'
            ]"""
        ),
        toggle("I accept the license and terms", :accept, wrap=NO),
        Stipple.Html.div([
            btn("Submit", type="submit", color="primary", wrap=NO)
            btn("Reset", type="reset", color="primary", :flat, class="q-ml-sm", wrap=NO)
        ])
    ], @on(:submit, "onSubmit"), @on(:reset, "onReset"), class="q-gutter-md", wrap=NO)
])

import Stipple.js_methods
js_methods(m::Example) = raw"""
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
      this.client_name = null
      this.client_age = null
      this.accept = false
    }
  """

import Stipple.client_data
client_data(m::Example) = client_data(client_name = js"null", client_age = js"null", accept = false)

function ui()
    page(vm(model), class="container", title="Hello Stipple", 
        myform()
    )
end

route("/", ui)
up(open_browser=true)


