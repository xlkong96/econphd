##Set up Julia packages
import Pkg

cd(ARGS[1])
# cd("/Users/xkong/Dropbox/Study/Grad@UChicago/2021Fall/Trade-Dingle/assignments/assignment2_XK")
##Must be run once to install packages: (https://docs.julialang.org/en/v1/stdlib/Pkg/index.html)
Pkg.activate(".") # Create new environment in this folder
for package in ["StatFiles","FixedEffectModels","RegressionTables","DataFrames"]
    Pkg.add(package)
end

Pkg.instantiate() # Updates packages given .toml file
using StatFiles,FixedEffectModels,RegressionTables,DataFrames

df = DataFrame(load("detroit.dta"))

# pre-run package
reg(df[1:10000,:], @formula(log_flows ~ log_dist + fe(home_id) + fe(work_id)), Vcov.robust())
@time t3 = reg(df, @formula(log_flows ~ log_dist + fe(home_id) + fe(work_id)), Vcov.robust())
regtable(t3; renderSettings = latexOutput("t3_julia.tex"), estim_decoration = make_estim_decorator([0.01, 0.05, 0.1]))

