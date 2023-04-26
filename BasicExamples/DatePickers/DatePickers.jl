using Stipple, StippleUI
import Stipple.Html: div

# R{Date}, R{Vector{DateRange}} etc are type Observable and you can listen for changes 
# https://juliagizmos.github.io/Observables.jl/stable/
@vars DatePickers begin
  date::R{Date} = today() + Day(30)
  dates::R{Vector{Date}} = Date[today()+Day(10), today()+Day(20), today()+Day(30)]
  daterange::R{DateRange} = DateRange(today(), (today() + Day(3)))
  dateranges::R{Vector{DateRange}} = [
    DateRange(today(), (today() + Day(3))),
    DateRange(today() + Day(7), (today() + Day(10))),
    DateRange(today() + Day(14), (today() + Day(17))),
  ]
  proxydate::R{Date} = today()
  inputdate::R{Date} = today()
end

function ui(model)
  [
    page(
      model,
      class = "container",
      title = "DatePickers Demo",
      partial = true,
      core_theme = true,
      [
        row(cell([h1("Date pickers")]))
        row(
          [
            cell([
              datepicker(:date),        # refers to line 7 date::R{Date}
            ])
            cell([
              datepicker(:dates, multiple = true), # :dates is mapped to line 8 Stipple's ReactiveModel
            ])
            cell([
              datepicker(:daterange, range = true), # :daterange -> daterange::R{DateRange} line 9
            ])
            cell([datepicker(:dateranges, range = true, multiple = true)])
          ],
        )
        row(
          [
            cell([
              btn(
                icon = "event",
                round = true,
                color = "primary",
                [
                  popup_proxy([
                    datepicker(
                      :proxydate,
                      content = [
                        div(
                          class = "row items-center justify-end q-gutter-sm",
                          [
                            btn(
                              label = "Cancel",
                              color = "primary",
                              flat = true,
                              v__close__popup = true,
                            )
                            btn(
                              label = "OK",
                              color = "primary",
                              flat = true,
                              v__close__popup = true,
                            )
                          ],
                        ),
                      ],
                    ),
                  ]),
                ],
              ),
            ])
            cell([
              div(
                class = "q-pa-md",
                style = "max-width: 300px",
                [
                  textfield(
                    "",
                    :inputdate,
                    filled = true,
                    content = [
                      template(
                        v__slot!!append = true,
                        [
                          icon(
                            name = "event",
                            class = "cursor-pointer",
                            [
                              popup_proxy(
                                ref = "qDateProxy",
                                transition__show = "scale",
                                transition__hide = "scale",
                                [
                                  datepicker(
                                    :inputdate,
                                    content = [
                                      div(
                                        class = "row items-center justify-end",
                                        [
                                          btn(
                                            v__close__popup = true,
                                            label = "Close",
                                            color = "primary",
                                            flat = true,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ])
          ],
        )
      ],
    ),
  ]
end

route("/") do
  model = DatePickers |> init
  html(ui(model), context = @__MODULE__)
end

up()
