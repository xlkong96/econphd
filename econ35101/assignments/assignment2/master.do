cap log close
clear all

* install packages
foreach pkg in reghdfe ppml hdfe poi2hdfe ppmlhdfe heatplot {
	cap ssc install `pkg'
}

* change directory
if "`c(username)'"=="xkong" & regexm(c(os),"Mac")==1 {
	global maindir = "/Users/xkong/Dropbox/Study/Grad@UChicago/2021Fall/Trade-Dingle/assignments/assignment2_XK"
	global julia_path = "/Applications/Julia-1.6.app/Contents/Resources/julia/bin/julia"
	global R_path = "/usr/local/bin/Rscript"
	global datadir = "$maindir/data"
}
else if "`c(username)'"=="<username>" & regexm(c(os),"<os>")==1 {
	global maindir = ""
	global julia_path = ""
	global R_path = ""
	global datadir = ""
}

cd "${maindir}"

cap program drop run_reg
program define run_reg

	if inlist("`1'","reg","glm","pplm") local fe = "i.home_id i.work_id"
	else if inlist("`1'","xtreg") local fe = "i.work_id, fe"
	else if inlist("`1'","areg") local fe = "i.work_id, ab(home_id)"
	else if inlist("`1'","reghdfe","ppmlhdfe") local fe = ", ab(home_id work_id)"
	else if inlist("`1'","poi2hdfe") local fe = ", id1(home_id) id2(work_id)"
	
	timer clear
	timer on 1 
	eststo: qui `1' `2' `3' `4' `fe'
	timer off 1
	qui timer list 1
	estadd scalar T = r(t1)

end

do "tables_stata.do"
shell $julia_path "$maindir/t3.jl" "$maindir"
shell $R_path $maindir/t3.R "$maindir"
