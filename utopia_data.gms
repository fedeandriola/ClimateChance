* UTOPIA_DATA.GMS - specify Utopia Model data in format required by GAMS
*
* OSEMOSYS 2011.07.07 conversion to GAMS by Ken Noble.Noble-Soft Systems - August 2012
* OSEMOSYS 2016.08.01 update by Thorsten Burandt, Konstantin L�ffler and Karlo Hainsch, TU Berlin (Workgroup for Infrastructure Policy) - October 2017
* OSEMOSYS 2020.04.13 reformatting by Giacomo Marangoni
* OSEMOSYS 2020.04.15 change yearsplit by Giacomo Marangoni

* OSEMOSYS 2016.08.01
* Open Source energy Modeling SYStem
*
*#      Based on UTOPIA version 5: BASE - Utopia Base Model
*#      Energy and demands in PJ/a
*#      Power plants in GW
*#      Investment and Fixed O&M Costs: Power plant: Million $ / GW (//$/kW)
*#      Investment  and Fixed O&M Costs Costs: Other plant costs: Million $/PJ/a
*#      Variable O&M (& Import) Costs: Million $ / PJ (//$/GJ)
*#
*#****************************************


*------------------------------------------------------------------------	
* Sets       
*------------------------------------------------------------------------

set     YEAR    / 2020*2100 /;
set     TECHNOLOGY      /
        coal_market 'coal market'
        gas_market 'gas market'
       # waste_market 'waste'   avendo aggregato le biomaase mi sembra ridondante 
        biomass_market 'biomass'
        oil_market 'oil market'
        rainfall 'rainfall'
        oil_refinery 'refineries' # perchè abbiamo tenuto le oil refineries? abbiamo il prezzo del petrolio, ci servono davvero?
        coal_pp'coal'
        #coal_usc_pp 'coal usc' aggregato in coal PP
        ccgt_pp 'combined cycle gas turbine'
       # wte_pp 'waste to energy'
        bio_pp 'bio energy'
        oil_pp 'oil power plant' #considerati qui dentro anche gli altri conmbustibili simili
        geothermal_pp 'geothermal'
        wind_pp 'wind'
        pv 'solar panels'
        hydro_ror_pp 'hydro run of river'
        hydro_dam_pp 'hydro dam'
        psh_pp 'pumped hydro and storage'
        electricity_demand 'electricity demand'
/;

set     TIMESLICE       /
        FD 'Fall - day'
        FN 'Fall - night'
        SPD 'Spring - dat '
        SPN 'Spring - night'
        SD 'Summer - day'
        SN 'Summer - night'
        WD 'Winter - day'
        WN 'Winter - night'
/;

set     FUEL    /
        coal'Coal'
        gas'Gas'
        waste 'Waste'
        biomass'Biomass'
        oil_crude 'Oil Crude'
        oil_ref 'oil refined'
        water 'water from rainfall'
        sun 'sun'
        wind 'wind'
        geo_heat 'geothermal heat'
        electricity 'electricity'
        
        
/;

set     EMISSION        / co2 /;
set     MODE_OF_OPERATION       / 1, 2 /;
set     REGION  / ITALY /;
set     SEASON / 1, 2, 3, 4 /;
set     DAYTYPE / 1 /;
set     DAILYTIMEBRACKET / 1, 2 /;
set     STORAGE / dam /; 

# characterize technologies 
set markets(TECHNOLOGY) / coal_market, gas_market, biomass_market, oil_market /;
set power_plants(TECHNOLOGY) / coal_pp, ccgt_pp, bio_pp, oil_pp, geothermal_pp, wind, pv, hydro_ror_pp, hydro_dam_pp, phs_pp/;
set storage_plants(TECHNOLOGY) / hydro_dam_pp /;
set fuel_transformation(TECHNOLOGY) / oil_refinery /;
set appliances(TECHNOLOGY) /electricity_demand /;
#set unmet_demand(TECHNOLOGY) / /;
#set transport(TECHNOLOGY) / TXD, TXE, TXG /;
set primary_sources(TECHNOLOGY) / coal_market, gas_market, waste_market, biomass_market, oil_market, rainfall /;
#set secondary_imports(TECHNOLOGY) / IMPDSL1, IMPGSL1 /;

set renewable_tech(TECHNOLOGY) / geothermal_pp, wind_pp, pv, hydro_ror_pp/; 
set renewable_fuel(FUEL) /water, sun, wind, geo_heat/; 

#set fuel_production(TECHNOLOGY);
#set fuel_production_fict(TECHNOLOGY) /RIV/;
#set secondary_production(TECHNOLOGY) /COAL, NUCLEAR, HYDRO, STOR_HYDRO, DIESEL_GEN, SRE/;

#Characterize fuels 
set primary_fuel(FUEL) / coal, gas, waste, biomass, oil_crude /;
set secondary_carrier(FUEL) / oil_ref /;
set final_demand(FUEL) / electricity/;

*$include "Model/osemosys_init.gms"

*------------------------------------------------------------------------	
* Parameters - Global
*------------------------------------------------------------------------


parameter YearSplit(l,y) / #quattro stagioni
  FD.(2020*2100)  .1667
  FN.(2020*2100)  .0833
*3mesi
  SPD.(2020*2100)  .1667
  SPN.(2020*2100)  .0833
*3mesi
#  ID.(2020*2100)  .3333   
#  IN.(2020*2100)  .1667
#*6mesi
  SD.(2020*2100)  .1667
  SN.(2020*2100)  .0833
*3mesi
  WD.(2020*2100)  .1667
  WN.(2020*2100)  .0833
*3mesi
/;

DiscountRate(r) = 0.05;

DaySplit(y,lh) = 12/(24*365); #ma la notte non la stiamo considerando da otto ore?


parameter Conversionls(l,ls) / #ogni periodo corrisponde a una stagione e le stiamo ordinando in winter, spring, summer, fall
SPD.2 1
SPN.2 1
FD.4 1
FN.4 1
SD.3 1
SN.3 1
WD.1 1
WN.1 1
/;

parameter Conversionld(l,ld) / #ogni giorno (per stagione) corrisponde al daytype (per ogni stagione)
SPD.1 1
SPN.1 1
FD.1 1
FN.1 1
SD.1 1
SN.1 1
WD.1 1
WN.1 1;

parameter Conversionlh(l,lh) / #prima giorno e poi notte in ogni giornata
SPD.1 1
SPN.2 1
FD.1 1
FN.2 1
SD.1 1
SN.2 1
WD.1 1
WN.2 1
/;

DaysInDayType(y,ls,ld) = 7; #sette giorni in una settimana

TradeRoute(r,rr,f,y) = 0;

DepreciationMethod(r) = 1;


*------------------------------------------------------------------------	
* Parameters - Demands       
*------------------------------------------------------------------------

parameter SpecifiedAnnualDemand(r,f,y) #/ #domanda elettrica per ogni anno [PJ]

  SpecifiedAnnualDemand("utopia","electricity","2020") = 1135.44;
  loop(y.val<=2050, SpecifiedAnnualDemand("utopia","electricity",y)=SpecifiedAnnualDemand("utopia","electricity","2020")*(1+.01*(y.val-2020)) ;);
  loop(y.val>=2050, SpecifiedAnnualDemand("utopia","electricity",y)=1457.74 ;);

  display SpecifiedAnnualDemand;

*   UTOPIA.electricity.2020	1135.44
*   UTOPIA.electricity.2021	1146.18
*   UTOPIA.electricity.2022	1156.92
*   UTOPIA.electricity.2023	1167.66
*   UTOPIA.electricity.2024	1178.4
*   UTOPIA.electricity.2025	1189.14
*   UTOPIA.electricity.2026	1199.88
*   UTOPIA.electricity.2027	1210.62
*   UTOPIA.electricity.2028	1221.36
*   UTOPIA.electricity.2029	1232.1
*   UTOPIA.electricity.2030	1242.84
*   UTOPIA.electricity.2031	1253.58
*   UTOPIA.electricity.2032	1264.32
*   UTOPIA.electricity.2033	1275.06
*   UTOPIA.electricity.2034	1285.8
*   UTOPIA.electricity.2035	1296.54
*   UTOPIA.electricity.2036	1307.28
*   UTOPIA.electricity.2037	1318.02
*   UTOPIA.electricity.2038	1328.76
*   UTOPIA.electricity.2039	1339.5
*   UTOPIA.electricity.2040	1350.24
*   UTOPIA.electricity.2041	1360.98
*   UTOPIA.electricity.2042	1371.72
*   UTOPIA.electricity.2043	1382.46
*   UTOPIA.electricity.2044	1393.2
*   UTOPIA.electricity.2045	1403.94
*   UTOPIA.electricity.2046	1414.68
*   UTOPIA.electricity.2047	1425.42
*   UTOPIA.electricity.2048	1436.16
*   UTOPIA.electricity.2049	1446.9
*   UTOPIA.electricity.2050	1457.64
*   UTOPIA.electricity.2051	1457.64
*   UTOPIA.electricity.2052	1457.64
*   UTOPIA.electricity.2053	1457.64
*   UTOPIA.electricity.2054	1457.64
*   UTOPIA.electricity.2055	1457.64
*   UTOPIA.electricity.2056	1457.64
*   UTOPIA.electricity.2057	1457.64
*   UTOPIA.electricity.2058	1457.64
*   UTOPIA.electricity.2059	1457.64
*   UTOPIA.electricity.2060	1457.64
*   UTOPIA.electricity.2061	1457.64
*   UTOPIA.electricity.2062	1457.64
*   UTOPIA.electricity.2063	1457.64
*   UTOPIA.electricity.2064	1457.64
*   UTOPIA.electricity.2065	1457.64
*   UTOPIA.electricity.2066	1457.64
*   UTOPIA.electricity.2067	1457.64
*   UTOPIA.electricity.2068	1457.64
*   UTOPIA.electricity.2069	1457.64
*   UTOPIA.electricity.2070	1457.64
*   UTOPIA.electricity.2071	1457.64
*   UTOPIA.electricity.2072	1457.64
*   UTOPIA.electricity.2073	1457.64
*   UTOPIA.electricity.2074	1457.64
*   UTOPIA.electricity.2075	1457.64
*   UTOPIA.electricity.2076	1457.64
*   UTOPIA.electricity.2077	1457.64
*   UTOPIA.electricity.2078	1457.64
*   UTOPIA.electricity.2079	1457.64
*   UTOPIA.electricity.2080	1457.64
*   UTOPIA.electricity.2081	1457.64
*   UTOPIA.electricity.2082	1457.64
*   UTOPIA.electricity.2083	1457.64
*   UTOPIA.electricity.2084	1457.64
*   UTOPIA.electricity.2085	1457.64
*   UTOPIA.electricity.2086	1457.64
*   UTOPIA.electricity.2087	1457.64
*   UTOPIA.electricity.2088	1457.64
*   UTOPIA.electricity.2089	1457.64
*   UTOPIA.electricity.2090	1457.64
*   UTOPIA.electricity.2091	1457.64
*   UTOPIA.electricity.2092	1457.64
*   UTOPIA.electricity.2093	1457.64
*   UTOPIA.electricity.2094	1457.64
*   UTOPIA.electricity.2095	1457.64
*   UTOPIA.electricity.2096	1457.64
*   UTOPIA.electricity.2097	1457.64
*   UTOPIA.electricity.2098	1457.64
*   UTOPIA.electricity.2099	1457.64
*   UTOPIA.electricity.2100	1457.64


* /;


parameter SpecifiedDemandProfile(r,f,l,y) / #distribuzione della domanda per ogni timeslice
  UTOPIA.electricity.WD.(2020*2100)  .14
  UTOPIA.electricity.WN.(2020*2100)  .08
  UTOPIA.electricity.SPD.(2020*2100)  .19
  UTOPIA.electricity.SPN.(2020*2100)  .07
  UTOPIA.electricity.SD.(2020*2100)  .17
  UTOPIA.electricity.SN.(2020*2100)  .09
  UTOPIA.electricity.FD.(2020*2100)  .16
  UTOPIA.electricity.FN.(2020*2100)  .07
/;

parameter AccumulatedAnnualDemand(r,f,y) /  #se definiamo specified annual demand non va definita
 /;

*------------------------------------------------------------------------	
* Parameters - Performance       
*------------------------------------------------------------------------

CapacityToActivityUnit(r,t)$power_plants(t) = 31.536; #PJ/GW/y

CapacityToActivityUnit(r,t)$(CapacityToActivityUnit(r,t) = 0) = 1;

* -((0,016875 *(y.val -2020))*0,75* 0,003)) riduzione percentuale di impianti termici al variare della temperatura dei fiumi
* -((0,036875 *(y.val -2020))*0,75* 0,003))

CapacityFactor(r,'coal_pp',l,y) = 0.85;
CapacityFactor(r,'ccgt_pp',l,y) = 0.85;
CapacityFactor(r,'oil_pp',l,y) = 0.85;
CapacityFactor(r,'geothermal_pp',l,y) = 0.84; 
CapacityFactor(r,'bio_pp',l,y) = 0.68;

CapacityFactor(r,'wind_pp',WD,y) = 0.39;
CapacityFactor(r,'wind_pp',WN,y) =0.39;
CapacityFactor(r,'wind_pp',SPD,y) =0.39;
CapacityFactor(r,'wind_pp',SPN,y) =0.39;
CapacityFactor(r,'wind_pp',SD,y) =0.39;
CapacityFactor(r,'wind_pp',SN,y) =0.39;
CapacityFactor(r,'wind_pp',FD,y) =0.39;
CapacityFactor(r,'wind_pp',FN,y) =0.39;

CapacityFactor(r,'pv',WD,y) = 0.32;
CapacityFactor(r,'pv',WN,y) =0.32;
CapacityFactor(r,'pv',SPD,y) =0.32;
CapacityFactor(r,'pv',SPN,y) =0.32;
CapacityFactor(r,'pv',SD,y) =0.32;
CapacityFactor(r,'pv',SN,y) =0.32;
CapacityFactor(r,'pv',FD,y) =0.32;
CapacityFactor(r,'pv',FN,y) =0.32;

loop(y.val<=2100,CapacityFactor(r,'hydro_dam_pp',WD,y) = (0,0004*(y.val-2006)+0,2411));
loop(y.val<=2100,CapacityFactor(r,'hydro_dam_pp',WN,y) = (0,0004*(y.val-2006)+0,2411));
loop(y.val<=2100,CapacityFactor(r,'hydro_dam_pp',SPD,y) = (-0,0006*(y.val-2006)+0,3739));
loop(y.val<=2100,CapacityFactor(r,'hydro_dam_pp',SPN,y) = (-0,0006*(y.val-2006)+0,3739));
loop(y.val<=2100,CapacityFactor(r,'hydro_dam_pp',SD,y) = (-0,000005*(y.val-2006)+0,2012));
loop(y.val<=2100,CapacityFactor(r,'hydro_dam_pp',SN,y) = (-0,000005*(y.val-2006)+0,2012));
loop(y.val<=2100,CapacityFactor(r,'hydro_dam_pp',FD,y) = (0,0009*(y.val-2006)+0,3411));
loop(y.val<=2100,CapacityFactor(r,'hydro_dam_pp',FN,y) = (0,0009*(y.val-2006)+0,3411));

loop(y.val<=2100,CapacityFactor(r,'hydro_ror_pp',WD,y) = (0,0006*(y.val-2006)+0,4251));
loop(y.val<=2100,CapacityFactor(r,'hydro_ror_pp',WN,y) = (0,0006*(y.val-2006)+0,4251));
loop(y.val<=2100,CapacityFactor(r,'hydro_ror_pp',SPD,y) = (-0,0007*(y.val-2006)+0,7069));
loop(y.val<=2100,CapacityFactor(r,'hydro_ror_pp',SPN,y) = (-0,0007*(y.val-2006)+0,7069));
loop(y.val<=2100,CapacityFactor(r,'hydro_ror_pp',SD,y) = (-0,0006*(y.val-2006)+0,423));
loop(y.val<=2100,CapacityFactor(r,'hydro_ror_pp',SN,y) = (-0,0006*(y.val-2006)+0,423));
loop(y.val<=2100,CapacityFactor(r,'hydro_ror_pp',FD,y) = (0,0011*(y.val-2006)+0,5324));
loop(y.val<=2100,CapacityFactor(r,'hydro_ror_pp',FN,y) = (0,0011*(y.val-2006)+0,5324));

CapacityFactor(r,t,l,y)$(CapacityFactor(r,t,l,y) = 0) = 1; 

AvailabilityFactor(r,t,y) = 1;

parameter OperationalLife(r,t) /
  UTOPIA.coal_pp 35
  UTOPIA.ccgt_pp 20
  UTOPIA.oil_pp 35
  UTOPIA.geothermal_pp 50
  UTOPIA.wind_pp 20
  UTOPIA.pv 20
  UTOPIA.bio_pp 20
  UTOPIA.hydro_dam_pp 80
  UTOPIA.hydro_ror_pp 30
/;
OperationalLife(r,t)$(OperationalLife(r,t) = 0) = 1;

parameter ResidualCapacity(r,t,y)  #/ #qua va scritta una funzione
*     ResidualCapacity("utopia","coal_pp","2020") = 5.658;
*     ResidualCapacity("utopia","coal_pp","2021") = 5.658;
*     ResidualCapacity("utopia","coal_pp","2022") = 5.658;
    loop(y$(y.val < 2022), ResidualCapacity("utopia","coal_pp",y)=5.658;);
    loop(y$(2022 <= y.val and y.val <= 2060), ResidualCapacity("utopia","coal_pp",y)=ResidualCapacity("utopia","coal_pp",y-1)*(1-.12) ;);
    loop(y$(y.val > 2060), ResidualCapacity("utopia","coal_pp",y)=0;); #chiedere se la funzione ha senso


    display ResidualCapacity;


$if set no_initial_capacity ResidualCapacity(r,t,y) = 0; #sono sbagliati perchè queste sono le efficienze, a noi serve l'inverso :)

parameter InputActivityRatio(r,t,f,m,y) / #da completare
  UTOPIA.refineries.oil_crude.1.(2020*2100) 1.02 #da trovare
  UTOPIA.coal_pp.coal.1.(2020*2100) 2.63
  UTOPIA.ccgt_pp.gas.1.(2020*2100) 1.78
  UTOPIA.oil_pp.oil_ref.1.(2020*2100) 2.86
  UTOPIA.geothermal_pp.geo_heat.1.(2020*2100) 1 #IEA assumption for renewables
  UTOPIA.wind_pp.wind.1.(2020*2100) 1
  UTOPIA.pv.sun.1.(2020*2100) 1
  UTOPIA.bio_pp.biomass.1.(2020*2100) 3.23
  UTOPIA.hydro_ror_pp.water.1.(2020*2100) 1
  UTOPIA.hydro_dam_pp.water.1.(2020*2100) 1
  UTOPIA.hydro_psh_pp.water.1.(2020*2100) 1.15 #turbine mode
  UTOPIA.hydro_psh_pp.electricity.2.(2020*2100) 1.15 #pumping mode
  /;

parameter OutputActivityRatio(r,t,f,m,y) /
  UTOPIA.coal_market.coal.1.(2020*2100) 1
  UTOPIA.gas_market.gas.1.(2020*2100) 1
  UTOPIA.oil_market.oil_crude.1.(2020*2100) 1
  UTOPIA.biomass_market.biomass.1.(2020*2100) 1
  UTOPIA.rainfall.water.1.(2020*2100) 1
  UTOPIA.refineries.oil_ref.1.(2020*2100) 1 
  UTOPIA.coal_pp.electricity.1.(2020*2100) 1
  UTOPIA.ccgt_pp.electricity.1.(2020*2100) 1
  UTOPIA.oil_pp.electricity.1.(2020*2100) 1
  UTOPIA.geothermal_pp.electricity.1.(2020*2100) 1
  UTOPIA.wind_pp.electricity.1.(2020*2100) 1
  UTOPIA.pv.electricity.1.(2020*2100) 1
  UTOPIA.bio_pp.electricity.1.(2020*2100) 1
  UTOPIA.hydro_ror_pp.electricity.1.(2020*2100) 1
  UTOPIA.hydro_dam_pp.electricity.1.(2020*2100) 1
  UTOPIA.hydro_psh_pp.electricity.1.(2020*2100) 1 #turbine mode
  UTOPIA.hydro_psh_pp.water.2.(2020*2100) 1 #pumping mode
/;



# By default, assume for imported secondary fuels the same efficiency of the internal refineries
* InputActivityRatio(r,'IMPDSL1','OIL',m,y)$(not OutputActivityRatio(r,'SRE','DSL',m,y) eq 0) = 1/OutputActivityRatio(r,'SRE','DSL',m,y); 
* InputActivityRatio(r,'IMPGSL1','OIL',m,y)$(not OutputActivityRatio(r,'SRE','GSL',m,y) eq 0) = 1/OutputActivityRatio(r,'SRE','GSL',m,y); 

*------------------------------------------------------------------------	
* Parameters - Technology costs       
*------------------------------------------------------------------------

parameter CapitalCost / #[M€/GW]aa
  UTOPIA.coal_market.(2020*2100) 0
  UTOPIA.gas_market.(2020*2100) 0
  UTOPIA.oil_market.(2020*2100) 0
  UTOPIA.biomass_market.(2020*2100) 0
  UTOPIA.rainfall.(2020*2100) 0
  UTOPIA.refineries.(2020*2100) 0 #it is not binding, so it can install as much as it wants
  UTOPIA.coal_pp.(2020*2100) 2000
  UTOPIA.ccgt_pp.(2020*2100) 900
  UTOPIA.oil_pp.(2020*2100) 1800
  UTOPIA.geothermal_pp.(2020*2100) 3500
  UTOPIA.wind_pp.(2020*2100) 1350
  UTOPIA.pv.(2020*2100) 1200
  UTOPIA.bio_pp.(2020*2100) 3500
  UTOPIA.hydro_ror_pp.(2020*2100) 2300
  UTOPIA.hydro_dam_pp.(2020*2100) 1900
  UTOPIA.hydro_psh_pp.(2020*2100) 1900 

/;

parameter VariableCost(r,t,m,y) /
  UTOPIA.COAL.1.(1990*2010)  .3
  UTOPIA.NUCLEAR.1.(1990*2010)  1.5
  UTOPIA.DIESEL_GEN.1.(1990*2010)  .4
  UTOPIA.IMPDSL1.1.(1990*2010)  10
  UTOPIA.IMPGSL1.1.(1990*2010)  15
  UTOPIA.IMPHCO1.1.(1990*2010)  2
  UTOPIA.IMPOIL1.1.(1990*2010)  8
  UTOPIA.IMPURN1.1.(1990*2010)  2
  UTOPIA.SRE.1.(1990*2010)  10
/;
 VariableCost(r,t,m,y)$(VariableCost(r,t,m,y) = 0) = 1e-5;

parameter FixedCost /
  UTOPIA.COAL.(1990*2010)  40
  UTOPIA.NUCLEAR.(1990*2010)  500
  UTOPIA.HYDRO.(1990*2010)  75
  UTOPIA.STOR_HYDRO.(1990*2010)  30
  UTOPIA.DIESEL_GEN.(1990*2010)  30
  UTOPIA.RHO.(1990*2010)  1
  UTOPIA.RL1.(1990*2010)  9.46
  UTOPIA.TXD.(1990*2010)  52
  UTOPIA.TXE.(1990*2010)  100
  UTOPIA.TXG.(1990*2010)  48
/;


*------------------------------------------------------------------------	
* Parameters - Storage       
*------------------------------------------------------------------------

parameter TechnologyToStorage(r,m,t,s) /
  UTOPIA.1.rainfall.dam 1
  UTOPIA.2.hydro_psh_pp.dam 1
/;

parameter TechnologyFromStorage(r,m,t,s) /
  UTOPIA.1.hydro_dam_pp.dam  1
  UTOPIA.1.hydro_psh_pp.dam  1
/;

StorageLevelStart(r,s) = 999;

StorageMaxChargeRate(r,s) = 99;

StorageMaxDischargeRate(r,s) = 99;

MinStorageCharge(r,s,y) = 0;

OperationalLifeStorage(r,s) = 99;

CapitalCostStorage(r,s,y) = 0;

ResidualStorageCapacity(r,s,y) = 999;



*------------------------------------------------------------------------	
* Parameters - Capacity and investment constraints       
*------------------------------------------------------------------------

CapacityOfOneTechnologyUnit(r,t,y) = ;

parameter TotalAnnualMaxCapacity(r,t,y) /
  UTOPIA.hydro_dam_pp.(2020*2100) 12.5 #assuming 85% of the potential already exploited
  UTOPIA.hydro_psh_pp.(2020*2100) 9.11 #assuming 85% of the potential already exploited
  UTOPIA.hydro_ror_pp.(2020*2100) 9 #assuming 75% of the potential already exploited
/;
TotalAnnualMaxCapacity(r,t,y)$(TotalAnnualMaxCapacity(r,t,y) = 0) = 99999;


parameter TotalAnnualMinCapacity(r,t,y) /
/;

TotalAnnualMaxCapacityInvestment(r,t,y) = 99999999;

TotalAnnualMinCapacityInvestment(r,t,y) = 0;


*------------------------------------------------------------------------	
* Parameters - Activity constraints       
*------------------------------------------------------------------------

TotalTechnologyAnnualActivityUpperLimit(r,t,y) = 99999;

TotalTechnologyAnnualActivityLowerLimit(r,t,y) = 0;

TotalTechnologyModelPeriodActivityUpperLimit(r,t) = 99999;

TotalTechnologyModelPeriodActivityLowerLimit(r,t) = 0;


*------------------------------------------------------------------------	
* Parameters - Reserve margin
*-----------------------------------------------------------------------

parameter ReserveMarginTagTechnology(r,t,y) /
  UTOPIA.COAL.(2020*2100)  1
  UTOPIA.NUCLEAR.(2020*2100)  1
  UTOPIA.HYDRO.(2020*2100)  1
  UTOPIA.STOR_HYDRO.(2020*2100)  1
  UTOPIA.DIESEL_GEN.(2020*2100)  1
/;

parameter ReserveMarginTagFuel(r,f,y) /
  UTOPIA.ELC.(2020*2100)  1
/;

parameter ReserveMargin(r,y) /
  UTOPIA.(2020*2100)  1.18
/;


*------------------------------------------------------------------------	
* Parameters - RE Generation Target       
*------------------------------------------------------------------------

RETagTechnology(r,t,y) = 0;

RETagFuel(r,f,y) = 0;

REMinProductionTarget(r,y) = 0;


*------------------------------------------------------------------------	
* Parameters - Emissions       
*------------------------------------------------------------------------

parameter EmissionActivityRatio(r,t,e,m,y) /
  UTOPIA.IMPDSL1.CO2.1.(2020*2100)  .075
  UTOPIA.IMPGSL1.CO2.1.(2020*2100)  .075
  UTOPIA.IMPHCO1.CO2.1.(2020*2100)  .089
  UTOPIA.IMPOIL1.CO2.1.(2020*2100)  .075
  UTOPIA.TXD.NOX.1.(2020*2100)  1
  UTOPIA.TXG.NOX.1.(2020*2100)  1
/;

EmissionsPenalty(r,e,y) = 0;

AnnualExogenousEmission(r,e,y) = 0;

AnnualEmissionLimit(r,e,y) = 9999;

ModelPeriodExogenousEmission(r,e) = 0;

ModelPeriodEmissionLimit(r,e) = 9999;