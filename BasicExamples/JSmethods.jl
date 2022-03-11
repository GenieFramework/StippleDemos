using Stipple, StippleUI

Base.@kwdef mutable struct JSmethods <: ReactiveModel
  x::R{Int} = 0 # pressing this will update the array of buttons
end

function restart()
  global hs_model
  hs_model = Stipple.init(JSmethods(), debounce = 1)
  on(println, hs_model.x)
end

Stipple.js_methods(::JSmethods) = raw"""
    showNotif () {
    alert("Welcome to JSMethods!") // some blocking javascript. Hit "OK" on alert to proceed with notification 
    this.$q.notify({
    message: 'I am notifying you!',
    color: 'purple'
    })
    }
"""

function ui()
  app = dashboard(
    vm(hs_model),
    [
      heading("jsmethods"),
      row(cell(class = "st-module", [p(button("Notify me", @click("showNotif()")))])),
    ],
    title = "jsmethods",
  )

  html(app)
end

route("/", ui)
restart()
