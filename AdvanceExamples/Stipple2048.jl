cd(@__DIR__)
using Pkg
pkg"activate ."

using Game2048Core
using Stipple
using StippleUI

import Stipple: js_methods, js_created

const G = Game2048Core
const mydiv = Genie.Renderer.Html.div

colors = ["#4355db", "#34bbe6", "#49da9a", "#a3e048", "#f7d038", "#eb7532", "#e6261f"]

css() = style(media="screen","""
    .board {
        width: 65vh !important;
        height: 65vh !important;
        position: relative;
    }
    
    .field{
      position: absolute !important;
      width: 24% !important;
      height: 24% !important;
      border-radius: 2%;
      background-color: #ff4119ff;
      box-shadow: -0.3em 0.2em 1.5em 0.2em #ff4119ff;
      transition: all 0.5s ease-in-out;
    }

    .center{
        position: absolute !important;
        padding: 0 !important;
        margin: 0 !important;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
    }

    .size{
        width: 65vh !important
    }
""")

@reactive! mutable struct G2048 <: ReactiveModel
    score::R{Int} = 0
    bitboard::R{Bitboard} = G.initbboard()
    lastboard::R{Bitboard} = Bitboard(0), READONLY
    board::R{Matrix{Int8}} = zeros(Int8, 4, 4)
    styles :: R{Matrix{String}} = fill("", 4, 4)
    key::R{UInt8} = 0
end

function handlers(model)
    on(model.isready) do _
        model.board[!] = G.bitboard_to_array(model.bitboard[])
        push!(model)
        animate_board(model)
    end

    on(model.bitboard) do bitboard
        model.board[] = G.bitboard_to_array(bitboard)
        model.score[] = score(model.bitboard[])
        animate_board(model)
    end

    on(model.key) do key
        key == 0 && return
        keyhandler(model, key)
        model.key[] = 0
    end

    model
end

js_created(::G2048) = """
	window.addEventListener('keydown', this.keydown);
"""

js_methods(::G2048) = """
	keydown: function(e) {
		this.key = e.keyCode
	}
"""

function coords(i, j)
    top, left = 25 .* [i - 1, j - 1]
end

function fieldstyle(i, j, color)
    global colors
    top, left = coords(i, j)
    s = "top: $top%; left: $left%; color: $color; box-shadow: 0 0 1.5em -0.2em $(color * "aa");"
end

function animate_board(model)
    for i = 1:4, j = 1:4
        color = get(colors, 1 + model.board[i, j], colors[end])
        model.styles[i, j] = fieldstyle.(i, j, color)
    end
end

import Game2048Core.move!

function move!(model::G2048, dir::Dirs)
    newboard = move(model.bitboard[], dir)
    newboard == model.bitboard[] && return

    model.lastboard[] = model.bitboard[]
    model.bitboard[] = newboard
    model.bitboard[] = add_tile(model.bitboard[])
    animate_board(model)
end

function undo(model)
    model.bitboard[] = model.lastboard[]
end

function keyhandler(model, key)
    if 37 <= key <= 40
        move!(model, Dirs(key - 37))
    elseif lowercase(Char(key)) == 'r'
        undo(model)
    else
        println("Key down: $key")
    end
end 

function ui(model)
    css() * 
    page(model, class = "container", row(cell(class="st-module", [
        row(cell([
            cell(class = "text-h4", "Stipple 2048"),
            numberfield(class="size", "Score", :score, :readonly, :outlined, :filled, style="top: 25%; left:30%;")
        ])),
        
        row(mydiv(class="board", [
                        
            [card(class = "field", "", style = Symbol("styles[$i * 4 + $j - 5]"), 
                [cardsection(class="text-h3 center",
                    """{{ board[$i * 4 + $j - 5] > 0 ? 2 ** board[$i * 4 + $j - 5] : ""}}"""
                )]
            ) for i = 1:4, j = 1:4]...,

        ]))
    ])), title = "Stipple 2048")
end

route("/") do 
    model |> handlers |> ui |> html
end

Genie.config.server_host = "127.0.0.1"

model = init(G2048, debounce = 0)

Genie.up(open_browser = false)