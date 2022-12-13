# contributed by zygmuntszpak: https://github.com/GenieFramework/StipplePlotly.jl/pull/53
using Stipple, Stipple.ReactiveTools, StipplePlotly, DataFrames

function create_example_dataframe()
    xs = [1.0, 2.0, 3.0, 4.0, 5.0, 1.5, 2.5, 3.5, 4.5, 5.5]    
    ys = [1.0, 6.0, 3.0, 6.0, 1.0, 4.0, 1.0, 7.0, 1.0, 4.0]
    groups = ["Team A", "Team A", "Team A", "Team A", "Team A", "Team B", "Team B", "Team B", "Team B", "Team B"]
    text = ["A-1", "A-2", "A-3", "A-4", "A-5","B-a", "B-b", "B-c", "B-d", "B-e"]
    return DataFrame(X = xs, Y = ys, Group = groups, Text = text)
end

df = create_example_dataframe()
pd = plotdata(df, :X, :Y; groupfeature = :Group, text = df.Text)

@handlers begin
    @out data = pd
    @out layout = PlotLayout()
    @out config = PlotConfig()
end

function ui()
    [
        plot(:data, layout = :layout, config = :config)
    ] |> join
end

@page("/", ui)

up()
