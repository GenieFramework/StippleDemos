# Demo for editing a Dict by help of a tree with templates
# work in progress
# to be done:
# - move edit field into header
# - support arrays

using Stipple, StippleUI, JSON

Genie.Secrets.secret_token!()

testdict = JSON.parse("""
{
  "test":
  {
  "foo": false,
  "baz": "qux",
  "corge": 
    {
      "grault": 1
    }
  }
}
""")


dict(;kwargs...) = Dict{Symbol, Any}(kwargs...)
const mydiv = Genie.Renderer.Html.div

function dict_tree(startfile; parent = "d", name = "d")
    if startfile isa Dict
        k = keys(startfile)
        dict(
            label = name,
            key = parent,
            children = [dict_tree(startfile[i], parent = parent * "." * i, name = i) for i in k]
        )
    elseif startfile isa Array && !isempty(startfile)
        if startfile[1] isa Dict
            for j in startfile
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
            children = [dict(label = i, key = parent * "." * i) for i in startfile])
        end    
    else
        dict(label = name,
            key = parent,
            value = startfile,
            body = startfile isa Bool ? "bool" : startfile isa Number ? "number" : "text",
            children = []
        )
    end
end


@reactive! mutable struct TreeDemo <: ReactiveModel
    d::R{Dict{String, Any}} = deepcopy(testdict)
    tree::R{Vector{Dict{Symbol, Any}}} = [dict_tree(testdict)]

    tree_selected::R{String} = ""
    tree_ticked::R{Vector{String}} = String[]
    tree_expanded::R{Vector{String}} = String[]
end

Genie.Router.delete!(:TreeDemo)
Stipple.js_methods(::TreeDemo) = """
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

function ui(model)
    page(
        model,
        title = "Dict Tree",
        row(cell( class = "st-module", [
            row([tree(var"node-key" = "key", nodes = :tree,
                var"selected.sync" = :tree_selected,
                var"expanded.sync" = :tree_expanded,
                [
                    template("", var"v-slot:body-text" = "prop", [
                        textfield("", dense = true, label = R"prop.node.label", value = R"getindex(prop.node.key)", var"@input" = "newval => setindex(prop.node.key, newval)")
                    ]),
                    template("", var"v-slot:body-number" = "prop", [
                        textfield("", dense = true, label = R"prop.node.label", value = R"getindex(prop.node.key)", var"@input" = "newval => setindex(prop.node.key, 1 * newval)")
                    ]),
                    template("", var"v-slot:body-bool" = "prop", [
                        checkbox("", dense = true, label = R"prop.node.label", value = R"getindex(prop.node.key)", var"@input" = "newval => setindex(prop.node.key, newval)")
                    ])
                ]
            )
        ])

            # mydiv(h4("Expanded: ") * "{{ tree_expanded }}")
            # mydiv(h4("Selected: ") * "{{ tree_selected }}")
            # mydiv(h4("Ticked: ")   * "{{ tree_ticked }}")
        ])),
    )
end

function handlers(model)
    on(model.isready) do isready
        isready && push!(model)
    end

    model
end

route("/") do
    # model defined gloablly for debugging and testing only
    global model
    model = init(TreeDemo) |> handlers
    model |> ui |> html
end

up()