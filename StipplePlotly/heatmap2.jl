using Genie, Genie.Renderer.Html, Stipple, StipplePlotly, Colors, ColorSchemes

Genie.config.log_requests = false

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

xx = ["L0", "L63", "L128", "L191", "L255"]
yy = ["L255", "L128", "L0"]
zz = [ 100.0 0.0  missing;
       31.30235455584154  94.9495352852204 0.7150792978758869;
       63.172349721957175 37 -72.02122607433563;
       51.19876097916769  18.676411380287483 314.15;
       87.03992589163836  88.74217734803698 62.122844059857215];

cs = :algae # color scheme

function textcolor_mask(z,zmin,zmax,cs; halfluminance=(0.5^2.2))
  m = zeros(Float64, size(z))
  for i=1:length(m)
    if !ismissing(z[i])
      c = get(colorschemes[cs], Float64(z[i]), (zmin,zmax))
      if xyY(c).Y < halfluminance
        m[i] = 1.0
      end
    end
  end
  m
end

function annotate_map(x, y, z, zmin, zmax, cs)
  m = textcolor_mask(z,zmin,zmax,cs; halfluminance=(0.5^2.2))
  anv = Vector{PlotAnnotation}(undef, 0)
  anv = PlotAnnotation[]
  for i=1:size(z,1)
    for j=1:size(z,2)
      c = rgb(RGB(m[i,j], m[i,j], m[i,j]))
      an = PlotAnnotation(visible=!ismissing(z[i,j]), x=x[i], y=y[j], xref="x", yref="y", text= "$(round(z[i,j]; sigdigits=3))", ax=0, ay=0, showarrow=false, font=Font(color=c, size=16) )
      push!(anv, an)
    end
  end
  anv
end

anv = annotate_map(xx, yy, zz, 0.0, 100.0, cs);

pd(name, x, y, z; zmin = 0.0, zmax = 100.0, cs = cs) = PlotData(
  z =  to_plotly_standard.(round.(z; sigdigits=3)),
  zmin = zmin,
  zmax = zmax,
  x = x,
  y = y,
  plot = StipplePlotly.Charts.PLOT_TYPE_HEATMAP,
  name = name,
  colorscale = ColorScale(cs),
  colorbar = ColorBar("Z-data", 18, "right"),
  hoverongaps = false,
  hoverinfo = "x+y+z"
)

pl(title; annotations::Union{Nothing, Vector{PlotAnnotation}} = nothing) = PlotLayout(
  plot_bgcolor = "#FFFFFF",
  title = PlotLayoutTitle(text=title, font=Font(24)),
  margin_b = 25,
  margin_t = 80,
  margin_l = 60,
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
  annotations = annotations
)

Base.@kwdef mutable struct Model <: ReactiveModel
  data::R{Vector{PlotData}} = [pd("Random 1", xx, yy, zz)], READONLY
  layout::R{PlotLayout} = pl(""; annotations=anv), READONLY
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
