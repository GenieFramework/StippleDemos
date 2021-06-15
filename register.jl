using Stipple, StippleUI

Base.@kwdef mutable struct RegistrationModel <: ReactiveModel
  name::R{String} = ""
  email::R{String} = ""
  new_email::R{Bool} = true
  password::R{String} = ""
  submit::R{Bool} = false
end

model = Stipple.init(RegistrationModel())

# a database of registered emails
email_db = Set(["a@b.com", "aa@bb.com"])

# for each email, check to see if it's already registered in our database
on(model.email) do email
  model.new_email[] = email ∉ email_db
end

# these are the tests to see if input is valid or not, except for checking if an email is already registered or not, all of these are done on the client and not on the server: winning!
Stipple.js_methods(model::RegistrationModel) = """
myRule (val) {
  return new Promise((resolve, reject) => {
    setTimeout(() => {
      resolve(!val || this.new_email || 'email already registered in our database')
    }, 1000)
  })
},
onSubmit () {
        this.\$q.notify({
          color: 'green-4',
          textColor: 'white',
          icon: 'cloud_done',
          message: 'Submitted'
        })
    }
"""

function register()
  app = dashboard(vm(model),
                  [
                   heading("Registration"),
                                                Stipple.form([
                                                textfield("Your name *", :name, type = "text", filled = true, hint="Name and surname", lazy_rules = true, rules="[ val => val && val.length > 0 || 'Please type something' ]"),
                                                textfield("Your email *", :email, type = "email", filled = true, hint="Email", lazy_rules = true, rules="[ val => val && val.length > 0 || 'Please type something']"), # add this if you want to have the server side checks for an already registered email:         , myRule ]"),
                                                textfield("Password *", :password, type = "password", filled = true, hint="A password", lazy_rules = true, rules="[ val => val && val.length > 0 || 'Please type something' ]"),
                                                btn("Sign up", @click("onSubmit"), type = "submit")
                                               ]), ])
  html(app)
end

route("/", register)
up(open_browser = true)

