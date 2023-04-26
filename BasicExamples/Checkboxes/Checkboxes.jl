using Stipple
using StippleUI

@vars Model begin
  valone::R{Bool} = false
  valtwo::R{Bool} = false
  valthree::R{Bool} = false
end

function ui(my_model)
  page(
    my_model,
    class = "container",
    [
      checkbox(label = "Apples", fieldname = :valone, dense = true),
      checkbox(label = "Bananas", fieldname = :valtwo, dense = true),
      checkbox(label = "Mangos", fieldname = :valthree, dense = true),
    ],
  )
end

my_model = Stipple.init(Model)

route("/") do
  html(ui(my_model), context = @__MODULE__)
end

up(async = true)
