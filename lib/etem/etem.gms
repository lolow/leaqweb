***********************
*                     *
* ETEM model for LEAQ *
*                     *
***********************
* Date     : 01/2011
* Version  : 1.0
* Authors  : L. Drouet
* Language : GAMS
* command  : gams etem.gms

$INCLUDE etem.inc

Variable
  OBJ              Objective value
;

Positive Variables
  VAR_OBJINV       Investment part of objective function
  VAR_OBJFIX       Fixed costs part of objective function
  VAR_OBJVAR       Variable costs part of objective function
  VAR_OBJSAL       Salvage value part of objective function
  VAR_ICAP(T,P)    Investment in new capacity
  VAR_IMP(T,S,IMP) Import activities
  VAR_EXP(T,S,EXP) Export activities
  VAR_COM(T,S,P,C) Commodity flow
;

Equations
  EQ_OBJ     Objective function
  EQ_OBJINV  Investment part of objective function
  EQ_OBJFIX  Fixed costs part of objective function
  EQ_OBJVAR  Variable costs part of objective function.
  EQ_OBJSAL  Salvage value part of objective function.
  EQ_COMBAL  Basic commodity balance equations ensuring that production >=/= consumption
  EQ_CAPACT  Capacity utilization equation
  EQ_PTRANS  Flow transformation constraint
  EQ_SHR_LO  Market/product share limit constraint
  EQ_SHR_UP
  EQ_SHR_FX
  EQ_PEAK    Peak activity equations
  EQ_ACT_LO  Activity bound constraints
  EQ_ACT_UP
  EQ_ACT_FX
  EQ_IMP_LO  Importation bound constraints
  EQ_IMP_UP
  EQ_IMP_FX
  EQ_EXP_LO  Exportation bound constraints
  EQ_EXP_UP
  EQ_EXP_FX
  EQ_FLO_LO  Flow bound constraints
  EQ_FLO_UP
  EQ_FLO_FX
  EQ_ICAP_LO New capacity bound constraints
  EQ_ICAP_UP
  EQ_ICAP_FX
  EQ_CAP_LO  Capacity bound constraints
  EQ_CAP_UP
  EQ_CAP_FX
  EQ_COM_NET_UP_TS  Net amount bound constraints per time slice  (t,s)
  EQ_COM_NET_UP_T   Net amount bound constraints per time period (t)
;



*###
*### Objective function
*###
*
*minimize OBJECTIVE : VAR_OBJINV + VAR_OBJFIX + VAR_OBJVAR - VAR_OBJSAL;
*
*
*###
*### Constraints
*###
*
*# Objective function constraints
*
*subject to EQ_OBJINV : 
*  VAR_OBJINV = sum{t in T, p in P} cost_icap[t,p]*VAR_ICAP[t,p]/((1+discount_rate)**(nb_completed_years[t]));
*
*subject to EQ_OBJFIX :
*  VAR_OBJFIX = sum{t in T, p in P} annualized*cost_fom[t,p]*
*               (sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]} VAR_ICAP[t1,p]+fixed_cap[t,p]) # capacity[t,p]
*               /((1+discount_rate)**(nb_completed_years[t]));
*
*subject to EQ_OBJVAR :
*  VAR_OBJVAR = sum{t in T} annualized*
*    ( 
*      sum{s in S} (
*        sum{p in P} cost_vom[t,p] * 
*                    sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,p,c]/act_flo[p,c] # activity[t,s,p] 
*       +sum{c in IMP} cost_imp[t,s,c] * VAR_IMP[t,s,c]
*       -sum{c in EXP} cost_exp[t,s,c] * VAR_EXP[t,s,c]
*       +sum{p in P, c in C_MAP[p]} cost_delivery[t,s,p,c] * VAR_COM[t,s,p,c]
*      )
*    )
*    /((1+discount_rate)**(nb_completed_years[t]));
*
*subject to EQ_OBJSAL :
*  VAR_OBJSAL = sum{t in T, p in P : t>=avail[p] and t+life[p]>nb_periods+1}
*    salvage[t,p]*cost_icap[t,p]*VAR_ICAP[t,p]/((1+discount_rate)**(nb_completed_years[t]));
*
*# Basic commodity balance equations (by type) ensuring that production >=/= consumption
*subject to EQ_COMBAL {t in T, s in S, c in C} :
*  (sum {p in P_PROD[c]} VAR_COM[t,s,p,c] +
*	if c in IMP then
*		VAR_IMP[t,s,c]
*	else
*		0
*   )*network_efficiency[c]
*  >=
*  if c not in DEM then 
*    sum{p in P_CONS[c]} VAR_COM[t,s,p,c] + 
*	if c in EXP then
*		VAR_EXP[t,s,c]
*	else
*	 	0
*  else
*    frac_dem[s,c]*demand[t,c];
*
*# capacity utilization equation
*subject to EQ_CAPACT {t in T, s in S, p in P} :
*  sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,p,c]/act_flo[p,c] # activity[t,s,p]
*   <= avail_factor[t,s,p]*cap_act[p]*fraction[s]*
*  (sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,p]+fixed_cap[t,p]); # capacity[t,p]
*
*# flow to flow transformation constraint
*subject to EQ_PTRANS {t in T, s in S, p in P, cg_in in FLOW_IN[p], cg_out in FLOW_OUT[p]: 
*    eff_flo[cg_in,cg_out]>0} :
*  sum{c_o in C_ITEMS[cg_out]} VAR_COM[t,s,p,c_o]
*= eff_flo[cg_in,cg_out] *
*  sum{c_i in C_ITEMS[cg_in]} VAR_COM[t,s,p,c_i];
*
*# market/product share limit constraints
*subject to EQ_SHR_LO {t in T, s in S, p in P, cg in FLOW_IN[p] union FLOW_OUT[p], c in C_ITEMS[cg] : flo_share_lo[cg,c]>0} :
*VAR_COM[t,s,p,c] >= flo_share_lo[cg,c]*sum{cc in C_ITEMS[cg]} VAR_COM[t,s,p,cc];
*
*subject to EQ_SHR_UP {t in T, s in S, p in P, cg in FLOW_IN[p] union FLOW_OUT[p], c in C_ITEMS[cg] : flo_share_up[cg,c]>0} :
*VAR_COM[t,s,p,c] <= flo_share_up[cg,c]*sum{cc in C_ITEMS[cg]} VAR_COM[t,s,p,cc];
*
*subject to EQ_SHR_FX {t in T, s in S, p in P, cg in FLOW_IN[p] union FLOW_OUT[p], c in C_ITEMS[cg] : flo_share_fx[cg,c]>0} :
*VAR_COM[t,s,p,c]  = flo_share_fx[cg,c]*sum{cc in C_ITEMS[cg]} VAR_COM[t,s,p,cc];
*
*# peak activity equations
*subject to EQ_PEAK {t in T, s in S, c in C} :
*  1/(1+peak_reserve[t,s,c])*(
*      sum{p in P_PROD[c] : c in C_ITEMS[flow_act[p]]} cap_act[p]*act_flo[p,c]*peak_prod[p,s,c]*fraction[s]*
*                              (sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,p]+fixed_cap[t,p]) # capacity[t,p] 
*    + sum{p in P_PROD[c] : c not in C_ITEMS[flow_act[p]]} peak_prod[p,s,c]*VAR_COM[t,s,p,c] 
*    + if c in IMP then
*		VAR_IMP[t,s,c]
*	else
*		0
*  )
*  >=
*  sum{p in P_CONS[c]} VAR_COM[t,s,p,c] + 	
*    if c in EXP then
*		VAR_EXP[t,s,c]
*	else
*	 	0;
*
*# activity bound constraints
*subject to EQ_ACT_LO {t in T, s in S, p in P : act_bnd_lo[t,s,p]>0} :
*  sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,p,c]/act_flo[p,c] # activity[t,s,p]
*   >= act_bnd_lo[t,s,p];
*
*subject to EQ_ACT_UP {t in T, s in S, p in P : act_bnd_up[t,s,p]>=0} :
*  sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,p,c]/act_flo[p,c] # activity[t,s,p]
*   <= act_bnd_up[t,s,p];
*
*subject to EQ_ACT_FX {t in T, s in S, p in P : act_bnd_fx[t,s,p]>=0} :
*  sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,p,c]/act_flo[p,c] # activity[t,s,p]
*   = act_bnd_fx[t,s,p];
*
*
*# importation bound constraints
*subject to EQ_IMP_LO {t in T, s in S, c in IMP : imp_bnd_lo[t,s,c]>0} :
*VAR_IMP[t,s,c] >= imp_bnd_lo[t,s,c];
*
*subject to EQ_IMP_UP {t in T, s in S, c in IMP : imp_bnd_up[t,s,c]>=0} :
*VAR_IMP[t,s,c] <= imp_bnd_up[t,s,c];
*
*subject to EQ_IMP_FX {t in T, s in S, c in IMP : imp_bnd_fx[t,s,c]>=0} :
*VAR_IMP[t,s,c] = imp_bnd_fx[t,s,c];
*
*# exportation bound constraints
*subject to EQ_EXP_LO {t in T, s in S, c in EXP : exp_bnd_lo[t,s,c]>0} :
*VAR_EXP[t,s,c] >= exp_bnd_lo[t,s,c];
*
*subject to EQ_EXP_UP {t in T, s in S, c in EXP : exp_bnd_up[t,s,c]>=0} :
*VAR_EXP[t,s,c] <= exp_bnd_up[t,s,c];
*
*subject to EQ_EXP_FX {t in T, s in S, c in EXP : exp_bnd_fx[t,s,c]>=0} :
*VAR_EXP[t,s,c] = exp_bnd_fx[t,s,c];
*
*# flow bound constraints
*subject to EQ_FLO_LO {t in T, s in S, p in P, cg in FLOW_IN[p] union FLOW_OUT[p] : flo_bnd_lo[t,s,cg]>0} :
*sum {c in C_ITEMS[cg]} VAR_COM[t,s,p,c] >= flo_bnd_lo[t,s,cg];
*
*subject to EQ_FLO_UP {t in T, s in S, p in P, cg in FLOW_IN[p] union FLOW_OUT[p] : flo_bnd_up[t,s,cg]>0} :
*sum {c in C_ITEMS[cg]} VAR_COM[t,s,p,c] <= flo_bnd_up[t,s,cg];
*
*subject to EQ_FLO_FX {t in T, s in S, p in P, cg in FLOW_IN[p] union FLOW_OUT[p] : flo_bnd_fx[t,s,cg]>0} :
*sum {c in C_ITEMS[cg]} VAR_COM[t,s,p,c] = flo_bnd_fx[t,s,cg];
*
*
*# new capacity bound constraints
*subject to EQ_ICAP_LO {t in T, p in P : icap_bnd_lo[t,p]>0} :
*VAR_ICAP[t,p] >= icap_bnd_lo[t,p];
*
*subject to EQ_ICAP_UP {t in T,  p in P : icap_bnd_up[t,p]>=0} :
*VAR_ICAP[t,p] <= icap_bnd_up[t,p];
*
*subject to EQ_ICAP_FX {t in T, p in P : icap_bnd_fx[t,p]>=0} :
*VAR_ICAP[t,p] = icap_bnd_fx[t,p];
*
*# capacity bound constraints
*subject to EQ_CAP_LO {t in T, p in P : cap_bnd_lo[t,p]>0} :
*    sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,p]+fixed_cap[t,p] # capacity[t,p]
*     >= cap_bnd_lo[t,p];
*
*subject to EQ_CAP_UP {t in T, p in P : cap_bnd_up[t,p]>=0} :
*	sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,p]+fixed_cap[t,p] # capacity[t,p]
*	 <= cap_bnd_up[t,p];
*
*subject to EQ_CAP_FX {t in T, p in P : cap_bnd_fx[t,p]>=0} :
*	sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,p]+fixed_cap[t,p] # capacity[t,p]
*	 = cap_bnd_fx[t,p];
*
*# net amount bound constraints per time slice (t,s)
*subject to EQ_COM_NET_UP_TS {t in T, s in S, c in C : com_net_bnd_up_ts[t,s,c]>=0} :
*	(sum{p in P_PROD[c]} VAR_COM[t,s,p,c] + if c in IMP then VAR_IMP[t,s,c] else 0) - # procurement
*	(sum{p in P_CONS[c]} VAR_COM[t,s,p,c] + if c in EXP then VAR_EXP[t,s,c] else 0)   # disposal
*	 <= com_net_bnd_up_ts[t,s,c];
*
*# net amount bound constraints per time period (t)
*subject to EQ_COM_NET_UP_T {t in T, c in C : com_net_bnd_up_t[t,c]>=0} :
*    sum{s in S}(
*	 (sum{p in P_PROD[c]} VAR_COM[t,s,p,c] + if c in IMP then VAR_IMP[t,s,c] else 0) - # procurement
*	 (sum{p in P_CONS[c]} VAR_COM[t,s,p,c] + if c in EXP then VAR_EXP[t,s,c] else 0)   # disposal
*	) <= com_net_bnd_up_t[t,c];
*
*###
*### Solve statement
*###
*
*solve;
*
*###
*### Output parameters
*###
*
*# Relationship between process activity & individual primary commodity flows
*param activity{t in T,s in S, p in P} := sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,p,c]/act_flo[p,c];
*
*# Capacity transfer
*param capacity{t in T, p in P} := sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]} VAR_ICAP[t1,p]+fixed_cap[t,p];
*
*# Commodity production
*param production{t in T, s in S, c in C} := sum{ p in P_PROD[c] inter P } VAR_COM[t,s,p,c];
*
*param consumption{t in T, s in S, c in C} := sum{ p in P_CONS[c] inter P } VAR_COM[t,s,p,c];
*
*# Commodity procurement
*param procurement{t in T, s in S, c in C} := sum{ p in P_PROD[c] } VAR_COM[t,s,p,c] + if c in IMP then VAR_IMP[t,s,c] else 0;
*
*# Commodity disposal
*param disposal{t in T, s in S, c in C} := sum{ p in P_CONS[c] } VAR_COM[t,s,p,c] + if c in EXP then VAR_EXP[t,s,c] else 0;
*
*# Commodity net amount
*param total_net_amount{t in T, s in S, c in C} := procurement[t,s,c] - disposal[t,s,c];
*
*#
*# All outputs
*#
*#
*
*printf "attribute,T,S,P,C,value\n";
*
*#Without index
*printf "VAR_OBJINV,,,,,%f\n", VAR_OBJINV;
*printf "VAR_OBJFIX,,,,,%f\n", VAR_OBJFIX;
*printf "VAR_OBJVAR,,,,,%f\n", VAR_OBJVAR;
*printf "VAR_OBJSAL,,,,,%f\n", VAR_OBJSAL;
*
**#T,P
*for {t in T, p in P}{
*  printf "CAPACITY,%s,,%s,,%f\n", t, p , capacity[t,p];
*}
*
*#T,P
*for {t in T, p in P}{
*  printf "VAR_ICAP,%s,,%s,,%f\n", t , p , VAR_ICAP[t,p];
*}
*
*#T, S, P
*for {t in T, s in S, p in P}{
*  printf "ACTIVITY,%s,%s,%s,,%f\n", t, s, p , activity[t,s,p];
*}
*for {t in T,p in P}{
*  printf "ACTIVITY,%s,ANNUAL,%s,,%f\n", t , p , sum {s in S} activity[t,s,p];
*}
*
*#T, S, C
*for {t in T, s in S, c in IMP}{
*  printf "VAR_IMP,%s,%s,,%s,%f\n", t, s, c, VAR_IMP[t,s,c];
*}
*for {t in T, c in IMP}{
*  printf "VAR_IMP,%s,ANNUAL,,%s,%f\n", t, c, sum {s in S}VAR_IMP[t,s,c];
*}
*for {t in T, s in S, c in EXP}{
*  printf "VAR_EXP,%s,%s,,%s,%f\n", t, s, c, VAR_EXP[t,s,c];
*}
*for {t in T, c in EXP}{
*  printf "VAR_EXP,%s,ANNUAL,,%s,%f\n", t, c, sum {s in S}VAR_EXP[t,s,c];
*}

*#T, S, C
*for {t in T, s in S, c in C}{
*  printf "C_PRICE,%s,%s,,%s,%f\n", t, s, c, EQ_COMBAL[t,s,c].dual;
*}

*#T,S,P,C
*for {t in T, s in S, p in P, c in C_MAP[p]}{
*  printf "VAR_COM,%s,%s,%s,%s,%f\n", t, s, p, c, VAR_COM[t,s,p,c];
*}

*#T,P,C
*for {t in T, p in P, c in C_MAP[p]}{
*  printf "VAR_COM,%s,ANNUAL,%s,%s,%f\n", t, p, c, sum{s in S} VAR_COM[t,s,p,c];
*}

*#CHECK DEMAND
*for {t in T, dem in DEM}{
*  printf "CHK_DEM,%s,,,%s,%f\n", t, dem , sum{s in S, p in P_PROD[dem]} (fixed_cap[t,p]*fraction[s]*cap_act[p]*
*                                                                 avail_factor[t,s,p]*act_flo[p,dem]) - demand[t,dem];
*}

*#T,C
*for {t in T, c in DEM}{
*  printf "DEMAND,%s,ANNUAL,,%s,%f\n", t, c, demand[t,c];
*}

*end;
