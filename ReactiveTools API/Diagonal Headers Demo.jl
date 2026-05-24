# Diagonal Headers Demo

using Stipple, Stipple.ReactiveTools, StippleUI

using DataFrames

df = DataFrame(team1 = ["Team A", "Team B"], team2 = ["Team C", "Team D"], score1 = [85, 90], score2 = [80, 95])

@app MyApp begin
    @out table = DataTable(df)
    @in relabel = false
    @in angle = 45
    @onbutton relabel on_relabel()
end

max_length = 15

@handler MyApp function on_relabel()
    relabel || return
    relabel!(table,
        "team1" => "Team 1 " * join(rand(1:9, max_length)),
        "score1" => "Score 1 " * join(rand(1:9, max_length)),
        "team2" => "Team 2 " * join(rand(1:9, max_length)),
        "score2" => "Score 2 " * join(rand(1:9, max_length)),
    )

    angle = rand(0:5:90)
    notify(table)
end

@methods MyApp js_diagonal_headers

height_offset = 0
x_offset = 0
y_offset = 0

ui() = htmldiv([
    h3(style = "margin-bottom: 1em", "Tables Demo")

    row(class = "q-mb-lg", [
        btn("Relabel", @click(:relabel))
    ])
    
    table(:table, dense = true,
        diagonal_headers(:table, 25; height_offset, x_offset, y_offset)
    ) |> cardsection |> card
    
    htmldiv(class = "q-ma-md")
    
    table(:table, dense = true,
        diagonal_headers(:table, "this.angle"; height_offset, x_offset, y_offset)
    ) |> cardsection |> card

    htmldiv(class = "q-ma-md")

    table(:table, dense = true,
        diagonal_headers(:table, 90; height_offset, x_offset, y_offset)
    ) |> cardsection |> card
])

p1 = @page("/test", ui, model = MyApp, post = x -> (global model = x; nothing))

up()


