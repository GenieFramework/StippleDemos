module App

using GenieFramework

@genietools

@app begin
  @out step = "1"
end

function ui()
  [
    stepper(:step, ref="stepper",color="primary", animated=true,
      [
        qstep("For each ad campaign that you create, you can control how much you're willing to
        spend on clicks and conversions, which networks and geographical locations you want
        your ads to show on, and more.", name! ="1", title="Select campaign settings",
        icon="settings", done! ="step > 1"),
        qstep("An ad group contains one or more ads which target a shared set of keywords.",
           name! = "2", title="Create an ad group", caption="Optional", icon="create_new_folder", done! = "step > 2"),
        qstep("This step won't show up because it is disabled.",
           name! ="3",
           title="Ad template",
           icon="assignment",
           disable=true,
        )
      ]
    ),
    template("", "v-slot:navigation",
      steppernavigation([
        btn(color="primary", label! ="step === 3 ? 'Finish' : 'Continue'", @click("$refs.stepper.next()")),
        btn(@iif("step > 1"), flat = true, color="primary", label="Back", class="q-ml-sm", @click("$refs.stepper.previous()") ),
      ])
    )
  ]
end

@page("/", ui)

end