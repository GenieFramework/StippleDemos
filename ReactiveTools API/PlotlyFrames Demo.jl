# Streamgraph / Bump Chart in Julia using PlotlyJS
# Animated version – smooth transitions via Plotly.js frames

using Random

using Stipple, Stipple.ReactiveTools
using StippleUI
using StipplePlotly
using PlotlyBase

Stipple.enable_model_storage(false)

# -- data generation ----------------------------------------------------------

function bump!(a::Vector{Float64})
    n = length(a)
    x = 1.0 / (0.1 + rand())
    y = 2.0 * rand() - 0.5
    z = 10.0 / (0.1 + rand())
    for i in 1:n
        w = ((i - 1) / n - y) * z
        a[i] += x * exp(-w^2)
    end
end

function bumps(n::Int, m::Int)::Vector{Float64}
    a = zeros(Float64, n)
    for _ in 1:m
        bump!(a)
    end
    return a
end

# -- parameters ---------------------------------------------------------------

const M = 200        # x-axis points per frame
const N = 9          # stacked layers
const K = 10         # bumps per layer
const N_FRAMES = 12  # animation frames
const FRAME_MS = 1600
const TRANSITION_MS = 1200

const COOL_COLORS = [
    "rgba(109,182,217,0.85)",
    "rgba(68,155,201,0.85)",
    "rgba(38,120,178,0.85)",
    "rgba(24,90,154,0.85)",
    "rgba(20,63,127,0.85)",
    "rgba(30,40,100,0.85)",
    "rgba(75,30,110,0.85)",
    "rgba(130,28,120,0.85)",
    "rgba(190,50,110,0.85)",
]

# -- helpers ------------------------------------------------------------------

function make_traces(seed::Int; values_only::Bool = false, n = N, m = M, k = K)
    Random.seed!(seed)
    x_vals = collect(0:(m - 1))
    layers = [bumps(m, k) for _ in 1:n]
    values_only && return attr(y = layers)
    # layers = reverse(cumsum(layers))

    traces = GenericTrace[]
    for i in 1:n
        push!(traces, scatter(
            x         = x_vals,
            y         = layers[i],
            fill      = i == 1 ? "tozeroy" : "tonexty",
            fillcolor = COOL_COLORS[i],
            line      = attr(color = COOL_COLORS[i], width = 0.5, simplify = false),
            name      = "Layer $(i)",
            stackgroup = "one",
        ))
    end
    return traces
end

# -- build animated chart -----------------------------------------------------

function make_streamgraph(; seed::Int = 42, n = N, m = M, k = K, n_frames = N_FRAMES, frame_ms = FRAME_MS, transition_ms = TRANSITION_MS)
    layout = PlotlyBase.Layout(
        title         = attr(text = "Streamgraph", font = attr(size = 18)),
        # width         = 928,
        # height        = 500,
        paper_bgcolor = "#1a1a2e",
        plot_bgcolor  = "#1a1a2e",
        font          = attr(color = "white"),
        xaxis         = attr(showgrid = false, zeroline = false, color = "white"),
        yaxis         = attr(showgrid = false, zeroline = false, color = "white", range = [0, 20]),
        legend        = attr(bgcolor = "rgba(0,0,0,0)", font = attr(color = "white")),
        hovermode     = "x unified",
        showlegend = false,
    )

    p = Plot(make_traces(seed, n = n, m = m, k = k), layout)

    p.frames = [
        frame(data = make_traces(seed + 137i; n, m, k), name = "f$i", values_only = true) for i in 1:n_frames
    ]

    return p
end


@app MyApp begin
    @in plot::Plot = make_streamgraph()
    @in frame::Int = 0
    @in looping::Bool = false
    @out loop_label::String = "Loop"

    @onchange looping on_looping()
end

@watch MyApp js"""
    frame(i) { this.\$refs.frameplot.animate(['f' + i], {
        transition: { duration: $TRANSITION_MS, easing: 'linear-in-out' },
        frame:      { duration: $FRAME_MS, redraw: false },
        mode:       'immediate'
    }) }
"""i

@methods MyApp js"""
    nextFrame() {
        this.frame = (this.frame % (this?.plot?.frames?.length || 1)) + 1
    }
"""

@handler MyApp function on_looping()
    loop_label = looping ? "Stop Looping" : "Loop"
    looping || return
    @async while looping
        frame = (frame % length(plot.frames)) + 1
        sleep(FRAME_MS / 1000)
    end
end

ui() = row(class = "st-module", cell(row(@gutter(:sm, [
    btn(col = 6, class = "full-width", "Next Frame", icon = "forward", @click("nextFrame()")),
    btn(col = 6, class = "full-width", :looping, icon = "loop", label = :loop_label, @click("looping = !looping")),
    cell(col = 12, plotly(col = 10, class = "full-width", id = "myDiv", ref = "frameplot", :plot))
]), col = 12)))

@page("/", ui, model = MyApp, debounce = 0)

up(open_browser = true)