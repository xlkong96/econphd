import delimited "$datadir/detroit.csv", varnames(1) clear

gen log_flows = log(flows)
ren distance_google_miles dist
ren duration_minutes time
gen log_dist = log(dist)
gen log_time = log(time)

label var dist "driving distance"
label var time "driving time"
label var log_dist "log(driving distance)"
label var log_time "log(driving time)"

xtset home_id work_id 


* table 1
foreach x in dist time {
	eststo clear
	foreach cmd in reg xtreg areg reghdfe {
		run_reg "`cmd'" log_flows log_`x'
	}
	esttab using "t1`x'.tex", replace b se r2 scalars(T) nocon keep(log_`x') booktabs mtitles("reg" "xtreg" "areg" "reghdfe") label star(* 0.1 ** 0.05 *** 0.01)
}


* table 2
gen log_flows1 = log(flows+1)
gen log_flows2 = log(flows+0.01)

gen flows_temp1 = flows if home_id==work_id
egen flows_temp2 = min(flows_temp1), by(work_id)
gen flows_temp3 = flows
replace flows_temp3 = 1e-12 * flows_temp2 if flows==0 & home_id~=work_id
gen log_flows3 = log(flows_temp3)
cap drop flows_temp*

eststo clear
run_reg "reghdfe" "log_flows" "log_dist" "if flows~=0"
run_reg "reghdfe" "log_flows1" "log_dist" "if flows~=0" 
run_reg "reghdfe" "log_flows1" "log_dist" "" 
run_reg "reghdfe" "log_flows2" "log_dist" "" 
run_reg "reghdfe" "log_flows3" "log_dist" "" 
run_reg "poi2hdfe" "flows" "log_dist" "" 
run_reg "ppmlhdfe" "flows" "log_dist" "" 
run_reg "ppmlhdfe" "flows" "log_dist" "if flows~=0"
esttab using "t2.tex", replace b se r2 scalars(T) nocon keep(log_dist) nomtitles booktabs label star(* 0.1 ** 0.05 *** 0.01)

* Breusch–Pagan test
qui reg log_flows log_dist i.home_id i.work_id if flows~=0
estat hettest

* plot residuals
predict res, r
heatplot res log_dist, bwidth(.1) levels(5) colors(spmap) legend(off) xtitle("Log distance") ytitle("Residuals") name(res,replace) scheme(s1mono)
gr export "hetres.pdf", as(pdf) replace

cap drop res res2


* table 3
eststo clear
timer clear
timer on 1 
eststo: reghdfe log_flows log_dist, ab(home_id work_id) vce(robust)
timer off 1
qui timer list 1
estadd scalar T = r(t1)
esttab using "t3_stata.tex", replace b se r2 scalars(T) nocon keep(log_dist) nomtitles booktabs label star(* 0.1 ** 0.05 *** 0.01)

eststo clear
compress 
save "detroit.dta", replace