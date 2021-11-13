##Dingel, DFS 1977, example of function call

##Set up Julia packages
import Pkg

##Must be run once to install packages: (https://docs.julialang.org/en/v1/stdlib/Pkg/index.html)
rootdir = "/Users/xkong/Dropbox/Study/Grad@UChicago/2021Fall/Trade - Dingle"
run(`mkdir -p $rootdir/assignments/assignment1_XK`) ##Create a folder for this project (https://docs.julialang.org/en/v1.0.0/manual/running-external-programs/)
cd(rootdir * "/assignments/assignment1_XK")

Pkg.activate(".") # Create new environment in this folder
for package in ["CSV","LaTeXStrings","Interpolations","Plots","Distributions","DataFrames","DataFramesMeta"]
    Pkg.add(package)
end

Pkg.instantiate() # Updates packages given .toml file
using CSV,DelimitedFiles,LaTeXStrings,Interpolations,Plots,Random,Distributions,DataFrames,DataFramesMeta #Load packages

include("DFS1977functions.jl")


# Plots the A(z) and B(z;L*/L) functions that appear in equations (1) and (10') of DFS to produce a version of DFS Figure 1 
a = readdlm("DFS1977_example_a.txt");
b = vec(readdlm("DFS1977_example_b.txt"));
L = ones(2);
fig1 = DFS1977plotAB(a,b,L)
savefig(fig1, "fig1.pdf")

# Given a, b, L, and g, solve for the value \bar{\omega}
zbarH1, AbarH1, zbarF1, AbarF1, ωbar1 = DFS1977solver(a,b,L,1.0)
println("Solution when g = 1.0: z_bar_star = ", zbarF1, " z_bar = ", zbarH1, " omega_bar = ", ωbar1)
zbarH2, AbarH2, zbarF2, AbarF2, ωbar2 = DFS1977solver(a,b,L,0.9)
println("Solution when g = 0.9: z_bar_star = ", zbarF2, " z_bar = ", zbarH2, " omega_bar = ", ωbar2)


# Compute home and foreign welfare
Uha, Uht, Ufa, Uft = DFS1977welfare(a,b,L,1.0)
GFTh = Uht - Uha
GFTf = Uft - Ufa
println("Autarky welfare: home = ", Uha, " foreign = ", Ufa)
println("Trade welfare: home = ", Uht, " foreign = ", Uft)
println("Gains from trade: home = ", GFTh, "foreign = ", GFTf)

# Uniformly change foreign technology
fshock = [1.0, 0.9, 0.8]
Uha  = zeros(length(fshock))
Uht  = zeros(length(fshock))
GFTh = zeros(length(fshock))
Ufa  = zeros(length(fshock))
Uft  = zeros(length(fshock))
GFTf = zeros(length(fshock))

for i = 1:length(fshock)
    tech_shock = hcat(ones(size(a)[1]).*fshock[i], ones(size(a)[1]).*1.0)
    Uha[i],Uht[i],GFTh[i],Ufa[i],Uft[i],GFTf[i] = round.(DFS1977welfare(a.*tech_shock,b,L,1.0); digits = 3)
end

# Write a latex table
open("tech_shock.tex", "w") do io
    write(io, "\\begin{tabular}{lcccccc} \n")
    write(io, "\\hline\\hline \n")
    write(io, "Foreign technological change, \$\\hat{a}^*(z)\$ & \\multicolumn{2}{c}{1.0} & \\multicolumn{2}{c}{0.9} & \\multicolumn{2}{c}{0.8} \\\\ \n ")
    write(io, " & Home & Foreign & Home & Foreign & Home & Foreign \\\\ \n ")
    write(io, "\\cmidrule(l r){2-3} \\cmidrule(l r){4-5} \\cmidrule(l r){6-7} \n")
    write(io, "Autarky welfare & $(Uha[1]) & $(Ufa[1]) & $(Uha[2]) & $(Ufa[2]) & $(Uha[3]) & $(Ufa[3]) \\\\ \n")
    write(io, "Trade welfare & $(Uht[1]) & $(Uft[1]) & $(Uht[2]) & $(Uft[2]) & $(Uht[3]) & $(Uft[3]) \\\\ \n")
    write(io, "Gains from trade & $(GFTh[1]) & $(GFTf[1]) & $(GFTh[2]) & $(GFTf[2]) & $(GFTh[3]) & $(GFTf[3]) \\\\ \n")
    write(io, "\\hline\\hline \n")
    write(io, "\\end{tabular}")
end

# Check multiple equilibria
# Simulate 100 different a and b and compute home GFT, foreign GFT, and volume of trade, then plot
num_sim = 500
sim_output1 = zeros(num_sim, 6)

N = 150 # no. of varieties
L = ones(2)
g = 0.9

for i in 1:num_sim
    println("Iteration $i")
    Random.seed!(i)
    aa = hcat(ones(N,1), 0.25.*ones(N,1) .+ rand(N,1));
    aa[:,2] = sort(aa[:,2])
    bb = 0.5.*rand(N) + 0.5.*ones(N)
    bb = bb ./ sum(bb)

    zbarH,AbarH,zbarF,AbarF,ωbar = DFS1977solver(aa,bb,L,g)
    Uha,Uht,GFTh,Ufa,Uft,GFTf = DFS1977welfare(aa,bb,L,g)
    VOT = DFS1977volume(aa,bb,L,g)

    sim_output1[i,1] = ωbar
    sim_output1[i,2] = zbarH
    sim_output1[i,3] = zbarF
    sim_output1[i,4] = GFTh
    sim_output1[i,5] = GFTf
    sim_output1[i,6] = VOT
end

p1 = scatter(sim_output1[:,6],sim_output1[:,4], xlabel = "Volume of trade", ylabel = "Home GFT (blue)", legend = false, markeralpha = 0.25, markersize = 3, markercolor = :blue, left_margin = 3Plots.mm, right_margin = 15Plots.mm)
scatter!(twinx(),sim_output1[:,6],sim_output1[:,5], xlabel = "Volume of trade", ylabel = "Foreign GFT (red)", legend = false, markeralpha = 0.25, markersize = 3, markercolor = :red, left_margin = 3Plots.mm, right_margin = 15Plots.mm)
savefig(p1, "VOT_GFT.pdf")

multi_eq_table1 = round.(sim_output1[round.(sim_output1[:,6]; digits = 3).==0.753, :]; digits = 3)
open("multi_eq.tex", "w") do io
    write(io, "\\begin{tabular}{ccccccc} \n")
    write(io, "\\toprule \n")
    write(io, " & \$\\bar{\\omega}\$ & \$\\bar{z}\$ & \$\\bar{z}^*\$ & \$GFT\$ & \$GFT^*\$ & \$VOT\$ \\\\ \n ")
    write(io, "\\midrule \n")
    for i = 1:4
        write(io, "($i) & $(multi_eq_table1[i,1]) & $(multi_eq_table1[i,2]) & $(multi_eq_table1[i,3]) & $(multi_eq_table1[i,4]) & $(multi_eq_table1[i,5]) & $(multi_eq_table1[i,6]) \\\\ \n")
    end
    write(io, "\\bottomrule \n")
    write(io, "\\end{tabular}")
end

# Now, hold b fixed
sim_output2 = zeros(num_sim, 6)

for i in 1:num_sim
    println("Iteration $i")
    Random.seed!(i)
    aa = hcat(ones(N,1), 0.25.*ones(N,1) .+ rand(N,1));
    aa[:,2] = sort(aa[:,2])

    zbarH,AbarH,zbarF,AbarF,ωbar = DFS1977solver(aa,b,L,g)
    Uha,Uht,GFTh,Ufa,Uft,GFTf = DFS1977welfare(aa,b,L,g)
    VOT = DFS1977volume(aa,b,L,g)

    sim_output2[i,1] = ωbar
    sim_output2[i,2] = zbarH
    sim_output2[i,3] = zbarF
    sim_output2[i,4] = GFTh
    sim_output2[i,5] = GFTf
    sim_output2[i,6] = VOT
end

multi_eq_table2 = round.(sim_output2[round.(sim_output2[:,6]; digits = 3).==0.753, :]; digits = 3)
open("multi_eq_fixb.tex", "w") do io
    write(io, "\\begin{tabular}{ccccccc} \n")
    write(io, "\\toprule \n")
    write(io, " & \$\\bar{\\omega}\$ & \$\\bar{z}\$ & \$\\bar{z}^*\$ & \$GFT\$ & \$GFT^*\$ & \$VOT\$ \\\\ \n ")
    write(io, "\\midrule \n")
    for i = 1:4
        write(io, "($i) & $(multi_eq_table2[i,1]) & $(multi_eq_table2[i,2]) & $(multi_eq_table2[i,3]) & $(multi_eq_table2[i,4]) & $(multi_eq_table2[i,5]) & $(multi_eq_table2[i,6]) \\\\ \n")
    end
    write(io, "\\bottomrule \n")
    write(io, "\\end{tabular}")
end

p2 = scatter(sim_output2[:,6],sim_output2[:,4], xlabel = "Volume of trade", ylabel = "Home GFT (blue)", legend = false, markeralpha = 0.25, markersize = 3, markercolor = :blue, left_margin = 3Plots.mm, right_margin = 15Plots.mm)
scatter!(twinx(),sim_output2[:,6],sim_output2[:,5], xlabel = "Volume of trade", ylabel = "Foreign GFT (red)", legend = false, markeralpha = 0.25, markersize = 3, markercolor = :red, left_margin = 3Plots.mm, right_margin = 15Plots.mm)
savefig(p2, "VOT_GFT_fixb.pdf")
