using Stipple, Stipple.ReactiveTools
using StippleUI
using StippleLatex

# define a small formula generator
function nestlist(f, a; init = nothing)
    T = eltype(a)
    list = T[]
    el = init
    for (i, x) in enumerate(a)
        el = i == 1 && init === nothing ? x : f(el, x)
        push!(list, el)
    end
    list
end

formula = nestlist(*, ["", raw"\sin", "^2", " x", " +", raw" \sqrt{", "a", "^2", " +", " b", "^2"])
formula[contains.(formula, "sqrt")] .*= "}"

# setting up the app
@app begin
    @in x = 0
    @in formula_1 = raw"\int_{a}^{b} f(x) \, dx = F(x)\Biggr|^b_a"
    @in formula_2 = raw""
    @private p = @task 1 + 1

    @onchange isready begin
        if !istaskstarted(p) || istaskdone(p) 
            p = @task begin
                println("Task started")
                while x <= 100
                    sleep(1)
                    x += 1
                    pos = x < 6 ? 1 : (x - 5) % (length(formula) + 5) + 1
                    formula_2 = formula[min(pos, length(formula))]
                end
            end
            schedule(p)
        end
    end
end

function ui()
    [
        row(cell(class = "st-module", [
            cell(h1(latex("\\LaTeX") * "-Demo"))
            cell(h2(latex"a^2 + b^2 = c^2"))
        ]))

        row(cell(class = "st-module", [
            textfield("Enter your LaTeX-Forumla", :formula_1,)
            cell(class = "q-pa-md", latex":formula_1"display)
            row([
                cell(class = "q-pa-md bg-red-1", raw"""cell(latex"\cos^2x"display)""")
                cell(class = "q-pa-md bg-green-1", latex"\cos^2x"display)
            ])
            row([
                cell(class = "q-pa-md bg-red-1", raw"""cell(latex"This is auto mode with a formula \(\cos^2x\)"auto)""")
                cell(class = "q-pa-md bg-green-1", latex"This is auto mode with a formula \(\cos^2x\)"auto)
            ])
            row([
                cell(class = "q-pa-md bg-red-1", raw"""latex(class = "q-pa-md", raw"\tan^2x", display = true)""")
                cell(class = "bg-green-1 q-pa-md", latex(class = "q-pa-md", raw"\tan^2x", display = true))
            ])
            bignumber("Wait for 5", :x, color = R"x >= 5 ? 'negative' : 'positive'", icon = "calculate")
            
            row([
                cell(class = "q-pa-md bg-red-1", raw"""cell(class = "q-pa-md", @latex(raw"\tanh^2 y", display = R"x >= 5"))""")
                cell(class = "q-pa-md bg-green-1", @latex(raw"\tanh^2 y", display = R"x >= 5"))
            ])


            row([
                cell(class = "q-pa-md bg-red-1", raw"""cell(class = "q-pa-md", @latex(raw"\tanh^2 y", display = R"x >= 5"))""")
                cell(class = "q-pa-md bg-green-1", @latex(raw"This is auto mode with an inline formula \(\cos^2x\) and a display formula $$\sin^2x$$", auto = true))
            ])
        ]))

        row(cell(class = "st-module", [
            textfield(class = "q-pa-lg", "LaTeX", :formula_2)
            cell(class = "q-pa-md", "Result:")
            cell(class = "q-pa-md", latex":formula_2"display)
        ]))
    ]
end

route("/") do
    page(@init(), ui()) |> html
end
    
up()