using Stipple
import Stipple: opts, OptDict

# Define the model
# Note the Stipple.@kwdef which is a redefineable version of Base.@kwdef as long as Stipple is in dev mode
Stipple.@kwdef mutable struct Example <: ReactiveModel
  s::R{String} = "..."
  n::R{Int} = 1
  a::R{Array} = [3, 2, 1]
end

model = Stipple.init(Example(), debounce = 0)

function ui()
  page(vm(model), class="container", title="Hello Stipple", [
    h1("Hello World")
    p("I am the first paragraph and I bring you")
    p("", @text(:s))

  ]) |> html
end

route("/", ui)

up(open_browser=true)

model.s[] = "Stipple!"


## Number and array modification
function ui()
  page(vm(model), class="container", title="Hello Stipple", [
    h1("Hello World"),

    p("I am the first paragraph and I bring you"),

    p("", @text(:s)),

    p([
      "Here we have our first number: "
      span("", @text(:n))
    ]),

    p([
      "And here is our first array: "
      span("", @text(:a))
    ])
  ]) |> html
end

# Count down!
for i = 10:-1:0
  model.n[] = i
  sleep(1)
end

# notifying assignment of new array
model.a[] = 1:2:9

# modification of array elements is non-notifying!
model.a[][2] = 10

# notifying modification of array elements
model.a[2] = 11

# non-notifying syntax for full arrays
model.a[!] = 1:2:9

# manual notification of change
notify(model.a)

# non-notifying syntax is working for all Reactive types
model.s[!] = "Hello Stipple!"

notify(model.s)

# on the js side call: `Example.a.__ob__.dep.notify()`


## Binding of array elements
function ui()
  page(vm(model), class="container", title="Hello Stipple", [
    h1("Hello World")

    p("I am the first paragraph and I bring you")

    p("", @text(:s))

    p([
      "Here we have our first number: "
      span("", @text(:n))
    ])

    p([
      "And here is our first array: "
      span("", @text(:a))
    ])

    p([
        "What is your name? ",
        input("", placeholder="Type your name", @bind(:s))
    ])

    p([
      "What is your amount? ",
      input("", placeholder="Type your name", @bind("a[1]", "number"))
    ])
  ]) |> html
end


updateinfo = on(model.a) do a
  @info "a was updated!"
  @show a
end

on(model.a) do x
  model.s[] = "a was updated to `$x`"
end

off(updateinfo)

function ui()
  page(vm(model), class="container", title="Hello Stipple", [
    h1("Hello World")

    p("I am the first paragraph and I bring you")

    p("", @text(:s))

    p([
      "Here we have our first number: "
      span("", @text(:n))
    ])

    p([
      "And here is our first array: "
      span("", @text(:a))
    ])

    p([
        "What is your name? ",
        input("", placeholder="Type your name", @bind(:s))
    ])

    p([
      "What is your place? ",
      input("", placeholder="Type your name", @bind(:n, "number"))
    ])

    p([
      "What is your amount? ",
      input("", placeholder="Type your name", @bind("a[n]", "number"))
    ])

    slider(0:100, Symbol("a[1]"))
  ]) |> html
end

## mode attributes
Stipple.@kwdef mutable struct Example <: ReactiveModel
  s::R{String} = "..."
  a::R{Array} = [3, 2, 1], PUBLIC
  n::R{Int} = 1, READONLY
  i::R{Int} = 1, PRIVATE

  d::R{Dict{Symbol, Any}} = opts(hello = "World"), JSFUNCTION
  f::R{JSONText} = JSONText("function() { return Example.n + 1 }"), JSFUNCTION
end

model = Stipple.init(Example(), debounce = 0)


## passing functions

model.d[:f] = js"function() { return Example.n + 1 }"

model.f[] = js"""function() { alert("The value of n is: " + this.n); return this.n + 1 }"""

model.f[] = js"() => this.n"

model.f[] = js"""Function(""," return this.n ")"""


## patterns for modes
Stipple.@kwdef mutable struct Example <: ReactiveModel
  s::String = "..."
  s_::String = "I'm readonly"
  s__::String = "You don't see me!"

  a::R{Array} = [3, 2, 1]   # PUBLIC
  n::R{Int} = -1            # PUBLIC
  n_::R{Int} = -1           # READONLY
  i__::R{Int} = 0           # PRIVATE

  d::R{Dict{Symbol, Any}} = opts(hello = "World"), JSFUNCTION
  f::R{JSONText} = js"""Function(""," return this.n_ ")""", JSFUNCTION
end

model = Stipple.init(Example())


'' Some more content, which didn't fit in the presentation :-)


## More than one model
models = Dict{Any, Example}()
route("/") do
  global lastparams, lastheaders, models
  lastparams = @params
  lastheaders = Genie.Requests.getheaders()
  user = first(split(lastheaders["User-Agent"]))
  if haskey(models, user)
    @info "using existing model of user '$user'."
  else
    @info "creating new model for user '$user' ..."
    models[user] = Stipple.init(Example())
  end
  ui(models[user])
end

lastparams
lastheaders


sc = sessioncookie(getcookies2(lastheaders["Cookie"]))
user = hash(sc)
getcookies(s) = Dict([Pair(strip.(split(c, "=", limit = 2), '"')...)  for c in split(s, "; ")])
getcookies2(s) = Dict([m.captures for m in eachmatch(r"""([^\s=]+)=(?>")?((?(2)[^"]+|[^;]+))""", s)])
sessioncookie(d) = first(values(d))

getcookies(lastheaders["Cookie"])
getcookies2(lastheaders["Cookie"])

sessioncookie(getcookies2(lastheaders["Cookie"]))

