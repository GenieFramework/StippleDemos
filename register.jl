using Stipple, StippleUI

Base.@kwdef mutable struct RegistrationModel <: ReactiveModel
  name::R{String} = ""
  email::R{String} = ""
  registered_email::R{Bool} = false
  password::R{String} = ""
  signup::R{Bool} = false
  # disable::R{Bool} = true
end

model = Stipple.init(RegistrationModel())

# a database of registered emails
email_db = Set(["a@b.com", "aa@bb.com"])

# for each email, check to see if it's already registered in our database
on(model.email) do email
  model.registered_email[] = email ∈ email_db
end

# these are the tests to see if input is valid or not, except for checking if an email is already registered or not, all of these are done on the client and not on the server: winning!
Stipple.js_computed(model::RegistrationModel) = """
  email_msg: function () {
    if (this.email.length == 0) {
      return 'email cannot be empty'
    } else if (this.registered_email) {
      return 'email already registered in our database'
    } else {
      return ''
    }
  },
  name_msg: function () {
    if (this.name.length == 0) {
      return 'name cannot be empty'
    } else {
      return ''
    }
  },
  password_msg: function () {
    if (this.password.length == 0) {
      return 'password cannot be empty'
    } else {
      return ''
    }
  }
"""

function register()
  app = dashboard(vm(model),
                  [
                   heading("Registration"),
                   row(cell(class="st-module", [
                                                p(["Name", input("", placeholder="Type your name", @bind(:name), type = "text")]),
                                                p([span("", @text(:name_msg))]),
                                                p(["Email", input("", placeholder="Type your email", @bind(:email), type = "email")]),
                                                p([span("", @text(:email_msg))]),
                                                p(["Password", input("", placeholder="Type a password", @bind(:password), type = "password")]),
                                                p([span("", @text(:password_msg))]),
                                                p(btn("Sign up", @click(:signup), disable = :disable)),
                                               ])),
                  ], title = "Registration")
  html(app)
end

route("/", register)
up(open_browser = true)

