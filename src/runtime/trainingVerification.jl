

function net_diff(net1, net2)
    max_delta = 0
    for (i, layer1) in enumerate(net1.layers)
        layer2 = net2.layers[i]
        max_delta = max(max_delta, maximum(layer1.weights - layer2.weights))
        max_delta = max(max_delta, maximum(layer1.bias - layer2.bias))
    end
    return max_delta
end

function solve(problems::TrainingProblem, max_branches=50, branch_management=false, perturbation_tolerence=0.0, samples=nothing)
    
    # solver = perturbation_tolerence > 0 ? IntervalNet(max_iter = 1, delta = (perturbation_tolerence, perturbation_tolerence))
    #                                     : Neurify(max_iter = 1) # max_iter=1 because we are doing branch management outside.

    solver = IntervalNet(max_iter = 1, delta = (perturbation_tolerence, perturbation_tolerence))

    problems = TrainingProblem(problems.networks, convert(HPolytope, problems.input), convert(HPolytope, problems.output))

    cnt = 0
    total_time = 0

    sat_idx = []
    vio_idx = []
    tim_idx = []
    err_idx = []
    tim_rec = []
    sat_rec = []
    cnt_rec = []
    cov_rec = []

    problem = Problem(problems.networks[1], problems.input, problems.output)
    splits_order = generate_ordinal_splits_order(problems.networks[1], max_branches)
    result, branches, samples_branch = init_split_given_order(solver, problem, max_branches, splits_order, samples)
    # println(solve(solver, problem))

    timed_result = @timed check_all_leaves(solver, problem, branches)
    result, result_dict, cnts = timed_result.value

    coverage = compute_coverage(branches, result_dict, size(problems.networks[1].layers[1].weights, 2), samples_branch)
    
    println("size(branches.leaves)")
    println(length(branches.leaves))
    last_net_id = 1
    last_unk_cnt = cnts

    # print_tree(branches, 1)
    
    for (i, nnet) in enumerate(problems.networks)
        
        # println("====")
        diff = net_diff(nnet, problems.networks[last_net_id]);
        # println("iter:", i, " net diff: ", diff)
        if diff < perturbation_tolerence
            append!(cnt_rec, cnts)
            append!(cov_rec, coverage)
            append!(tim_rec, 0)
            continue
        end
        last_net_id = i

        problem = Problem(nnet, problems.input, problems.output)

        if !branch_management
            result, branches, samples_branch = init_split_given_order(solver, problem, max_branches, splits_order, samples)
        end

        timed_result = @timed check_all_leaves(solver, problem, branches)
        result, result_dict, cnts = timed_result.value

        if branch_management && cnts[2] > last_unk_cnt[2]
            result, branches, samples_branch = init_split_given_order(solver, problem, max_branches, splits_order, samples)
            timed_result = @timed check_all_leaves(solver, problem, branches)
            result, result_dict, cnts = timed_result.value
            last_unk_cnt = cnts
        end
        println("cnts, coverage: ",cnts, " ", coverage)
        total_time += timed_result.time

        coverage = compute_coverage(branches, result_dict, size(problems.networks[1].layers[1].weights, 2), samples_branch)
        append!(cov_rec, coverage)
        append!(cnt_rec, cnts)
        append!(tim_rec, timed_result.time)
        # println("Output: ")
        # println(result)
        # println("")
        # println(branches.size)
        if branch_management
            merge_holds_nodes!(solver, problem, branches, result_dict) # try to merge holds nodes to save memory resources.
        end
        # merge_holds_nodes_general!(solver, problem, branches, result_dict) # try to merge holds nodes to save memory resources.
        # break
        # println(branches.size)
        # println(result_dict)
        unknown_leaves = [k for (k,v) in result_dict if v.status==:unknown] # because branches.leaves may change in the split process
        # println(unknown_leaves)
        for leaf in unknown_leaves
            # println(leaf, ' ', result_dict[leaf].status)
            result_dict[leaf].status == :unknown && ordinal_split!(solver, problem, branches, leaf, max_branches, splits_order) # split unknown nodes
        end

        # println(branches.size)
        if result.status == :violated 
            noisy = NeuralVerification.compute_output(nnet, result.counter_example)
            append!(vio_idx, i)
            println("======== found counter example ========")
            println("index: " * string(i))
            println("Time: " * string(timed_result[2]) * " s")
            println("Input:   ", result.counter_example)
            println("Counter pred:   ", noisy[:,:]')
            println("=======================================")
        elseif result.status == :unknown
            append!(tim_idx, i)
            # println("Timed out")
        else
            append!(sat_idx, i)
            # println("Holds")
        end
    end

    return tim_rec, cnt_rec

end