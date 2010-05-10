###############
#             #
# ETEM model  #
#             # 
###############
# Date     : 11/2008
# Version  : 2.0
# Authors  : L. Drouet et J. Thenie
# Language : GMPL
# command  : glpsol -m model_file.mod -d data_file.dat -y display_file.txt -o output_file.txt
# example  : glpsol -m etem.mod -d geneva.dat

param nb_periods    >=1;
param period_length >=1;     # expressed in year.

set T := 1..nb_periods;      # time periods.
set L;                       # localization
set S;                       # slice periods
set P;                       # processes
set C;                       # commodities
set DEM within C;            # useful demands
set IMP within C;            # imported commodities
set EXP within C;            # exported commodities
set FLOW;                    # commodities groups labels
set FLOW_IN{P} within FLOW;  # incoming flows 
set FLOW_OUT{P} within FLOW; # outcoming flows
set C_ITEMS{FLOW} within C;  # set of commodities
set P_MAP{L} within P;       # localization of processes

# COMPUTED SETS
set C_MAP{p in P}  within C := setof{f in FLOW_IN[p], c in C_ITEMS[f]}(c) union setof{f in FLOW_OUT[p], c in C_ITEMS[f]}(c); 
set P_PROD{c in C} within P := setof{p in P, f in FLOW_OUT[p]: c in C_ITEMS[f]}(p);
set P_CONS{c in C} within P := setof{p in P, f in FLOW_IN[p]: c in C_ITEMS[f]}(p);

# GIVEN PARAMETERS
param discount_rate;
param act_flo{P,C};                 # conversion factor from flow to activity.
param avail_factor{T,S,P};          # availability factor
param avail{P};                     # availability period.
param cap_act{P};                   # conversion factor from capacity to activity
param cost_delivery{T,S,P,C};       # delivery cost of a commodity for a process
param cost_exp{T,S,C};              # export costs.
param cost_fom{T,P};                # operation and maintenance fixed cost.
param cost_icap{T,P};               # investment cost of one capacity unit.
param cost_imp{T,S,C};              # import costs.
param cost_vom{T,P};                # operation and maintenance variable cost.
param demand{T,DEM};                # useful demand.
param eff_flo{FLOW,FLOW};           # efficiency ratio for a specified process between 2 flows.
param fixed_cap{T,L,P};             # fixed capacity (residual cap.).
param flow_act{P} symbolic in FLOW; # flow which define process activity
param flo_share_fx{FLOW,C};         # fixed flow share of c in the total flow
param flo_share_lo{FLOW,C};         # lower bound of the flow share of c in the total flow
param flo_share_up{FLOW,C};         # upper bound of the flow share of c in the total flow
param fraction{S};                  # fraction of the year (for capacities).
param frac_dem{S,DEM};              # fraction of the year (for demands).
param life{P};                      # process life duration expressed in periods.
param network_efficiency{C};        # infrastructure efficiency
param peak_prod{P,S,C};             # ration on production which can be use at peak period
param peak_reserve{T,S,C};          # reserve on production

param act_bnd_fx{T,S,L,P};          # fixed activity
param act_bnd_lo{T,S,L,P};          # lower bound on activity
param act_bnd_up{T,S,L,P};          # upper bound on activity
param cap_bnd_fx{T,L,P};            # fixed capacity
param cap_bnd_lo{T,L,P};            # lower bound on capacity
param cap_bnd_up{T,L,P};            # upper bound on capacity
param com_net_bnd_up_ts{T,S,C};     # upper bound on total net amount
param com_net_bnd_up_t{T,C};        # upper bound on total net amount
param exp_bnd_fx{T,S,EXP};          # fixed exportation
param exp_bnd_lo{T,S,EXP};          # lower bound on exportation
param exp_bnd_up{T,S,EXP};          # upper bound on exportation
param flo_bnd_fx{T,S,FLOW};         # fixed flow
param flo_bnd_lo{T,S,FLOW};         # lower bound on flow
param flo_bnd_up{T,S,FLOW};         # upper bound on flow
param icap_bnd_fx{T,L,P};           # fixed new capacity
param icap_bnd_lo{T,L,P};           # lower bound on new capacity
param icap_bnd_up{T,L,P};           # upper bound on new capacity
param imp_bnd_fx{T,S,IMP};          # fixed importation
param imp_bnd_lo{T,S,IMP};          # lower bound on importation
param imp_bnd_up{T,S,IMP};          # upper bound on importation

# COMPUTED PARAMETERS
param nb_completed_years{t in T} := # number of completed years
  (t-1)*period_length;
param annualized :=                 # factor to annualize a period
  sum{y in 1..period_length} (1+discount_rate)**(1-y); 
param salvage{t in T, p in P} :=    # parameter used for salvage value
   (1-(1+discount_rate)**(-period_length*(t+life[p]-nb_periods-1)))
  /(  (1+discount_rate)**( period_length*(nb_periods+1-t)))
  /(1-(1+discount_rate)**(-period_length*life[p])); 

# VARIABLES (objective part)
var VAR_OBJINV >=0;      # investment part of objective function.
var VAR_OBJFIX >=0;      # fixed costs part of objective function.
var VAR_OBJVAR >=0;      # variable costs part of objective function.
var VAR_OBJSAL >=0;      # salvage value part of objective function.

# VARIABLES (decisions)
var VAR_ICAP{T,l in L,P_MAP[l]}   >=0;               # investment capacity
var VAR_IMP{T,S,IMP}  >=0;                           # import activities 
var VAR_EXP{T,S,EXP}  >=0;                           # export activities
var VAR_COM{T,S,l in L,p in P_MAP[l],C_MAP[p]}>=0;   # commodity flow


###
### Objective function
###

minimize OBJECTIVE : VAR_OBJINV + VAR_OBJFIX + VAR_OBJVAR - VAR_OBJSAL;


###
### Constraints
###

# Objective function constraints

subject to EQ_OBJINV : 
  VAR_OBJINV = sum{t in T, l in L, p in P_MAP[l]} cost_icap[t,p]*VAR_ICAP[t,l,p]/((1+discount_rate)**(nb_completed_years[t]));
  
subject to EQ_OBJFIX :
  VAR_OBJFIX = sum{t in T, l in L, p in P_MAP[l]} annualized*cost_fom[t,p]*
               (sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]} VAR_ICAP[t1,l,p]+fixed_cap[t,l,p]) # capacity[t,p]
               /((1+discount_rate)**(nb_completed_years[t]));
  
subject to EQ_OBJVAR :
  VAR_OBJVAR = sum{t in T} annualized*
    ( 
      sum{s in S} (
        sum{l in L, p in P_MAP[l]} cost_vom[t,p] * 
                    sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,l,p,c]/act_flo[p,c] # activity[t,s,p] 
       +sum{c in IMP} cost_imp[t,s,c] * VAR_IMP[t,s,c]
       -sum{c in EXP} cost_exp[t,s,c] * VAR_EXP[t,s,c]
       +sum{l in L, p in P_MAP[l], c in C_MAP[p]} cost_delivery[t,s,p,c] * VAR_COM[t,s,l,p,c]
      )
    )
    /((1+discount_rate)**(nb_completed_years[t]));
  
subject to EQ_OBJSAL :
  VAR_OBJSAL = sum{t in T, l in L, p in P_MAP[l] : t>=avail[p] and t+life[p]>nb_periods+1}
    salvage[t,p]*cost_icap[t,p]*VAR_ICAP[t,l,p]/((1+discount_rate)**(nb_completed_years[t]))  ;  
  
# Basic commodity balance equations (by type) ensuring that production >=/= consumption
subject to EQ_COMBAL {t in T, s in S, c in C} :
  (sum{l in L, p in P_PROD[c] inter P_MAP[l]} VAR_COM[t,s,l,p,c] + 
	if c in IMP then
		VAR_IMP[t,s,c]
	else
		0
   )*network_efficiency[c]
  >=
  if c not in DEM then 
    sum{l in L, p in P_CONS[c] inter P_MAP[l]} VAR_COM[t,s,l,p,c] + 
	if c in EXP then
		VAR_EXP[t,s,c]
	else
	 	0
  else
    frac_dem[s,c]*demand[t,c];

# capacity utilization equation
subject to EQ_CAPACT {t in T, s in S, l in L, p in P_MAP[l]} :
  sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,l,p,c]/act_flo[p,c] # activity[t,s,p]
   <= avail_factor[t,s,p]*cap_act[p]*fraction[s]*
  (sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,l,p]+fixed_cap[t,l,p]); # capacity[t,p]

# flow to flow transformation constraint
subject to EQ_PTRANS {t in T, s in S, l in L, p in P_MAP[l], cg_in in FLOW_IN[p], cg_out in FLOW_OUT[p]: 
    eff_flo[cg_in,cg_out]>0} :
  sum{c_o in C_ITEMS[cg_out]} VAR_COM[t,s,l,p,c_o]
= eff_flo[cg_in,cg_out] *
  sum{c_i in C_ITEMS[cg_in]} VAR_COM[t,s,l,p,c_i];

# market/product share limit constraints
subject to EQ_SHR_LO {t in T, s in S, l in L, p in P_MAP[l], cg in FLOW_IN[p] union FLOW_OUT[p], c in C_ITEMS[cg] : flo_share_lo[cg,c]>0} :
VAR_COM[t,s,l,p,c] >= flo_share_lo[cg,c]*sum{cc in C_ITEMS[cg]} VAR_COM[t,s,l,p,cc];

subject to EQ_SHR_UP {t in T, s in S, l in L, p in P_MAP[l], cg in FLOW_IN[p] union FLOW_OUT[p], c in C_ITEMS[cg] : flo_share_up[cg,c]>0} :
VAR_COM[t,s,l,p,c] <= flo_share_up[cg,c]*sum{cc in C_ITEMS[cg]} VAR_COM[t,s,l,p,cc];

subject to EQ_SHR_FX {t in T, s in S, l in L, p in P_MAP[l], cg in FLOW_IN[p] union FLOW_OUT[p], c in C_ITEMS[cg] : flo_share_fx[cg,c]>0} :
VAR_COM[t,s,l,p,c]  = flo_share_fx[cg,c]*sum{cc in C_ITEMS[cg]} VAR_COM[t,s,l,p,cc];

# peak activity equations
subject to EQ_PEAK {t in T, s in S, c in C} :
  1/(1+peak_reserve[t,s,c])*(
      sum{l in L, p in P_PROD[c] inter P_MAP[l] : c in C_ITEMS[flow_act[p]]} cap_act[p]*act_flo[p,c]*peak_prod[p,s,c]*fraction[s]*
                              (sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,l,p]+fixed_cap[t,l,p]) # capacity[t,p] 
    + sum{l in L, p in P_PROD[c] inter P_MAP[l] : c not in C_ITEMS[flow_act[p]]} peak_prod[p,s,c]*VAR_COM[t,s,l,p,c] 
    + if c in IMP then
		VAR_IMP[t,s,c]
	else
		0
  )
  >=
  sum{l in L, p in P_CONS[c] inter P_MAP[l]} VAR_COM[t,s,l,p,c] + 	
    if c in EXP then
		VAR_EXP[t,s,c]
	else
	 	0;

# activity bound constraints
subject to EQ_ACT_LO {t in T, s in S, l in L, p in P_MAP[l] : act_bnd_lo[t,s,l,p]>0} :
  sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,l,p,c]/act_flo[p,c] # activity[t,s,p]
   >= act_bnd_lo[t,s,l,p];

subject to EQ_ACT_UP {t in T, s in S, l in L, p in P_MAP[l] : act_bnd_up[t,s,l,p]>=0} :
  sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,l,p,c]/act_flo[p,c] # activity[t,s,p]
   <= act_bnd_up[t,s,l,p];

subject to EQ_ACT_FX {t in T, s in S, l in L, p in P_MAP[l] : act_bnd_fx[t,s,l,p]>=0} :
  sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,l,p,c]/act_flo[p,c] # activity[t,s,p]
   = act_bnd_fx[t,s,l,p];

# importation bound constraints
subject to EQ_IMP_LO {t in T, s in S, c in IMP : imp_bnd_lo[t,s,c]>0} :
VAR_IMP[t,s,c] >= imp_bnd_lo[t,s,c];

subject to EQ_IMP_UP {t in T, s in S, c in IMP : imp_bnd_up[t,s,c]>=0} :
VAR_IMP[t,s,c] <= imp_bnd_up[t,s,c];

subject to EQ_IMP_FX {t in T, s in S, c in IMP : imp_bnd_fx[t,s,c]>=0} :
VAR_IMP[t,s,c] = imp_bnd_fx[t,s,c];

# exportation bound constraints
subject to EQ_EXP_LO {t in T, s in S, c in EXP : exp_bnd_lo[t,s,c]>0} :
VAR_EXP[t,s,c] >= exp_bnd_lo[t,s,c];

subject to EQ_EXP_UP {t in T, s in S, c in EXP : exp_bnd_up[t,s,c]>=0} :
VAR_EXP[t,s,c] <= exp_bnd_up[t,s,c];

subject to EQ_EXP_FX {t in T, s in S, c in EXP : exp_bnd_fx[t,s,c]>=0} :
VAR_EXP[t,s,c] = exp_bnd_fx[t,s,c];

# flow bound constraints
subject to EQ_FLO_LO {t in T, s in S, l in L, p in P_MAP[l], cg in FLOW_IN[p] union FLOW_OUT[p] : flo_bnd_lo[t,s,cg]>0} :
sum {c in C_ITEMS[cg]} VAR_COM[t,s,l,p,c] >= flo_bnd_lo[t,s,cg];

subject to EQ_FLO_UP {t in T, s in S, l in L, p in P_MAP[l], cg in FLOW_IN[p] union FLOW_OUT[p] : flo_bnd_up[t,s,cg]>0} :
sum {c in C_ITEMS[cg]} VAR_COM[t,s,l,p,c] <= flo_bnd_up[t,s,cg];

subject to EQ_FLO_FX {t in T, s in S, l in L, p in P_MAP[l], cg in FLOW_IN[p] union FLOW_OUT[p] : flo_bnd_fx[t,s,cg]>0} :
sum {c in C_ITEMS[cg]} VAR_COM[t,s,l,p,c] = flo_bnd_fx[t,s,cg];

# new capacity bound constraints
subject to EQ_ICAP_LO {t in T, l in L, p in P_MAP[l] : icap_bnd_lo[t,l,p]>0} :
VAR_ICAP[t,l,p] >= icap_bnd_lo[t,l,p];

subject to EQ_ICAP_UP {t in T, l in L, p in P_MAP[l] : icap_bnd_up[t,l,p]>=0} :
VAR_ICAP[t,l,p] <= icap_bnd_up[t,l,p];

subject to EQ_ICAP_FX {t in T, l in L, p in P_MAP[l] : icap_bnd_fx[t,l,p]>=0} :
VAR_ICAP[t,l,p] = icap_bnd_fx[t,l,p];

# capacity bound constraints
subject to EQ_CAP_LO {t in T, l in L, p in P_MAP[l] : cap_bnd_lo[t,l,p]>0} :
    sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,l,p]+fixed_cap[t,l,p] # capacity[t,p]
     >= cap_bnd_lo[t,l,p];

subject to EQ_CAP_UP {t in T, l in L, p in P_MAP[l] : cap_bnd_up[t,l,p]>=0} :
	sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,l,p]+fixed_cap[t,l,p] # capacity[t,p]
	 <= cap_bnd_up[t,l,p];

subject to EQ_CAP_FX {t in T, l in L, p in P_MAP[l] : cap_bnd_fx[t,l,p]>=0} :
	sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]}VAR_ICAP[t1,l,p]+fixed_cap[t,l,p] # capacity[t,p]
	 = cap_bnd_fx[t,l,p];

# net amount bound constraints per time slice (t,s)
subject to EQ_COM_NET_UP_TS {t in T, s in S, c in C : com_net_bnd_up_ts[t,s,c]>=0} :
	(sum{l in L, p in P_PROD[c] inter P_MAP[l]} VAR_COM[t,s,l,p,c] + if c in IMP then VAR_IMP[t,s,c] else 0) - # procurement
	(sum{l in L, p in P_CONS[c] inter P_MAP[l]} VAR_COM[t,s,l,p,c] + if c in EXP then VAR_EXP[t,s,c] else 0)   # disposal
	 <= com_net_bnd_up_ts[t,s,c];

# net amount bound constraints per time period (t)
subject to EQ_COM_NET_UP_T {t in T, c in C : com_net_bnd_up_t[t,c]>=0} :
    sum{s in S}(
	 (sum{l in L, p in P_PROD[c] inter P_MAP[l]} VAR_COM[t,s,l,p,c] + if c in IMP then VAR_IMP[t,s,c] else 0) - # procurement
	 (sum{l in L, p in P_CONS[c] inter P_MAP[l]} VAR_COM[t,s,l,p,c] + if c in EXP then VAR_EXP[t,s,c] else 0)   # disposal
	) <= com_net_bnd_up_t[t,c];

###
### Solve statement
###

solve;

###
### Output parameters
###

# Relationship between process activity & individual primary commodity flows
param activity{t in T,s in S, l in L, p in P_MAP[l]} := sum{c in C_ITEMS[flow_act[p]]} VAR_COM[t,s,l,p,c]/act_flo[p,c];

# Capacity transfer
param capacity{t in T, l in L, p in P_MAP[l]} := sum{t1 in 1..t : t1>=t-life[p]+1 and t1>=avail[p]} VAR_ICAP[t1,l,p]+fixed_cap[t,l,p];

# Commodity production
param production{t in T, s in S, c in C} := sum{l in L, p in P_PROD[c] inter P_MAP[l] } VAR_COM[t,s,l,p,c];

param consumption{t in T, s in S, c in C} := sum{l in L, p in P_CONS[c] inter P_MAP[l] } VAR_COM[t,s,l,p,c];

# Commodity procurement
param procurement{t in T, s in S, c in C} := sum{l in L, p in P_PROD[c] inter P_MAP[l] } VAR_COM[t,s,l,p,c] + if c in IMP then VAR_IMP[t,s,c] else 0;

# Commodity disposal
param disposal{t in T, s in S, c in C} := sum{l in L, p in P_CONS[c] inter P_MAP[l] } VAR_COM[t,s,l,p,c] + if c in EXP then VAR_EXP[t,s,c] else 0;

# Commodity net amount
param total_net_amount{t in T, s in S, c in C} := procurement[t,s,c] - disposal[t,s,c];

#
# All outputs
#
#

printf "attribute,T,S,L,P,C,value\n";

#Without index
printf "VAR_OBJINV,,,,,,%f\n", VAR_OBJINV;
printf "VAR_OBJFIX,,,,,,%f\n", VAR_OBJFIX;
printf "VAR_OBJVAR,,,,,,%f\n", VAR_OBJVAR;
printf "VAR_OBJSAL,,,,,,%f\n", VAR_OBJSAL;

#T,L,P
for {t in T, l in L, p in P_MAP[l]}{
  printf "CAPACITY,%s,,%s,%s,,%f\n", t, l , p , capacity[t,l,p];
}

#T,L,P
for {t in T, l in L, p in P_MAP[l]}{
  printf "VAR_ICAP,%s,,%s,%s,,%f\n", t, l , p , VAR_ICAP[t,l,p];
}

#T, S, L, P
for {t in T, s in S, l in L, p in P_MAP[l]}{
  printf "ACTIVITY,%s,%s,%s,%s,,%f\n", t, s, l , p , activity[t,s,l,p];
}
for {t in T, l in L, p in P_MAP[l]}{
  printf "ACTIVITY,%s,ANNUAL,%s,%s,,%f\n", t, l , p , sum {s in S} activity[t,s,l,p];
}

#T, S, C
for {t in T, s in S, c in IMP}{
  printf "VAR_IMP,%s,%s,,,%s,%f\n", t, s, c, VAR_IMP[t,s,c];
}
for {t in T, c in IMP}{
  printf "VAR_IMP,%s,ANNUAL,,,%s,%f\n", t, c, sum {s in S}VAR_IMP[t,s,c];
}
for {t in T, s in S, c in EXP}{
  printf "VAR_EXP;%s;%s;;;%s;%f\n", t, s, c, VAR_EXP[t,s,c];
}
for {t in T, c in EXP}{
  printf "VAR_EXP;%s;ANNUAL;;;%s;%f\n", t, c, sum {s in S}VAR_EXP[t,s,c];
}

#T,S,L,P,C
for {t in T, s in S, l in L, p in P_MAP[l], c in C_MAP[p]}{
  printf "VAR_COM,%s,%s,%s,%s,%s,%f\n", t, s, l, p, c, VAR_COM[t,s,l,p,c];
}

#T,L,P,C
for {t in T,  l in L, p in P_MAP[l], c in C_MAP[p]}{
  printf "VAR_COM,%s,ANNUAL,%s,%s,%s,%f\n", t, l, p, c, sum{s in S} VAR_COM[t,s,l,p,c];
}

#CHECK DEMAND
for {t in T, dem in DEM}{
  printf "CHK_DEM,%s,%s,,,,%f\n", t, dem , sum{s in S, l in L, p in P_PROD[dem]} (fixed_cap[t,l,p]*fraction[s]*cap_act[p]*
                                                                 avail_factor[t,s,p]*act_flo[p,dem]) - demand[t,dem];
}

end;