# This method only works for half space output constraint
# c y <= d
# For this implementation, limit the input constraint to Hyperrectangle

struct Duality{O<:AbstractMathProgSolver} <: Feasibility
    optimizer::O
end

# False if J > 0, True if J <= 0
function interpret_result(solver::Duality, status, J)
    if status != :Optimal
        return Result(:Unknown)
    end
    opt_cost = getvalue(J)
    # println(opt_cost)
    return ifelse(opt_cost <= 0.0, Result(:SAT), Result(:UNSAT))
end

function encode(solver::Duality, model::Model, problem::Problem)
    layers = problem.network.layers
    n_layer = length(layers)
    bounds = get_bounds(problem)
    c, d = tosimplehrep(problem.output)

    λ = init_multipliers(model, problem.network)
    μ = init_multipliers(model, problem.network)
    
    ## J the objective function
    J = -d[1]
    # Input constraint
    J += input_layer_cost(layers[1], μ[1], problem.input)
    # Cost for all linear layers
    for i in 2:n_layer
        J += layer_cost(layers[i], μ[i], λ[i-1], bounds[i])
    end
    # Cost for activation
    for i in 1:n_layer
        J += activation_cost(layers[i], μ[i], λ[i], bounds[i])
    end

    # output constraint
    @constraint(model, λ[n_layer] .== -c)
    @objective(model, Min, J)

    return J
end

# For each layer l and node k
# max { mu[l][k] * z - lambda[l][k] * act(z) }
function activation_cost(layer, μ, λ, bound)
    J = zero(typeof(first(μ)))
    (W, b, act) = (layer.weights, layer.bias, layer.activation)
    for k in 1:length(b)
        z = W[k, :]' * bound.center + b[k]
        r = sum(abs.(W[k, :]) .* bound.radius)
        high = μ[k] * (z + r) - λ[k] * act(z + r)
        low = μ[k] * (z - r) - λ[k] * act(z - r)
        J += symbolic_max(high, low)
    end
    return J
end

# For all layer l
# max { λ[l-1]' * x[l] - μ[l]' * (W[l] * x[l] + b[l]) }
# x[i] belongs to a Hyperrectangle
# TODO consider bringing in μᵀ instead of μ
function layer_cost(layer, μ, λ, bound)
    (W, b) = (layer.weights, layer.bias)
    J = λ' * bound.center - μ' * (W * bound.center + b)
    # instead of for-loop:
    J += sum(symbolic_abs(λ - W' * μ) .* bound.radius) # TODO check that this is equivalent to before
    return J
end

# Input constraint
# max { - mu[1]' * (W[1] * input + b[1]) }
# input belongs to a Hyperrectangle
function input_layer_cost(layer, μ, input)
    W, b = layer.weights, layer.bias

    J = - μ' * (W * input.center .+ b)
    J += sum(symbolic_abs.(μ' * W) .* input.radius)   # TODO check that this is equivalent to before
    return J
end