cd(@__DIR__)
using Pkg
pkg"activate ."

using Game2048Core
using Stipple
using StippleUI

import Stipple: js_methods, js_created, js_destroyed

const G = Game2048Core
const mydiv = Genie.Renderer.Html.div

colors = ["#4355db", "#34bbe6", "#49da9a", "#a3e048", "#f7d038", "#eb7532", "#e6261f"]
speed = 0.15

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
      transition: all $(speed)s ease-in-out;
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

Stipple.@kwdef mutable struct Tile
    id::Int = 0
    i::Int = 0
    j::Int = 0
    show::Bool = true
    text::String = "-"
    style::String = ""
end

@vars G2048 begin
    score::R{Int} = 0
    bitboard::R{Bitboard} = G.initbboard()
    lastboard::R{Bitboard} = Bitboard(0), READONLY
    board::R{Matrix{Int8}} = zeros(Int8, 4, 4)
    tiles::R{Vector{Tile}} = [Tile(id = n, i = (n - 1) % 4 + 1, j = (n - 1) ÷ 4 + 1) for n in 1:(4*4)]
    key::R{UInt8} = 0
    replay::R{Bool} = false
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

    onbutton(model.replay, replay)

    model
end

js_created(::G2048) = """
    console.log("creating")
    window.addEventListener('keydown', this.keydown);
"""

js_destroyed(::G2048) = """
    alert('destroying')
	window.removeEventListener('keydown', this.keydown);
"""

js_methods(::G2048) = """
	keydown: function(e) {
		this.key = e.keyCode
	}
"""

function coords(i, j)
    top, left = i > 0 ? 25 .* [i - 1, j - 1] : (-0, -50)
end

function fieldstyle(i, j, color)
    top, left = coords(i, j)
    s = string(
        i == 0 ? "transition: 0s; " : "", 
        "top: $top%; left: $left%; color: $color; box-shadow: 0 0 1.5em -0.2em $(color * "aa");"
    )
end

function animate_board(model; pos_only = false)
    for t = model.tiles[]
        i, j = t.i, t.j
        color = get(colors, 1 + get(model.board[], (i, j), 0), colors[end])
        t.style = fieldstyle.(i, j, color)
        # if show, leave the text as is, otherwise update text
        if ! pos_only
            t.text = get(model.board[], (i, j), 0) == 0 ? "" : string(2^model.board[i, j])
        end
        # t.show = ! isempty(t.text)
    end
    notify(model.tiles)
end

import Game2048Core.move!

function newpositions(v::Vector)
    vnew = v[v .> 0]
    ii  = findall(v .> 0)
    ii_new = collect(1:length(vnew))
    ii_vis = fill(true, length(vnew))
    n = 2
    while n <= length(vnew)
        if vnew[n] == vnew[n - 1]
            ii_new[n:end] .-= 1
            ii_vis[n] = false
            n += 1
        end
        n += 1
    end
    zip(ii, ii_new, ii_vis)
end

function newpositions(m::Matrix, dir::Dirs)
    trans = dir == G.left || dir == G.right
    rev = dir == G.down || dir == G.right
    trans && (m = m')
    rev && (m = reverse(m, dims = 1))
    pos = fill((0, 0), size(m)...)
    vis = fill(false, size(m)...)

    for j in 1:size(m, 2)
        for (i, i_new, i_vis) in newpositions(m[:, j])
            pos[i, j] = (rev ? size(m, 1) + 1 - i_new : i_new, j)
            trans && (pos[i, j] = reverse(pos[i, j]))
            vis[i, j] = i_vis
        end
    end

    if rev
        reverse!(pos, dims = 1)
        reverse!(vis, dims = 1)
    end
    if trans
        pos = permutedims(pos)
        vis = permutedims(vis)
    end

    pos, vis
end

function move!(model::G2048, dir::Dirs)
    newboard = move(model.bitboard[], dir)
    newboard == model.bitboard[] && return
    model.lastboard[] = model.bitboard[]
    model.bitboard[] = newboard
    newpos, vis = newpositions(G.bitboard_to_array(model.lastboard[]), dir)

    # set new positions and set show to false for tiles to be merged
    for t in model.tiles[]
        t.i == 0 && continue
        t.show = vis[t.i, t.j]
        t.i, t.j = newpos[t.i, t.j]
    end

    # move to new positions and wait for animation to finish
    animate_board(model, pos_only = true)
    sleep(speed)
    
    n = findfirst(t -> t.i == 0, model.tiles[])

    # free the tiles that were merged
    for t in model.tiles[]
        t.i == 0 && continue
        t.show || (t.i = t.j = 0)
    end
    animate_board(model, pos_only = true)

    model.bitboard[] = add_tile(model.bitboard[])
    
    pos = findfirst(G.bitboard_to_array(newboard) .!= G.bitboard_to_array(model.bitboard[]))
    isnothing(n) && (n = findfirst(t -> t.i == 0, model.tiles[]))
    t = model.tiles[n]
    
    t.i, t.j = pos[1], pos[2]
    t.show = true
    
    animate_board(model)
end

function replay()
    g = G2048()
    model.lastboard[] = g.lastboard[]
    model.tiles[] .= g.tiles[]
    model.score[] = g.score[]
    for t in model.tiles[]
        G.bitboard_to_array(g.bitboard[])[t.i, t.j] == 0 && (t.i = t.j = 0; t.text = "")
    end
    model.bitboard[] = g.bitboard[]
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
    page(model, class = "container", "", @on("keyup.enter", ""), inner = row(cell(class="st-module", [
        row(cell([
            row(class = "size", [
                cell(class = "text-h4", "Stipple 2048"),
                btn("", icon = "replay", @click(:replay))
            ]),
            numberfield(class="size", "Score", :score, :readonly, :outlined, :filled, style="top: 25%; left:30%;")
        ])),
        
        row(mydiv(class="board", [
            [card(class = "field bg-orange", style = fieldstyle(i, j, "#55a")) for i in 1:4, j = 1:4]...,           
            [card(class = "field", "", style = Symbol("tiles[$n-1].style"), 
                [cardsection(class = "text-h3 center",
                    """{{ tiles[$n-1].text }}"""
                )],
                @iif("tiles[$n-1].i > -1")
            ) for n = 1:(4 * 4)]...,
        ]))
    ])), title = "Stipple 2048")
end

route("/") do 
    model |> ui |> html
    # uiconst
end

Genie.config.server_host = "127.0.0.1"

function restart()
    global model
    model = init(G2048, debounce = 0) |> handlers
    for t in model.tiles[]
        G.bitboard_to_array(model.bitboard[])[t.i, t.j] == 0 && (t.i = t.j = 0; t.text = "")
    end
    println("Stipple 2048 restarted!")
end

restart()

Genie.up(open_browser = true)
