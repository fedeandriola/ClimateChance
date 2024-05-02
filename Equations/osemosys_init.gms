scalar default_max /1e8/;

YearSplit(l,y) = 1/card(l)/365; #by default, equally long timeslices
DiscountRate(r) = 0.05; 
TradeRoute(r,rr,f,y) = 0; 
DepreciationMethod(r) = 1;

*** parameters on demand 
SpecifiedAnnualDemand(r,f,y) = 0;
mandProfile(r,f,l,y) = 1/card(l);
AccumulatedAnnualDemand(r,f,y) = 0;

*** parameter on technology characteristics
CapacityToActivityUnit(r,t) = 1;
CapacityToActivityUnit(r,t)$(power_plants(t)) = 31.536;
CapacityFactor(r,t,l,y) = 1;
AvailabilityFactor(r,t,y) = 1;
OperationalLife(r,t) = 0;
ResidualCapacity(r,t,y) = 0;

CapitalCost(r,t,y) = 0;
VariableCost(r,t,m,y) = 0;
FixedCost(r,t,y) = 0;  

*** WHY THIS DOESN'T WORK?
*InputActivityRatio(r,t,f,m,y) = 0;
*OutputActivityRatio(r,t,f,m,y) = 0;

**** makes a mip the problem
CapacityOfOneTechnologyUnit(r,t,y) = 0; #by default, not a MIP

*** constraints on max capacity, investment, activity
TotalAnnualMaxCapacity(r,t,y) = default_max;
TotalAnnualMinCapacity(r,t,y) = 0;
TotalAnnualMaxCapacityInvestment(r,t,y) = default_max;
TotalAnnualMinCapacityInvestment(r,t,y) = 0;
TotalTechnologyAnnualActivityUpperLimit(r,t,y) = default_max;
TotalTechnologyAnnualActivityLowerLimit(r,t,y) = 0;
TotalTechnologyModelPeriodActivityUpperLimit(r,t) = default_max;
TotalTechnologyModelPeriodActivityLowerLimit(r,t) = 0;

*** reserve margin parameters initialization
ReserveMarginTagTechnology(r,t,y) = 0;
ReserveMarginTagFuel(r,f,y) = 0;
ReserveMargin(r,y) = 0;

*** renewable parameters initialization
RETagTechnology(r,t,y) = 0;
RETagFuel(r,f,y) = 0;
REMinProductionTarget(r,y) = 0;

*** emission parameters initialization
EmissionsPenalty(r,e,y) = 0;
AnnualExogenousEmission(r,e,y) = 0;
AnnualEmissionLimit(r,e,y) = default_max;
ModelPeriodExogenousEmission(r,e) = 0;
ModelPeriodEmissionLimit(r,e) = default_max;
EmissionActivityRatio(r,t,e,m,y) = 0;

*** storage related parameters initialization
$ifthen.storage set storage
DaySplit(y,lh) = 1/365; 
Conversionls(l,ls) = 1;
Conversionld(l,ld) = 1;
Conversionlh(l,lh) = 1;
DaysInDayType(y,ls,ld) = 7;
StorageLevelStart(r,s) = 0;
TechnologyToStorage(r,m,t,s) = 0;
TechnologyFromStorage(r,m,t,s) = 0;
StorageMaxChargeRate(r,s) = 99;
StorageMaxDischargeRate(r,s) = 99;
MinStorageCharge(r,s,y) = 0;
OperationalLifeStorage(r,s) = 1;
CapitalCostStorage(r,s,y) = 0;
ResidualStorageCapacity(r,s,y) = 0;
$endif.storage