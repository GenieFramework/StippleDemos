using Genie, Genie.Renderer.Html, Stipple, StipplePlotly, Colors, ColorSchemes

Genie.config.log_requests = false

plotly_palette = ["Greys", "YlGnBu", "Greens", "YlOrRd", "Bluered", "RdBu", "Reds", "Blues", "Picnic", "Rainbow", "Portland", "Jet", "Hot", "Blackbody", "Earth", "Electric", "Viridis", "Cividis"]

function rgb(pix::RGB{Float64})
  R = round(Int, 255 * clamp(pix.r, 0.0, 1.0))
  G = round(Int, 255 * clamp(pix.g, 0.0, 1.0))
  B = round(Int, 255 * clamp(pix.b, 0.0, 1.0))
  return "rgb($R,$G,$B)"
end

# See: https://juliagraphics.github.io/ColorSchemes.jl/stable/basics/
function ColorScale(scheme::Symbol, N = 101)
  x = permutedims(0.0:(1.0/(N - 1)):1.0)
  cs = get(colorschemes[scheme], x, :clamp)
  cs_rgb = rgb.(cs)
  return vcat(x, cs_rgb)
end

function to_plotly_standard(x)
  if isnothing(x)
    m = "null"
  elseif ismissing(x)
    m = "null"
  elseif isa(x, AbstractString)
    m = x
  elseif isinf(x)
    m = "null"
  elseif isnan(x)
    m = "null"
  else
    m = x
  end
  return m
end

pd(name) = PlotData(
  z =  to_plotly_standard.(round.([100.0 0.0  missing;
       30.30235455584154  94.9495352852204 0.7150792978758869;
       63.172349721957175 37 -72.02122607433563;
       51.19876097916769  18.676411380287483 314.15;
       87.03992589163836  88.74217734803698 62.122844059857215]; sigdigits=3)),
  zmin = 0.0,
  zmax = 100.0,
  x = ["L0", "L63", "L128", "L191", "L255"],
  y = ["L255", "L128", "L0"],
  plot = StipplePlotly.Charts.PLOT_TYPE_HEATMAP,
  name = name,
  colorscale = ColorScale(:algae),
  colorbar = ColorBar("Z-data", 18, "right"),
  hoverongaps = false,
  hoverinfo = "x+y+z"
)

pl(title) = PlotLayout(
  plot_bgcolor = "#FFFFFF",
  title = PlotLayoutTitle(text=title, font=Font(24)),
  margin_b = 25,
  margin_t = 80,
  margin_l = 80,
  margin_r = 40,
  xaxis = [PlotLayoutAxis(xy = "x", index = 1,
    title = "From",
    font = Font(18),
    ticks = "outside top",
    side = "top",
    position = 1.0,
    showline = true,
    showgrid = false,
    zeroline = false,
    mirror = "all",
    ticklabelposition = "outside top")],
  yaxis = [PlotLayoutAxis(xy = "y", index = 1,
    showline = true,
    zeroline = false,
    mirror = "all",
    showgrid = false,
    title = "To",
    font = Font(18),
    ticks = "outside",
    scaleanchor = "x",
    scaleratio = 1,
    constrain = "domain",
    constraintoward = "top")],
)

Base.@kwdef mutable struct Model <: ReactiveModel
  data::R{Vector{PlotData}} = [pd("Random 1")], READONLY
  layout::R{PlotLayout} = pl(""), READONLY
  config::R{PlotConfig} = PlotConfig(), READONLY
end

model = Stipple.init(Model())

function ui()
  page(
    vm(model), class="container", [
      plot(:data, layout = :layout, config = :config)
    ]
  ) |> html
end

route("/", ui)

up()
