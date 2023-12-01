# Test of `@mixins` from branch hh-rm-mixins (https://github.com/GenieFramework/Stipple.jl/pull/245)

using Stipple, Stipple.ReactiveTools
using StippleUI

@app GreetMixin begin
  @in name = "John Doe"

  @onchange name begin
    println("'name' changed to $(name)!")
  end

end greet_handlers

@mounted GreetMixin = "console.log('Just mounted the App including the GreetMixin')"

@methods GreetMixin :greet => "function() { console.log('Hi ' + this.name + '!') }"

@mixins [GreetMixin]

@app begin
  @mixin GreetMixin
  @in s = "Hi"
  @in i = 10

  @onchange i begin
    println("'i' changed to $(i)!")
  end
end

ui() = row(cell(class = "st-module", [
  cell(class = "q-my-md q-pa-md bg-green-3", "Name: {{name}}")
  cell(class = "q-my-md q-pa-md bg-green-4", "i: {{i}}")
  
  btn("client mixin 'greet'", @click("greet"), color = "red-3", nocaps = true)
  btn(class = "q-ml-md", "backend mixin '@onchange name'", @click("name = 'John ' + (name.endsWith('Doe') ? 'Dough' : 'Doe')"), color = "red-3", nocaps = true)
]))

@page("/", ui)

up(open_browser = true)