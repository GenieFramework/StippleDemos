using Stipple
using StippleUI
using StipplePlotly

using CSV, DataFrames, Dates

# configuration
const data_opts = DataTableOptions(columns = [Column("Good_Rating"), Column("Amount", align = :right),
                                              Column("Age", align = :right), Column("Duration", align = :right)])

const plot_colors = ["#72C8A9", "#BD5631"]

# reading data from CSV file and contrucing data frame 
cd(@__DIR__)
data = CSV.File("data/german_credit.csv") |> DataFrame

# Defining a Stipple ReactiveModel of type observable 
@reactive mutable struct Dashboard1 <: ReactiveModel
  credit_data::R{DataTable} = DataTable()
  credit_data_pagination::DataTablePagination = DataTablePagination(rows_per_page=100)
  credit_data_loading::R{Bool} = false

  range_data::R{RangeData{Int}} = RangeData(18:80)

  big_numbers_count_good_credits::R{Int} = 0
  big_numbers_count_bad_credits::R{Int} = 0
  big_numbers_amount_good_credits::R{Int} = 0
  big_numbers_amount_bad_credits::R{Int} = 0

  age_slots::R{Vector{String}} = ["20-30", "30-40", "40-50", "50-60", "60-70", "70-80"]
  bar_plot_data::R{Vector{PlotData}} = PlotData[]
  bar_layout::R{PlotLayout} = PlotLayout(barmode= "group")

  bubble_plot_data::R{Vector{PlotData}} = PlotData[]

  bubble_layout::R{PlotLayout} = PlotLayout(showlegend = false)
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

  model.bar_plot_data[] =
  [PlotData(x = model.age_slots[],
          y = age_stats[:good_credit],
          name = "Good credit",
          plot = StipplePlotly.Charts.PLOT_TYPE_BAR,
          marker = PlotDataMarker(color = plot_colors[1])),

  PlotData(x = model.age_slots[],
          y = age_stats[:bad_credit],
          name = "Bad credit",
          plot = StipplePlotly.Charts.PLOT_TYPE_BAR,
          marker = PlotDataMarker(color = plot_colors[2]))]
end

function bubblestats(data::DataFrame, model::M) where {M<:ReactiveModel}
  selected_columns = [:Age, :Amount, :Duration]
  credit_stats = Dict{Symbol,DataFrame}()

  credit_stats[:good_credit] = data[data.Good_Rating .== true, selected_columns]
  credit_stats[:bad_credit] = data[data.Good_Rating .== false, selected_columns]

  model.bubble_plot_data[] = 
  [PlotData(x = credit_stats[:good_credit].Age,
           y = credit_stats[:good_credit].Amount,
           name = "Good Credit",
           mode = "markers",
           marker = PlotDataMarker(size=18, opacity= 0.4, color = plot_colors[1], symbol="circle")),

  PlotData(x = credit_stats[:bad_credit].Age,
          y = credit_stats[:bad_credit].Amount,
          name = "Bad Credit",
          mode = "markers",
          marker = PlotDataMarker(size=18, color = plot_colors[2], symbol="cross"))]
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
  page(model, 
  title="German Credits", 
  head_content = Genie.Assets.favicon_support(), 
  partial = false,
  prepend = style(
    """
    .modebar {
      display: none!important;
    }
    """
  ),
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
