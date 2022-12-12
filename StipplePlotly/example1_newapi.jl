using Stipple, StipplePlotly


pd(name) = PlotData(
  x = ["Jan2019", "Feb2019", "Mar2019", "Apr2019", "May2019",
        "Jun2019", "Jul2019", "Aug2019", "Sep2019", "Oct2019",
        "Nov2019", "Dec2019"],
  y = Int[rand(1:100_000) for x in 1:12],
  plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER,
  name = name
)

@handlers begin
    @out data = [pd("Random 1"),pd("Random 2")]
    @out layout = PlotLayout(plot_bgcolor = "#333", title = PlotLayoutTitle(text="Random numbers", font=Font(24)))
    @out config = PlotConfig()
end

function ui()
    [
        plot(:data, layout = :layout, config = :config)
    ] |> join
end

@page("/", ui)

up()
