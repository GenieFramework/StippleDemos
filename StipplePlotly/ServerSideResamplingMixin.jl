# Server-side resampling with `@mixin`
# this approach comes in handy if you have more than one plot that should be resampled
# Stipple v0.30.5 required or line 130 must replaced by line 132

using Stipple, Stipple.ReactiveTools
using StippleUI
using StipplePlotly
using PlotlyBase

import Statistics: mean
import Stipple: opts

const PBLayout = PlotlyBase.Layout
 
"""
    x, y = lttb(v::AbstractVector, n = length(v)÷10)
 
The largest triangle, three-buckets reduction of the vector `v` over points `1:N` to a
new, shorter vector `y` at `x` with `length(x) == n`.
 
See https://skemman.is/bitstream/1946/15343/3/SS_MSthesis.pdf

#### Acknowledgement
This implementation is taken from https://gist.github.com/jmert/4e1061bb42be80a4e517fc815b83f1bc
"""
function lttb(v::AbstractVector, n = length(v)÷10)
    N = length(v)
    N == 0 && return similar(v)
 
    w = similar(v, n)
    z = similar(w, Int)
 
    # always take the first and last data point
    @inbounds begin
        w[1] = y₀ = v[1]
        w[n] = v[N]
        z[1] = x₀ = 1
        z[n] = N
    end
 
    # split original vector into buckets of equal length (excluding two endpoints)
    #   - s[ii] is the inclusive lower edge of the bin
    s = range(2, N, length = n-1)
    @inline lower(k) = round(Int, s[k])
    @inline upper(k) = k+1 < n ? round(Int, s[k+1]) : N-1
    @inline binrange(k) = lower(k):upper(k)
 
    # then for each bin
    @inbounds for ii in 1:n-2
        # calculate the mean of the next bin to use as a fixed end of the triangle
        r = binrange(ii+1)
        x₂ = mean(r)
        y₂ = sum(@view v[r]) / length(r)
 
        # then for each point in this bin, calculate the area of the triangle, keeping
        # track of the maximum
        r = binrange(ii)

        x̂, ŷ, Â = first(r), v[first(r)], typemin(y₀)
        for jj in r
            x₁, y₁ = jj, v[jj]
            # triangle area:
            A = abs(x₀*(y₁-y₂) + x₁*(y₂-y₀) + x₂*(y₀-y₁)) / 2
            # update coordinate if area is larger
            if A > Â
                x̂, ŷ, Â = x₁, y₁, A
            end
            x₀, y₀ = x₁, y₁
        end
        z[ii+1] = x̂
        w[ii+1] = ŷ
    end
 
    return (z, w)
end
 
function lttb!(trace::AbstractTrace, range::Union{Nothing, AbstractVector}, threshold::Int)
    n = max(length(trace.y), length(trace.x))
    
    xx = isempty(trace.x) ? (1:n) : trace.x
    index = nothing
    if range !== nothing
        index = range[1] .<= xx .<= range[end]
        xx = xx[index]
    end
 
    if !isempty(trace.y)
        yy = index === nothing ? trace.y : trace.y[index]
        xnew, ynew = if threshold >= length(yy)
            xx, yy
        else
            index_new, ynew = lttb(yy, threshold)
            xnew = xx[index_new]
            xnew, ynew
        end
        trace.x = xnew
        trace.y = ynew
    elseif !isempty(trace.x)
        xnew, _ = lttb(xx, threshold)
        trace.x = xnew
    end
    return trace
end
 
function lttb(trace::AbstractTrace, range::Union{Nothing, AbstractVector}, threshold::Int)
    lttb!(deepcopy(trace), range, threshold)
end

function lttb!(trace::AbstractTrace, layout::PBLayout, threshold::Int)
    range = layout === nothing ? nothing : layout[:xaxis_range]
    range isa Dict && (range = nothing)
    lttb!(trace, range, threshold)
end

function lttb(trace::AbstractTrace, layout::PBLayout, threshold::Int)
    lttb!(deepcopy(trace), layout, threshold)
end

# definition of an app to be used as a mixin
@app PlotResampled begin
    @private _range = Float64[]
    @private _rawdata = GenericTrace[]

    @in _resolution = 1000
    @out _data = GenericTrace[]
    @in _layout::PBLayout = PBLayout()
end

@app begin
    @mixin plot::PlotResampled(_layout = PBLayout(xaxis_range = Float64[], title = "Server-side resampling"))
    # next line is for Stipple < v0.30.5
    # @mixin plot::PlotResampled!(_layout = PBLayout(xaxis_range = Float64[], title = "Server-side resampling"))

    @onchange isready begin
        xx1 = 0:0.01:1500
        xx2 = 0:0.015:1500
        plot_rawdata = [
            scatter(x = xx1, y = sin.(xx1), mode = "markers", line_color = "darkblue")
            scatter(x = xx2, y = 1 .+ cos.(xx2), mode = "markers", line_color = "orange")
        ]
    end

    @onchange plot_resolution begin
        plot_range = []
        notify(plot_layout)
    end

    @onchange plot_rawdata begin
        plot_range = []
        # autorange if new data is added
        plot_layout[:xaxis_autorange] = true
        # alternatively uncomment the next line to just replace the data with the current range
        # notify(layout)
    end
    
    @onchange plot_layout begin
        plot_range == plot_layout[:xaxis_range] && return
        autorange = get(plot_layout, :xaxis_autorange, true)
        x = [lttb(rd, autorange ? nothing : plot_layout, plot_resolution) for rd in plot_rawdata]
        # if data already identical don't replace in order to avoid loops
        x != plot_data && (plot_data = x)
        plot_layout[:xaxis_range] isa Vector && (plot_range = plot_layout[:xaxis_range])
    end
end

# set reaction time for layout faster than the default 300ms
@debounce plot_layout 10

ui() = [
    plot(:plot_data, layout = :plot_layout)
    btntoggle(class = "q-ml-md", :plot_resolution, options = [opts(label = "$v", value = v) for v in (100, 250, 500, 1000, 5000)], color = "blue-5", toggle__color = "blue-10")
]

@page("/", ui)

up(open_browser = true)
