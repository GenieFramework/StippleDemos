using Stipple, StipplePlotly, StippleUI
using DataFrames

include("lib/solver.jl") # get_data from solver.jl

@reactive mutable struct HeatPages <: ReactiveModel
    tableData::R{DataTable} = DataTable(DataFrame(1000 * ones(10, 10), ["$i" for i in 1:10]))
    credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=10)

    value::R{Int} = 0
    click::R{Int} = 0

    func_features::R{Vector{Symbol}} = [:_sin, :_tanh, :_sign]
    func::R{Symbol} = :_sign

    T0::R{Float64} = 1000.0
    Tout::R{Float64} = 0.0
    timefield::R{Float64} = 100
    para::R{Float64} = 1.0

    plot_data::R{Vector{PlotData}} = []
    layout::R{PlotLayout} = PlotLayout(plot_bgcolor="#fff")

end


contourPlot(z, n=10, L=0.2) = PlotData(
    x=collect(range(0, L, length=n)),
    y=collect(range(0, L, length=n)),
    z=[z[:, i] for i in 1:10],
    plot=StipplePlotly.Charts.PLOT_TYPE_CONTOUR,
    contours=Dict("start" => 0, "end" => 1000),
    name="test",
)


function compute_data(ic_model::HeatPages)

    T0 = ic_model.T0[]
    Tout = ic_model.Tout[]
    timefield = ic_model.timefield[]
    para = ic_model.para[]
    func = ic_model.func[]
    res = get_data(T0, Tout, timefield, para, func)
    len = length(res[1, 1, :])
    for i in 1:len
        ic_model.plot_data[] = [contourPlot(res[:, :, i])]
        ic_model.tableData[] = DataTable(
            DataFrame(round.(res[:, :, i], digits=2), ["$i" for i in 1:10]))
        sleep(1 / 30)
    end
    nothing
end


function ui(model::HeatPages)

    onany(model.value) do (_...)
        model.click[] += 1
        compute_data(model)
    end

    page(model, class="container", title="Ai4Lab",
        head_content=Genie.Assets.favicon_support(),
        prepend=style(
            """
            tr:nth-child(even) {
              background: #F8F8F8 !important;
            }

            .modebar {
              display: none!important;
            }

            .st-module {
              marign: 20px;
              background-color: #FFF;
              border-radius: 5px;
              box-shadow: 0px 4px 10px rgba(0, 0, 0, 0.04);
            }

            .stipple-core .st-module > h5,
            .stipple-core .st-module > h6 {
              border-bottom: 0px !important;
            }
            """
        ),
        [
            heading("二维平板换热虚拟仿真实验室(Two Dimensional Plate Heat Transfer Virtual Simulation Laboratory)")
            row([
                cell(
                    class="st-module",
                    [
                        h6("Initial Temperature: T0(℃)")
                        slider(1000:50:2000,
                            @data(:T0);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("Environmental Temperature: Tout(℃)")
                        slider(0:50:500,
                            @data(:Tout);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("Coefficient of t: Para")
                        slider(0:0.1:2,
                            @data(:para);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("Time Domain(s)")
                        slider(40:20:400,
                            @data(:timefield);
                            label=true)
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h6("Change of Environmental Temperature")
                        Stipple.select(:func; options=:func_features)
                    ]
                )])
            row([
                btn("Simulation!", color="primary", textcolor="black", @click("value += 1"), [
                    tooltip(contentclass="bg-indigo", contentstyle="font-size: 16px",
                        style="offset: 10px 10px", "Click the button to start simulation")])
                cell(
                    class="st-module",
                    [
                        h6(["Simulation Times: ",
                            span(model.click, @text(:click))])
                    ])
            ])
            row([
                cell(
                    size=6,
                    class="st-module",
                    [
                        h5("Result Plot")
                        plot(:plot_data, layout=:layout, config="{ displayLogo:false }")
                    ]
                )
                cell(
                    class="st-module",
                    [
                        h5("Result Data")
                        table(:tableData; pagination=:credit_data_pagination, label=false, flat=true)
                    ]
                )
            ])
        ]
    )
end

htmlfile = HeatPages |> init |> ui |> html

route("/") do
    htmlfile
end

up()