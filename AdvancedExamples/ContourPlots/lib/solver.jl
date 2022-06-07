using DifferentialEquations: ODEProblem, solve, Tsit5

_sin(t) = 1 + sin(t)
_tanh(t) = tanh(t)
_sign(t) = sign(t)

function get_data(T0::Float64, Tout::Float64, time::Float64, para::Float64, func::Symbol)
    a = 1.27E-5
    n = 10
    L = 0.2
    δ = L / n
    λ = 50
    h = 1.0E9
    A = a / δ^2
    B = a / (δ^2 / 2 + δ * λ / h)
    p = [A, B, n]

    function to_index(i, j, n)
        return (i - 1) * n + j
    end
    function heat!(dT, T, p, t)
        A, B, n = p
        n = Int(n)
        Tf = Tout * (eval(func)(para * t))
        # 内部节点
        for i in 2:n-1
            for j in 2:n-1
                dT[to_index(i, j, n)] = A * (T[to_index(i + 1, j, n)] + T[to_index(i - 1, j, n)] + T[to_index(i, j + 1, n)] + T[to_index(i, j - 1, n)] - 4 * T[to_index(i, j, n)])
            end
        end
        # 边边界
        for i in 2:n-1
            dT[to_index(i, 1, n)] = A * (T[to_index(i + 1, 1, n)] + T[to_index(i - 1, 1, n)] + T[to_index(i, 2, n)]) - (3B + A) * T[to_index(i, 1, n)] + B * Tf
        end
        for i in 2:n-1
            dT[to_index(i, n, n)] = A * (T[to_index(i + 1, n, n)] + T[to_index(i - 1, n, n)] + T[to_index(i, n - 1, n)]) - (3B + A) * T[to_index(i, n, n)] + B * Tf
        end
        for i in 2:n-1
            dT[to_index(1, i, n)] = A * (T[to_index(1, i + 1, n)] + T[to_index(1, i - 1, n)] + T[to_index(2, i, n)]) - (3B + A) * T[to_index(1, i, n)] + B * Tf
        end
        for i in 2:n-1
            dT[to_index(n, i, n)] = A * (T[to_index(n, i + 1, n)] + T[to_index(n, i - 1, n)] + T[to_index(n - 1, i, n)]) - (3B + A) * T[to_index(1, i, n)] + B * Tf
        end
        # 角边界
        dT[to_index(1, 1, n)] = A * (T[to_index(2, 1, n)] + T[to_index(1, 2, n)]) - (2B + 2A) * T[to_index(1, 1, n)] + 2B * Tf
        dT[to_index(n, n, n)] = A * (T[to_index(n - 1, n, n)] + T[to_index(n, n - 1, n)]) - (2B + 2A) * T[to_index(n, n, n)] + 2B * Tf
        dT[to_index(n, 1, n)] = A * (T[to_index(n, 2, n)] + T[to_index(n - 1, 1, n)]) - (2B + 2A) * T[to_index(n, 1, n)] + 2B * Tf
        dT[to_index(1, n, n)] = A * (T[to_index(2, n, n)] + T[to_index(1, n - 1, n)]) - (2B + 2A) * T[to_index(1, n, n)] + 2B * Tf
    end

    u0 = [T0 for i in 1:n for j in 1:n]
    prob = ODEProblem(heat!, u0, (0, time), p, saveat=1)
    sol = solve(prob, Tsit5())

    an_len = length(sol.u)
    res = zeros(n, n, an_len)

    for t in 1:an_len
        for i in 1:n
            for j in 1:n
                res[i, j, t] = sol.u[t][to_index(i, j, n)]
            end
        end
    end
    return res
end


res = get_data(1000.0, 0.0, 100.0, 1.0, :_sign); # get_data test
