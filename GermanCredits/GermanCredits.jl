using Stipple
using StippleUI
using StipplePlotly

using CSV, DataFrames, Dates

# configuration
const data_opts = DataTableOptions(columns = [Column("Good_Rating"), Column("Amount", align = :right),
                                              Column("Age", align = :right), Column("Duration", align = :right)])

const plot_colors = ["#72C8A9", "#BD5631"]

# PlotOption is a Julia object defined in StippleCharts
# const bubble_plot_opts = PlotOptions(data_labels_enabled=false, fill_opacity=0.8, xaxis_tick_amount=10, chart_animations_enabled=false,
#                                       xaxis_max=80, xaxis_min=17, yaxis_max=20_000, chart_type=:bubble,
#                                       colors=plot_colors, plot_options_bubble_min_bubble_radius=4, chart_font_family="Lato, Helvetica, Arial, sans-serif")

# const bar_plot_opts = PlotOptions(xaxis_tick_amount=10, xaxis_max=350, chart_type=:bar, plot_options_bar_data_labels_position=:top,
#                                   plot_options_bar_horizontal=true, chart_height=200, colors=plot_colors, chart_animations_enabled=false,
#                                   xaxis_categories = ["20-30", "30-40", "40-50", "50-60", "60-70", "70-80"], chart_toolbar_show=false,
#                                   chart_font_family="Lato, Helvetica, Arial, sans-serif", stroke_show = false)


# reading data from CSV file and contrucing data frame 
cd(@__DIR__)
data = CSV.File("data/german_credit.csv") |> DataFrame

# Defining a Stipple ReactiveModel of type observable 
@reactive mutable struct Dashboard1 <: ReactiveModel
  credit_data::R{DataTable} = DataTable()
  credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=100)
  credit_data_loading::R{Bool} = false

  range_data::R{RangeData{Int}} = RangeData(15:80)

  big_numbers_count_good_credits::R{Int} = 0
  big_numbers_count_bad_credits::R{Int} = 0
  big_numbers_amount_good_credits::R{Int} = 0
  big_numbers_amount_bad_credits::R{Int} = 0

  # bar_plot_options::PlotOptions = bar_plot_opts
  # bar_plot_data::R{Vector{PlotSeries}} = []
  age_slots::R{Vector{String}} = ["20-30", "30-40", "40-50", "50-60", "60-70", "70-80"]
  bar_plot_data::R{Vector{PlotData}} = PlotData[]
  bar_layout::R{PlotLayout} = PlotLayout(barmode= "group")

  # bubble_plot_options::PlotOptions = bubble_plot_opts
  # bubble_plot_data::R{Vector{PlotSeries}} = []
  bubble_plot_data::R{Vector{PlotData}} = PlotData[]

  title::PlotLayoutTitle = PlotLayoutTitle(text= "Marker Size")
  bubble_layout::R{PlotLayout} = PlotLayout(title=title, showlegend = false, height = 720, width = 1080)
end


# functions
function creditdata(data::DataFrame, model::M) where {M<:Stipple.ReactiveModel}
  model.credit_data[] = DataTable(data, data_opts)  # credit_data propertly of type StippleUI.DataTable is assigned to data from CSV
  # data_opts data_opts = DataTableOptions(columns = [Column("Good_Rating"), Column("Amount", align = :right), Column("Age", align = :right), Column("Duration", align = :right)])
end

function bignumbers(data::DataFrame, model::M) where {M<:ReactiveModel}
  model.big_numbers_count_good_credits[] = data[data.Good_Rating .== true, [:Good_Rating]] |> nrow   # Good_Rating from CSV 
  model.big_numbers_count_bad_credits[] = data[data.Good_Rating .== false, [:Good_Rating]] |> nrow
  model.big_numbers_amount_good_credits[] = data[data.Good_Rating .== true, [:Amount]] |> Array |> sum  # Amount field from CSV 
  model.big_numbers_amount_bad_credits[] = data[data.Good_Rating .== false, [:Amount]] |> Array |> sum
end

function barstats(data::DataFrame, model::M) where {M<:Stipple.ReactiveModel}
  age_stats = Dict{Symbol,Vector{Int}}(:good_credit => Int[], :bad_credit => Int[])

  for x in 20:10:70
    push!(age_stats[:good_credit],
          data[(data.Age .∈ [x:x+10]) .& (data.Good_Rating .== true), [:Good_Rating]] |> nrow)
    push!(age_stats[:bad_credit],
          data[(data.Age .∈ [x:x+10]) .& (data.Good_Rating .== false), [:Good_Rating]] |> nrow)
  end

  @info age_stats
  @info typeof(age_stats[:good_credit])
  @info model.age_slots[]

  model.bar_plot_data[] =
  [PlotData(x = model.age_slots[],
          y = age_stats[:good_credit],
          name = "Good credit",
          plot = StipplePlotly.Charts.PLOT_TYPE_BAR),

  PlotData(x = model.age_slots[],
          y = age_stats[:bad_credit],
          name = "Bad credit",
          plot = StipplePlotly.Charts.PLOT_TYPE_BAR)
  ]
end

function bubblestats(data::DataFrame, model::M) where {M<:ReactiveModel}
  selected_columns = [:Age, :Amount, :Duration]
  credit_stats = Dict{Symbol,DataFrame}()

  credit_stats[:good_credit] = data[data.Good_Rating .== true, selected_columns]
  credit_stats[:bad_credit] = data[data.Good_Rating .== false, selected_columns]

  model.bubble_plot_data[] = 
  [PlotData(x = credit_stats[:good_credit].Age,
           y = credit_stats[:good_credit].Amount,
           mode = "markers",
           marker = PlotDataMarker(symbol="circle")),

  PlotData(x = credit_stats[:bad_credit].Age,
          y = credit_stats[:bad_credit].Amount,
          mode = "markers",
          marker = PlotDataMarker(symbol="cross"))]
end

function setmodel(data::DataFrame, model::M)::M where {M<:ReactiveModel}
  creditdata(data, model)
  bignumbers(data, model)

  barstats(data, model)
  bubblestats(data, model)

  model
end


### setting up vuejs and stipple connection with ReactiveModel
# Stipple.register_components(Dashboard1, StippleCharts.COMPONENTS)

# Instantiating Reactive Model isntantace 
gc_model = setmodel(data, Dashboard1()) |> init

function filterdata(model::Dashboard1)
  model.credit_data_loading[] = true
  model = setmodel(data[(model.range_data[].range.start .<= data[!, :Age] .<= model.range_data[].range.stop), :], model)
  model.credit_data_loading[] = false

  nothing
end

# handlers
on(gc_model.range_data) do _
  filterdata(gc_model)
end

function ui(model)
  (
  page(model, title="German Credits",
            head_content = Genie.Assets.favicon_support(), partial = false,
  [
    heading("German Credits by Age")

    row([
      cell(class="st-module", [
        row([
          cell(class="st-br", [
            bignumber("Bad credits",
                      :big_numbers_count_bad_credits,
                      icon="format_list_numbered",
                      color="negative")
          ])

          cell(class="st-br", [
            bignumber("Good credits",
                      :big_numbers_count_good_credits,
                      icon="format_list_numbered",
                      color="positive")
          ])

          cell(class="st-br", [
            bignumber("Bad credits total amount",
                      R"big_numbers_amount_bad_credits | numberformat",
                      icon="euro_symbol",
                      color="negative")
          ])

          cell(class="st-br", [
            bignumber("Good credits total amount",
                      R"big_numbers_amount_good_credits | numberformat",
                      icon="euro_symbol",
                      color="positive")
          ])
        ])
      ])
    ])

    row([
      cell([
        h4("Age interval filter")

        range(18:1:90,
              :range_data;
              label=true,
              labelalways=true,
              labelvalueleft=Symbol("'Min age: ' + range_data.min"),
              labelvalueright=Symbol("'Max age: ' + range_data.max"))
      ])
    ])

    row([
      cell(class="st-module", [
        h4("Credits data")

        table(:credit_data;
              style="height: 400px;",
              pagination=:credit_data_pagination,
              loading=:credit_data_loading
        )
      ])
      cell(class="st-module", [
        h4("Credits by age")
        plot(:bar_plot_data; layout=:bar_layout, config = "{ displayLogo:false }")
      ])
    ])

    row([
      cell(class="st-module", [
        h4("Credits by age, amount and duration")
        plot(:bubble_plot_data, layout=:bubble_layout, config = "{ displayLogo:false }")
      ])
    ])

    footer(class="st-footer q-pa-md", [
      cell([
        span("Stipple &copy; $(year(now()))")
      ])
    ])
  ])
  )
end

# serving on localhost
route("/") do
  ui(gc_model) |> html
end

up()