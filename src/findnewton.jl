# findnewton.jl
#
#   Faster search for sorted array
#
# Jeremy Rüffer
# Thünen Institut
# Institut für Agrarklimaschutz
# Junior Research Group NITROSPHERE
# Julia 0.7
# 09.12.2016
# Last Edit: 28.06.2018

" findnewton{T<:Any}(x,target::Array{T,1};max_iterations::Int,verbose::Bool)

In a sorted data set, search iteratively for the target value/s. Uses Newtonian method, look in the center for a match. If value is greater look halfway between end and current value. If less than look between current value and previous low value. Range will be halved each time until the same index or the sentinal value (iteration max) have been reached.

---

#### Keywords:\n
* max_iterations::Int = Maximum number of iterations to attempt, 1000 is default
* verbose::Bool = Display imformation as the function runs, FALSE is default\n\n

---

\n
#### Related Functions:\n
* searchsorted
* searchsortedfirst
* searchsortedlast"
function findnewton(x,target::Array{T,1};max_iterations::Int=1000,verbose::Bool=false) where T <: Any
	answer = Array{Int}(undef,length(target))
	answer[1] = findnewton(x,target[1];max_iterations=max_iterations,verbose=verbose)
	lastgood = Int(1)
	temp = []
	bad_vals = false
	for i=2:1:length(target)
		temp = findnewton(x,target[i];max_iterations=max_iterations,verbose=verbose)
		if temp <= answer[lastgood] + 1
			# If the answer is the same or just one more than the previous value
			# then a gap has been found, mark it for later deletion
			answer[i] = -1
			bad_vals = true
		else
			answer[i] = temp
			lastgood = i
		end
	end

	# Remove Bad Values
	if bad_vals
		answer = answer[findall(answer .!= -1)]
	end

	return answer
end

function findnewton(x,target;max_iterations::Int=1000,verbose::Bool=false)
	if verbose
		println("Min = " * string(findmin(x)[1]))
		println("Max = " * string(findmax(x)[1]))
		println("Target = " * string(target) * "\n")
	end
	
	############################
	##  Initialize Variables  ##
	############################
	lower = 1
	upper = length(x)
	test = false
	sentinal = 1
	answer = []

	########################
	##  Newtonian Search  ##
	########################
	while !test && sentinal < max_iterations
		mid = Int(lower + floor((upper-lower)/2))
		verbose ? println("  Iteration (" * string(sentinal) * ") = " * string(x[mid])) : []
		if x[mid] > target
			# Target is higher than guess
			if upper == mid
				test = true
				answer = mid
			else
				upper = mid
			end
		elseif x[mid] < target
			# Target is lower than guess
			if lower == mid
				test = true
				answer = mid
			else
				lower = mid
			end
		else
			# Exact Match!
			test = true
			answer = mid
		end
	
		sentinal += 1
	end

	# Sentinal Catch Case
	if sentinal >= max_iterations
		warn("Sentinal value reached, returned value may not be the best answer.")
		answer = mid
	end

	if verbose
		println("\nIndex = " * string(int(answer)))
		println("Answer = " * string(x[answer]) * "\n")
	end
	return Int(answer)
end
