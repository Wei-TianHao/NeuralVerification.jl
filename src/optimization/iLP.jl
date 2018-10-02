# Iterative LP

struct ILP{O<:AbstractMathProgSolver} <: Feasibility
    optimizer::O
    max_iter::Int64
end

function solve(solver::ILP, problem::Problem)
    x = problem.input.center
    i = 0
    while i < solver.max_iter
        model = JuMP.Model(solver = solver.optimizer)
        act_pattern = get_activation(problem.network, x)

        neurons = init_neurons(model, problem.network)
        add_complementary_output_constraint(model, problem.output, last(neurons))
        encode_lp_constraint(model, problem.network, act_pattern, neurons)
        J = max_disturbance(model, first(neurons) - problem.input.center)

        status = JuMP.solve(model)
        if status != :Optimal
            return Result(:Unknown)
        end
        x = getvalue(first(neurons))
        if satisfy(problem.network, x, act_pattern)
            radius = getvalue(J)
            if radius >= minimum(problem.input.radius)
                return Result(:SAT, radius)
            else
                return Result(:UNSAT, radius)
            end
        end
        i += 1
    end
    return Result(:Unknown)
end

function satisfy(nnet::Network, x::Vector{Float64}, act_pattern::Vector{Vector{Bool}})
    curr_value = x
    for (i, layer) in enumerate(nnet.layers)
        curr_value = layer.weights * curr_value + layer.bias
        for j in 1:length(curr_value)
            if act_pattern[i][j] && curr_value[j] < 0.0
                return false
            end
            if ~act_pattern[i][j] && curr_value[j] > 0.0
                return false
            end
        end
        curr_value = layer.activation(curr_value)
    end
    return true
end