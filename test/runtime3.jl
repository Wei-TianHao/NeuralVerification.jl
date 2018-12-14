# ConvDual, Duality
# Problem spec - input: Hyperrectangle with uniform radisu, outputL half space constraint

using NeuralVerification
using Test

macro no_error(ex)
    quote
        try $(esc(ex))
            true
        catch
            false
        end
    end
end

at = @__DIR__

# Problem type - input:Hyperrectangle, output:Hyperrectangle
print("###### Group 3 - input:Hyperrectangle, output:Hpolytope (with 1 constraint) ######\n")
# Small MNIST Network 

mnist_small = read_nnet("$at/../examples/networks/mnist_small.nnet")

# entry 23 in MNIST datset
input_center = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,121,254,136,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,13,230,253,248,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,4,118,253,253,225,42,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,61,253,253,253,74,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,32,206,253,253,186,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,211,253,253,239,69,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,254,253,253,133,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,142,255,253,186,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,149,229,254,207,21,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,54,229,253,254,105,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,152,254,254,213,26,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,112,251,253,253,26,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,29,212,253,250,149,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,36,214,253,253,137,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,75,253,253,253,59,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,93,253,253,189,17,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,224,253,253,84,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,43,235,253,126,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,99,248,253,119,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,225,235,49,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
#output_center = [-1311.1257826380004,4633.767704436501,-654.0718535670002,-1325.349417307,1175.2361184373997,-1897.8607293569007,-470.3405972940001,830.8337987382,-377.7467076115001,572.3674015264198]

in_epsilon = 1 #0-255
out_epsilon = 10 #logit domain

input_low = input_center .- in_epsilon
input_high = input_center .+ in_epsilon

#output_low = output_center .- out_epsilon
#output_high = output_center .+ out_epsilon

inputSet = Hyperrectangle(low=input_low, high=input_high)
#outputSet = Hyperrectangle(low=output_low, high=output_high)





A = Matrix(undef, 2, 1)
A = [1.0, -1, 0, 0, 0, 0, 0, 0, 0 ,0]'
b = [0.0]
outputSet = HPolytope(A, b)

########### Small ############
# Problem type - input:Hyperrectangle, output:Hpolytope (one constraint)

problem_hyperrect_halfspace_small = Problem(mnist_small, inputSet, outputSet)
print("################## Small ##################\n")

# Duality
print("\nDuality - Small")
optimizer = GLPKSolverMIP()
solver = Duality(optimizer)
#@time solve(solver, problem_hyperrect_halfspace_small)

# ConvDual
print("\nConvDual - Small")
optimizer = GLPKSolverMIP()
solver = ConvDual()
@time solve(solver, problem_hyperrect_halfspace_small)

########### Deep ############
print("################## Deep ##################\n")

mnist_deep = read_nnet("$at/../examples/networks/mnist_large.nnet")
problem_hyperrect_halfspace_deep = Problem(mnist_deep, inputSet, outputSet)

# Duality
print("\nDuality - Deep")
optimizer = GLPKSolverMIP()
solver = Duality(optimizer)
#@time solve(solver, problem_hyperrect_halfspace_deep)

# ConvDual
print("\nConvDual - Deep")
optimizer = GLPKSolverMIP()
solver = ConvDual()
@time solve(solver, problem_hyperrect_halfspace_deep)

########### Wide ############
print("################## Wide ##################\n")

mnist_wide = read_nnet("$at/../examples/networks/mnist-1-100.nnet")
problem_hyperrect_halfspace_wide = Problem(mnist_wide, inputSet, outputSet)

# Duality
print("\nDuality - Wide")
optimizer = GLPKSolverMIP()
solver = Duality(optimizer)
#@time solve(solver, problem_hyperrect_halfspace_deep)

# ConvDual
print("\nConvDual - Wide")
optimizer = GLPKSolverMIP()
solver = ConvDual()
@time solve(solver, problem_hyperrect_halfspace_deep)
