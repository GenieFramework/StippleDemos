module App

using GenieFramework

@genietools

@app begin
  @out name = ""
  @out age = 0
  @out objects = ["Dog", "Cat", "Beer"]
  @out warin = true
  @out accept = false
end

function ui()
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
        )
      ],
      @on(:submit, "onSubmit"),
      @on(:reset, "onReset"),
      class = "q-gutter-md",
    ) 
  ]
end

@client_data begin
  client_name = nothing
  client_age = nothing
  accept = false
end

@methods """
onSubmit () {
  console.log(this.accept)
  if (this.accept !== true) {
    this.\$q.notify({
      color: 'red-5',
      textColor: 'white',
      icon: 'warning',
      message: 'You need to accept the license and terms first'
    })
  }
  else {
    this.\$q.notify({
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

@page("/", ui)

end