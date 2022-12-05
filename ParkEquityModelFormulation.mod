# Park Equity Modeling
# File: ParkEquityExportSolutions.run
# Purpose: To export solutions from AMPL into Excel
# Anisa Young, Emily Tucker, Mariela Fernandez, David White, Robert Brookover, Brandon Harris

# ------------------------------------------------------------------------------------------------

# SETS

set K; # set of all parks (existing and candidate) --> k
set L; # set of all resident locations --> l
set R; # set of all demographics --> r

# ------------------------------------------------------------------------------------------------

# PARAMETERS

# Normalization Parameters (n in formulation)
param DistNorm; # normalization for distance deviation
param CapNorm;  # normalization for capacity deviation
param HeatNorm; # normalization for heat deviation
param TreeNorm; # normalization for tree cover deviation

# Weight Parameters (w in formulation)
param DistWeight; # importance weight of added distance
param CapWeight; # importance weight of overcrowdiing
param HeatPlusWeight; # importance weight of heat beyond the desired range
param HeatMinusWeight; # importance weight of heat below the desired range
param TreePlusWeight; # importance weight of tree cover beyond the desired range
param TreeMinusWeight; # importance weight of tree cover below the desired range

# Big M Values (mu in the formulation)
param ActDistBigM; # big M for actual distance
param CapDevBigM; # big M for capacity deviation
param ActCapBigM; # big M for actual capacity

# Heat and Tree Cover Ranges (for export only)
param MaxHeat; # maximum desired heat
param MinHeat; # minimum desired heat
param MaxTree; # maximum desired tree cover
param MinTree; # minimum desired tree cover

# Demographic Strategic Target Priority Weight Parameter (q[r] in formulation)
param DemWeight {r in R}; # importance weight for demographic group r in R

# Resident Demographic Counts in Location Parameter (t[l,r])
param LRcount {l in L, r in R}; # count of residents in location l in L with demographic characteristic r in R

# Distance Parameters
param Distance {k in K, l in L}; # distance from primary park to resident location l in L (d[l] in formulation)
param MaxAllowDist; # max allowable distance from resident characteristic r in R to its primary park (m in formulation)

# Existing Park Parameters
param ParkExists {k in K}; # 0/1 park does not/does exist at park site k in K (e[k] in formulation)

# Park Capacity Parameters
param ParkCap {k in K}; # amount of capacity in park k in K (a[k] in formulation)

# Park Monetary Parameters
param Budget; # budget for park purchasing (b in formulation)
param ParkFee {k in K}; # fee to purchase park k in K (f[k] in formulation)

# Park Environment Parameters
param HeatPlus {k in K}; # amount of heat in park k in K above the allowable range (c_heat+[k] in formulation)
param HeatMinus {k in K}; # amount of heat in park k in K below the allowable range (c_heat-[k] in formulation)
param TreePlus {k in K}; # amount of tree cover in park k in K above the allowable range (c_tree+[k] in formulation)
param TreeMinus {k in K}; # amount of tree cover in park k in K below the allowable range (c_tree-[k] in formulation)

# ------------------------------------------------------------------------------------------------

# DECISION VARIABLES

# Main Decision Variables
var y {k in K} binary >= 0; # 0/1 park not/located at park site k in K
var x {k in K, l in L} binary >= 0; # 0/1 residents in location l in L not/assigned to park k in K

# Slack Variables
var DistPlus {l in L} >= 0; # distance to primary park beyond desired limit for location l in L (d+ in formulation)
var CapPlus {k in K} >= 0; # amount of overcrowding in park k in K for location l in L (a+ informulation)

# Binary Variable for Needing Slack Parameters
var NoDistSlack {l in L} binary >= 0; # 1 if do not need slack variable for distance (u in formulation)
var NoCapSlack {k in K} binary >= 0; # 1 if do not need slack variable for capacity (u in formulation)

# Linearization DVs (pi in formulation)
var LinActDist {l in L} >= 0; # DV defines the linearization of actual distance of location l in L to its primary park
var LinActCap {k in K} >= 0; # DV defines the linearization of actual capacity within park k in K
var LinCapPlusKL {k in K, l in L} >= 0; # DV defines the linearization of capacity of location l in L at park k in K

# DV defines the total cost of park purchasing
var TotalParkFee >= 0;

# Weighted Deviation Decision Variables

# Calculate R deviations --> deviations experienced by each demographic in set R
var DistDeviationR {r in R} >= 0; # weighted distance deviation per demographic
var CapDeviationR {r in R} >= 0; # weighted capacity deviation (overcrowding) per demographic
var HeatPDeviationR {r in R} >= 0; # weighted heat excess deviation per demographic
var HeatMDeviationR {r in R} >= 0; # weighted heat deficit deviation per demographic
var TreePDeviationR {r in R} >= 0; # weighted tree cover excess deviation per demographic
var TreeMDeviationR {r in R} >= 0; # weighted tree cover deficit deviation per demographic
var AllDeviationsR {r in R} >= 0; # weighted total deviation per demographic

var MaxTotalDevR >= 0; # maximum total weighted deviation of all demographic groupings
var MinTotalDevR >= 0; # minimum total weighted deviation of all demographic groupings

# STATUS DVs

# Check how many assignments exist (should be equal to the number of locations L)
var AssignNum >= 0;

# ------------------------------------------------------------------------------------------------

# OBJECTIVE FUNCTION

# minimize the maximum total demographic deviation
# minimize OF: MaxTotalDevR; # (objective function 1)

# OR

# minimize the overall deviations within the study area
minimize OF: sum {r in R} AllDeviationsR[r]; # (objective function 20)

# ------------------------------------------------------------------------------------------------

# CONSTRAINTS

# Allocation and Coverage Constraints
s.t. AssignOnePark {l in L}: sum {k in K} x[k,l] = 1; # ensure that all resident locations have exactly one primary park (constraint 4)
s.t. VisitOpenPark {k in K, l in L}: x[k,l] <= y[k]; # patrons may only visit selected parks (constraint 5)
s.t. PickExistPark {k in K}: ParkExists[k] <= y[k]; # if a park exists, then must select it (constraint 6)

# Land Purchasing Constraints
s.t. BudgetLimit: sum {k in K} ParkFee[k] * y[k] <= Budget; # the monetary cost to purchase land must be within the allocated budget (constraint 7)

# Distance Constraints
s.t. AllowedDistance {l in L}: (sum {k in K} Distance[k,l] * x[k,l]) - DistPlus[l] <= MaxAllowDist; # patrons within the maximum allowable distance from their primary park (constraint 8)
s.t. MinDistSlack {l in L}: DistPlus[l] - (sum {k in K} Distance[k,l] * x[k,l]) + MaxAllowDist + LinActDist[l] - (NoDistSlack[l] * MaxAllowDist) <= 0; # sets the minimum allowable distance slack variable value (constraint 26)
s.t. SetLinActDist1 {l in L}: LinActDist[l] <= ActDistBigM * NoDistSlack[l]; # linearization constraint (constraint 27)
s.t. SetLinActDist2 {l in L}: LinActDist[l] <= (sum {k in K} Distance[k,l] * x[k,l]); # linearization constraint constraint 28)
s.t. SetLinActDist3 {l in L}: LinActDist[l] >= (sum {k in K} Distance[k,l] * x[k,l]) - (ActDistBigM * (1 - NoDistSlack[l])); # linearization constraint (constraint 29)
s.t. SetLinActDist4 {l in L}: LinActDist[l] >= 0; # linearization constraint (constraint 30)

# Land Capacity Constraints
s.t. MeetCapacity {k in K}: (sum {l in L, r in R} LRcount[l,r] * x[k,l]) - CapPlus[k] <= ParkCap[k]; # the park size must be able to accommodate the patrons (constraint 10)
s.t. MinCapSlack {k in K}: CapPlus[k] - (sum {l in L, r in R} LRcount[l,r] * x[k,l]) + ParkCap[k] + LinActCap[k] - (ParkCap[k] * NoCapSlack[k]) <= 0; # sets the minimum allowable distance slack variable value (constraint 31)
s.t. SetLinActCap1 {k in K}: LinActCap[k] <= ActCapBigM * NoCapSlack[k]; # linearization constraint (constraint 32)
s.t. SetLinActCap2 {k in K}: LinActCap[k] <= (sum {l in L, r in R} LRcount[l,r] * x[k,l]); # linearization constraint (constraint 33)
s.t. SetLinActCap3 {k in K}: LinActCap[k] >= (sum {l in L, r in R} LRcount[l,r] * x[k,l]) - (ActCapBigM * (1 - NoCapSlack[k])); # linearization constraint (constraint 34)
s.t. SetLinActCap4 {k in K}: LinActCap[k] >= 0; # linearization constraint (constraint 35)

# Linearization of Capacity --> Overcrowding of Parks to Locations
s.t. SetLinCapPlusKL1 {k in K, l in L}: LinCapPlusKL[k,l] <= CapDevBigM * x[k,l]; # linearization constraint (constraint 22)
s.t. SetLinCapPlusKL2 {k in K, l in L}: LinCapPlusKL[k,l] <= CapPlus[k]; # linearization constraint (constraint 23)
s.t. SetLinCapPlusKL3 {k in K, l in L}: LinCapPlusKL[k,l] >= CapPlus[k] - (CapDevBigM * (1 - x[k,l]));  # linearization constraint (constraint 24)
s.t. SetLinCapPlusKL4 {k in K, l in L}: LinCapPlusKL[k,l] >= 0; # linearization constraint (constraint 25)

# WEIGHTED AND NORMALIZED DEVIATION BY POPULATION * * * * * * * * * * *

# Weighted and Normalized Demographic Deviations (together equate constraint 21)
s.t. SetDistDeviationR {r in R}: DistDeviationR[r] = DistNorm * DistWeight * sum {l in L} DemWeight[r] * LRcount[l,r] * DistPlus[l]; # demographic distance deviation calculation
s.t. SetCapDeviationR {r in R}: CapDeviationR[r] = CapNorm * CapWeight * sum {k in K, l in L} DemWeight[r] * LRcount[l,r] * LinCapPlusKL[k,l]; # demographic capacity deviation (overcrowding) calculation
s.t. SetHeatPDeviationR {r in R}: HeatPDeviationR[r] = HeatNorm * HeatPlusWeight * sum {k in K, l in L} DemWeight[r] * LRcount[l,r] * HeatPlus[k] * x[k,l]; # demographic heat excess deviation calculation
s.t. SetHeatMDeviationR {r in R}: HeatMDeviationR[r] = HeatNorm * HeatMinusWeight * sum {k in K, l in L} DemWeight[r] * LRcount[l,r] * HeatMinus[k] * x[k,l]; # demographic heat deficit deviation calculation
s.t. SetTreePDeviationR {r in R}: TreePDeviationR[r] = TreeNorm * TreePlusWeight * sum {k in K, l in L} DemWeight[r] * LRcount[l,r] * TreePlus[k] * x[k,l]; # demographic tree cover excess deviation calculation
s.t. SetTreeMDeviationR {r in R}: TreeMDeviationR[r] = TreeNorm * TreeMinusWeight * sum {k in K, l in L} DemWeight[r] * LRcount[l,r] * TreeMinus[k] * x[k,l]; # demographic tree cover deficit deviation calculation
s.t. SetTotalDeviationR {r in R}: AllDeviationsR[r] = DistDeviationR[r] + CapDeviationR[r] + HeatPDeviationR[r] + HeatMDeviationR[r] + TreePDeviationR[r] + TreeMDeviationR[r]; # total demographic deviations

# Select Min and Max Deviations	(constraint 3)
s.t. SetMaxTotalDevR {r in R}: MaxTotalDevR >= AllDeviationsR[r]; # find the maximum deviation of all demographic deviations

# * * * * * * * * * * * * * * * * SET STATUS DVs * * * * * * * * * * * * * * * *

# Set Cost Variable
s.t. SetTotalParkFee: TotalParkFee = sum {k in K} ParkFee[k] * y[k]; # calculates the total park purchasing fee

# NOT IN FORMULATION - Check how many assignments exist (should be equal to the number of locations L)
s.t. SetAssignNum: AssignNum = sum {k in K, l in L} x[k,l];
