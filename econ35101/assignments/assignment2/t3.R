args = commandArgs(trailingOnly = TRUE)
setwd(args[1])
# setwd("/Users/xkong/Dropbox/Study/Grad@UChicago/2021Fall/Trade-Dingle/assignments/assignment2_XK")
install.packages(c("fixest","haven"), repos = "http://cran.us.r-project.org")
library(fixest)
library(haven)

df = read_dta("detroit.dta")

start_time <- Sys.time()
fixest = feols(log_flows ~ log_dist | home_id + work_id , df, vcov = "hetero")
end_time <- Sys.time()
print(end_time - start_time)

etable(fixest, tex = TRUE, file = "t3_R.tex", replace = TRUE)
