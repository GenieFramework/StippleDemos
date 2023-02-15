# Demo for editing a Dict by help of a tree with templates
# work in progress
# to be done:
# - move edit field into header
# - support arrays

using Stipple, StippleUI
using Stipple.ReactiveTools

dict(;kwargs...) = Dict(kwargs...)
stringdict(; kwargs...) = Dict(zip(String.(getindex.(collect(kwargs), 1)), getindex.(collect(kwargs), 2)))

const mydiv = Genie.Renderer.Html.div

function dict_tree(startdict; parent = "d", name = "d")
    if startdict isa Dict
        k = keys(startdict)
        dict(
            label = name,
            key = parent,
            children = [dict_tree(startdict[i], parent = parent * "." * i, name = i) for i in k]
        )
    elseif startdict isa Array && !isempty(startdict)
        if startdict[1] isa Dict
            for j in startdict
                k = keys(j)
                dict(
                    label = name,
                    key = parent,
                    children = [dict_tree(j[i], parent = parent * "." * i, name=i) for i in k]
                )
            end
        else
            dict(
            label = name,
            key = parent,
            children = [dict(label = i, key = parent * "." * i) for i in startdict])
        end    
    else
        dict(label = name,
            key = parent,
            value = startdict,
            body = startdict isa Bool ? "bool" : startdict isa Number ? "number" : "text",
            children = []
        )
    end
end

testdict = stringdict(test = stringdict(
    corge = stringdict(grault = 1),
    baz = "qux",
    foo = false)
)

@appname TreeDemo

@app begin
    @in d = deepcopy(testdict)
    @in tree = [dict_tree(testdict)]

    @in tree_selected = ""
    @in tree_ticked = String[]
    @in tree_expanded = String[]

    @onchange isready begin
        isready && @push
    end
end

@methods """
getindex: function(key) {
    let o = this
    kk = key.split('.')
    for(let i = 0; i < kk.length; i++){ 
        o = o[kk[i]];
    }
    return o
},

setindex: function(key, val) {
    let o = this
    kk = key.split('.')
    for(let i = 0; i < kk.length - 1; i++){ 
        o = o[kk[i]];
    }
    o[kk[kk.length-1]] = val
    return val
}
"""

function ui()
    row(cell( class = "st-module", [
        row([tree(var"node-key" = "key", nodes = :tree,
            var"selected.sync" = :tree_selected,
            var"expanded.sync" = :tree_expanded,
            [
                template("", var"v-slot:body-text" = "prop", [
                    textfield("", dense = true, label = R"prop.node.label",
                        value = R"getindex(prop.node.key)",
                        @on(:input, "newval => setindex(prop.node.key, newval)")
                    )
                ]),
                template("", var"v-slot:body-number" = "prop", [
                    textfield("", dense = true, label = R"prop.node.label",
                        value = R"getindex(prop.node.key)",
                        @on(:input, "newval => setindex(prop.node.key, 1 * newval)")
                    )
                ]),
                template("", var"v-slot:body-bool" = "prop", [
                    checkbox("", dense = true, label = R"prop.node.label",
                        value = R"getindex(prop.node.key)",
                        @on(:input, "newval => setindex(prop.node.key, newval)")
                    )
                ])
            ]
        )])

        mydiv(h4("Expanded: ") * "{{ tree_expanded }}")
        mydiv(h4("Selected: ") * "{{ tree_selected }}")
        mydiv(h4("Ticked: ")   * "{{ tree_ticked }}")
    ]))
end

route("/") do
    # model defined gloablly for debugging and testing only
    global model
    model = @init
    page(model, ui()) |> html
end

up()