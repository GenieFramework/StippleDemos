using Pkg
Pkg.activate(@__DIR__)

using Stipple, Stipple.ReactiveTools
using StippleUI
using StippleMathjs


# you need to define x0 and y0 outside the loop in order to
# guarantee that z is of the correct type.
# Alternatively, you could declare z explicitly `z::ComplexF64`


x0 = 1.0
y0 = 2.0

@app begin
    @in x = x0
    @in y = y0
    @in z::ComplexF64 = x0 + y0 * im

    @onchange x, y begin
        z[!] = x + y*im
        @push z
    end

    @onchange z begin
        @show z
        x[!] = z.re
        y[!] = z.im
        @push x
        @push y
    end
end

@deps StippleMathjs

function ui()
    [
        card(class = "q-pa-md", [
            numberfield(class = "q-ma-md", "x", :x)
            numberfield(class = "q-ma-md", "y", :y)
        ])

        card(class = "q-pa-md q-my-md", [
            row([cell(col = 2, "z"),        cell("{{ z }}")])
            row([cell(col = 2, "z.mul(z)"), cell("{{ z.mul(z) }}")])
            row([cell(col = 2, "z.abs()"),  cell("{{ z.abs() }}")])

            btn(class = "q-my-md", "square(z)", color = "primary", @click("z = z.mul(z)"))
        ])
    ]
end

@page("/", ui, debounce = 10)
up()