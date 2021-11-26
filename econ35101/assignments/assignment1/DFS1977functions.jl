function DFS1977plotAB(a::Array{Float64,2},b::Array{Float64,1},L::Array{Float64,1})

    A = a[:,1]./a[:,2]

    N = size(a)[1]
    ϑ = cumsum(b, dims = 1)
    ϑ = ifelse.(ϑ .> 1, 1, ϑ) # max of cumsum goes slightly over 1 due to numeric error
    L_ratio = L[1]/L[2]
    B = ϑ ./ (1 .- ϑ) .* L_ratio
        
    z = (1:N)./N
    plotAB = plot()
    plot!(z, A, label = "A(z)", color = "red", xlabel = "z", ylims = (0, 5))
    plot!(z, B, label = "B(z)", color = "blue", xlabel = "z", ylims = (0, 5))

    return plotAB
end


function DFS1977solver(a::Array{Float64,2},b::Array{Float64,1},L::Array{Float64,1},g::Float64)

    # STEP 1: PERFORM ERROR CHECK
    error_count = 0
    error_message = ""
    # 1. verify that a has dimension N-by-2 (where N>2) and is non-negative
    if size(a)[1] <= 2
        error_count = error_count + 1
        error_message = error_message * "ERROR $error_count: a only has $size(a)[1] rows."
    end
    if prod(a.>=0) == 0
        error_count = error_count + 1
        error_message = error_message * " " * "ERROR $error_count: some elements in a is negative."
    end
    # 2. verify that A = a[:,1]./a[:,2] is monotone decreasing (equation 1 in DFS)
    A = a[:,1]./a[:,2]
    D_A = A[2:end] - A[1:end-1]
    if prod(D_A.<=0) == 0
        error_count = error_count + 1
        error_message = error_message * " " * "ERROR $error_count: A (relative productivity schedule) is not monotonic decreasing."
    end 
    # 3. verify that b is a vector of dimension N (the same length as A), strictly positive, and that sum(b)==1
    if size(b)[1] != size(a)[1]
        error_count = error_count + 1
        error_message = error_message * " " * "ERROR $error_count: a and b have different number of rows."
    end
    if prod(b.>0) == 0
        error_count = error_count + 1
        error_message = error_message * " " * "ERROR $error_count: some elements in b is not positive."
    end
    if abs(sum(b) - 1.0) > 1e-10
        error_count = error_count + 1
        error_message = error_message * " " * "ERROR $error_count: sum of elements in b is not 1."
    end
    # 4. verify that g is a scalar in (0,1] (as assumed in DFS III.B)
    if g <= 0 || g > 1
        error_count = error_count + 1
        error_message = error_message * " " * "ERROR $error_count: g is not in (0,1]."
    end
    if error_count > 0
        return error(error_message)
    else 
        # println("No error in inputs is detected. Proceed to output.")
    # STEP 2: PRODUCE OUTPUT

        A = a[:,1]./a[:,2]

        # determine \bar{z} and \bar{z}^*
        zbarH_fnc(ω) = argmin((A .- ω.*g).^2)
        zbarF_fnc(ω) = argmin((A .- ω./g).^2)

        # calculate \lambda and \lambda^*
        λH(ω) = sum(b[1:zbarH_fnc(ω)])
        λF(ω) = sum(b[zbarF_fnc(ω)+1:end])

        # define \psi, RHS of equation (19')
        L_ratio = L[1]./L[2]
        ψ(ω) = (1 .- λF(ω)) ./ (1 .- λH(ω)) .* L_ratio

        # do a grid search and solve for \omega
        ω_vec = 0.0:0.001:2.0
        ωbar = ω_vec[argmin( abs.(ψ.(ω_vec) .- ω_vec) )]

        # evaluate at the solution
        zbarH = zbarH_fnc(ωbar)
        zbarF = zbarF_fnc(ωbar)
        ωbar = A[zbarF] .* g
        AbarH = A[zbarH]
        AbarF = A[zbarF]

        return zbarH, AbarH, zbarF, AbarF, ωbar

    end
end


function DFS1977welfare(a::Array{Float64,2},b::Array{Float64,1},L::Array{Float64,1},g::Float64)

    zbarH, AbarH, zbarF, AbarF, ωbar = DFS1977solver(a,b,L,g)

    # autarky
    Uha = log(L[2]) - sum(b.*log.(a[:,2]))
    Ufa = log(L[1]) - sum(b.*log.(a[:,1]))
    
    # trade
    N = size(a)[1]
    himp = (zbarH+1):N
    hprod = 1:zbarH
    fimp = 1:zbarF
    fprod = (zbarF+1):N

    Uht = log(L[2]) .- sum( b[hprod] .* log.(a[hprod,2]) ) .- sum( b[himp] .* log.(a[himp,1]./ωbar./g) )
    Uft = log(L[1]/ωbar) .- sum( b[fprod] .* log.(a[fprod,1]./ωbar) ) .- sum( b[fimp] .* log.(a[fimp,2]./g) )
    
    GFTh = Uht - Uha
    GFTf = Uft - Ufa

    return Uha, Uht, GFTh, Ufa, Uft, GFTf

end



function DFS1977volume(a::Array{Float64,2},b::Array{Float64,1},L::Array{Float64,1},g::Float64)

    zbarH, AbarH, zbarF, AbarF, ωbar = DFS1977solver(a,b,L,g)

    # volumn of trade = home imports + foreign imports = home imports + home exports
    # home_imports = sum(b[(zbarH+1):end]./a[(zbarH+1):end,1].*ωbar.*L[2].*g) 
    # home_exports = sum(b[1:zbarF]./a[1:zbarF,2]./ωbar.*L[1].*g)
    # value of trade for home
    VOT = sum(b[(zbarH+1):end].*L[2]) + sum(b[1:zbarF]./ωbar.*L[1])

    return VOT

end