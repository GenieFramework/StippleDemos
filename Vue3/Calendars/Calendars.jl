module Calendars

using Stipple, Stipple.ReactiveTools
using StippleUI

using Dates


UI = Ref(ParsedHTMLString[])
ui() = UI[]


calendar_css() = [
    stylesheet("https://cdn.jsdelivr.net/npm/@quasar/quasar-ui-qcalendar@next/dist/QCalendarMonth.min.css", type = "text/css")
]

calendar_deps() = [
    script(src="https://cdn.jsdelivr.net/npm/@quasar/quasar-ui-qcalendar@next/dist/QCalendarMonth.umd.min.js")
    script(src="https://cdn.jsdelivr.net/npm/@quasar/quasar-ui-qcalendar@next/dist/Timestamp.umd.min.js")
]


UI[] = [
    row(class = "text-center text-h5", [cell("{{ monthName }}"), cell("{{ selectedDate.substring(0,4)}}")]),
    row(class = "q-pa-md q-gutter-sm", [
        cell()
        btn(col = :auto, icon = "arrow_left", var"v-on:click" = "onPrev", dense = true)
        btn(col = :auto, "Today", var"v-on:click" = "onToday", )
        btn(col = :auto, icon = "arrow_right", var"v-on:click" = "onNext", dense = true)
        cell()
    ]),
    cell(class = "q-pa-md full-width", style = "height: 400px;", 
    quasar(:calendar__month, ref = "calendar", fieldname = "selectedDate", "",
        var"day-min-height" = R"70",
        :focusable, :hoverable, :bordered,
        @on("change", "onChange"), @on("moved", "onMoved"), @on("click-date", "onClickDate"),
        @on("click-day", "onClickDay"), @on("click-head-day", "onClickHeadDay")
    ))
]

@app Calendar begin
    @in selectedDate::Any = today()
    @in startDate = today()
    @in endDate = today()
end

@computed Calendar [
    :monthName => """function () {
        return Timestamp.getMonthFormatter()(Timestamp.parsed(this.selectedDate).month - 1)
    }"""
]

@methods Calendar [
    :onMoved => """function(data) {
        console.log("onMoved", data);
    }"""

    :onChange => """function(data) {
        this.startDate = data.start;
        this.endDate = data.end;
    }"""

    :onClickDate => """function(data) {
        console.log("onClickDate", data);
    }"""

    :onClickDay => """function(data) {
        console.log("onClickDay", data);
    }"""

    :onClickHeadDay => """function(data) {
        console.log("onClickHeadDay", data);
    }"""

    :onToday => """function() {
        this.selectedDate = QCalendarMonth.today();
    }"""

    :onPrev => """function() {
        this.\$refs.calendar.prev();
    }"""

    :onNext => """function() {
        this.\$refs.calendar.next();
    }"""
]

function __init__()
    Stipple.ReactiveTools.HANDLERS_FUNCTIONS[Calendar] = handlers
    
    add_css(calendar_css)
    @deps Calendar calendar_deps
    Stipple.register_components(Calendar, "QCalendarMonth" => "QCalendarMonth.QCalendarMonth")

    route("/") do
        global model
        model = @init Calendar
        page(model, ui) |> html
    end
end

using PrecompileTools
@compile_workload begin
    Stipple.PRECOMPILE[] = true
    ui()
    __init__()
    model = @init Calendar
    page(model, ui) |> html
    Stipple.PRECOMPILE[] = false
end

end