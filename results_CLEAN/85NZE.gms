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

set     YEAR    / 2020*2060 /;
set     TECHNOLOGY      /
        coal_market 'coal market'
        gas_market 'gas market'
        biomass_market 'biomass'
        oil_market 'oil market'
        sun_market 'sun market'
        wind_market 'wind market'
        uranium_market 'uranium market'
        rainfall 'rainfall'
        oil_refinery 'refineries' 
        coal_pp 'coal'
        ccgt_pp 'combined cycle gas turbine'
        bio_pp 'bio energy'
        oil_pp 'oil power plant' 
        geothermal_pp 'geothermal'
        windON_pp 'wind'
        windOFF_pp 'windOFF'
        pv_pp 'solar panels'
        hydro_ror_pp 'hydro run of river'
        hydro_dam_pp 'hydro dam'
        psh_pp 'pumped hydro and storage'
        nuclear_pp "nuclear SMR"
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
        coal 'Coal'
        gas 'Gas'
        biomass 'Biomass'
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
set     REGION  / UTOPIA /;
set     SEASON / 1, 2, 3, 4 /;
set     DAYTYPE / 1 /;
set     DAILYTIMEBRACKET / 1, 2 /;
set     STORAGE / dam /; 

# characterize technologies 
set markets(TECHNOLOGY) / coal_market, gas_market, biomass_market, oil_market, sun_market, wind_market, uranium_market /;
set power_plants(TECHNOLOGY) / coal_pp, ccgt_pp, bio_pp, oil_pp, geothermal_pp, windON_pp,windOFF_pp, pv_pp, hydro_ror_pp, hydro_dam_pp, psh_pp, nuclear_pp /;
set storage_plants(TECHNOLOGY) / hydro_dam_pp /;
set fuel_transformation(TECHNOLOGY) / oil_refinery /;
set appliances(TECHNOLOGY) /electricity_demand /;
set primary_sources(TECHNOLOGY) / coal_market, gas_market, biomass_market, oil_market, rainfall, sun_market, wind_market, uranium_market /;


set renewable_tech(TECHNOLOGY) / geothermal_pp, windON_pp, pv_pp, hydro_ror_pp/; 
set renewable_fuel(FUEL) /water, sun, wind, geo_heat/; 


#Characterize fuels 
set primary_fuel(FUEL) / coal, gas, waste, biomass, oil_crude /;
set secondary_carrier(FUEL) / oil_ref /;
set final_demand(FUEL) / electricity/;

*$include "Model/osemosys_init.gms"

*------------------------------------------------------------------------   
* Parameters - Global
*------------------------------------------------------------------------

 #quattro stagioni
parameter YearSplit(l,y) /
  FD.(2020*2060)  .1667
  FN.(2020*2060)  .0833
*3mesi
  SPD.(2020*2060)  .1667
  SPN.(2020*2060)  .0833
*3mesi
  SD.(2020*2060)  .1667
  SN.(2020*2060)  .0833
*3mesi
  WD.(2020*2060)  .1667
  WN.(2020*2060)  .0833
*3mesi
/;

DiscountRate(r) = 0.05;

DaySplit(y,lh) = 12/(24*365); 

#ogni periodo corrisponde a una stagione e le stiamo ordinando in winter, spring, summer, fall
parameter Conversionls(l,ls)  / 
SPD.2 1
SPN.2 1
FD.4 1
FN.4 1
SD.3 1
SN.3 1
WD.1 1
WN.1 1
/;
#ogni giorno (per stagione) corrisponde al daytype (per ogni stagione)
parameter Conversionld(l,ld) / 
SPD.1 1
SPN.1 1
FD.1 1
FN.1 1
SD.1 1
SN.1 1
WD.1 1
WN.1 1
/;
#prima giorno e poi notte in ogni giornata
parameter Conversionlh(l,lh) / 
SPD.1 1
SPN.2 1
FD.1 1
FN.2 1
SD.1 1
SN.2 1
WD.1 1
WN.2 1 
/;

DaysInDayType(y,ls,ld) = 7; 

TradeRoute(r,rr,f,y) = 0;

DepreciationMethod(r) = 1;


*------------------------------------------------------------------------   
* Parameters - Demands       
*------------------------------------------------------------------------

parameter SpecifiedAnnualDemand(r,f,y); 

  SpecifiedAnnualDemand(r,"electricity","2020") = 1135.44;
  loop(y $(y.val <= 2050), SpecifiedAnnualDemand(r,"electricity",y)=SpecifiedAnnualDemand(r,"electricity","2020")*(1+.01*(y.val-2020)) ;);
  loop(y $(y.val > 2050), SpecifiedAnnualDemand(r,"electricity",y)=1457.74 ;);

  display SpecifiedAnnualDemand;


parameter SpecifiedDemandProfile(r,f,l,y) / 
  UTOPIA.electricity.WD.(2020*2060)  .14
  UTOPIA.electricity.WN.(2020*2060)  .09
  UTOPIA.electricity.SPD.(2020*2060)  .19
  UTOPIA.electricity.SPN.(2020*2060)  .075
  UTOPIA.electricity.SD.(2020*2060)  .17
  UTOPIA.electricity.SN.(2020*2060)  .1
  UTOPIA.electricity.FD.(2020*2060)  .16
  UTOPIA.electricity.FN.(2020*2060)  .075
/;




parameter AccumulatedAnnualDemand(r,f,y) /  
 /;

*------------------------------------------------------------------------   
* Parameters - Performance       
*------------------------------------------------------------------------

CapacityToActivityUnit(r,t)$power_plants(t) = 31.536; #PJ/GW/y

CapacityToActivityUnit(r,t)$(CapacityToActivityUnit(r,t) = 0) = 1;

* RSP 4.5        -((0.016875 *(y.val -2020))*0.75* 0.003)) riduzione percentuale di impianti termici al variare della temperatura dei fiumi
* RSP 8.5        -((0.036875 *(y.val -2020))*0.75* 0.003)) riduzione percentuale di impianti termici al variare della temperatura dei fiumi
* DA AGGIUNGERE AI CAPACITY FACTOR FOSSILI

CapacityFactor(r,'coal_pp',l,y) = 0.85;
CapacityFactor(r,'ccgt_pp',l,y) = 0.85;
CapacityFactor(r,'oil_pp',l,y) = 0.85;
CapacityFactor(r,'geothermal_pp',l,y) = 0.84; 
CapacityFactor(r,'bio_pp',l,y) = 0.68;
CapacityFactor(r,'nuclear_pp',l,y) = 0.95;

CapacityFactor(r,'windON_pp','WD',y) = 0.3;
CapacityFactor(r,'windON_pp','WN',y) =0.4;
CapacityFactor(r,'windON_pp','SPD',y) =0.2;
CapacityFactor(r,'windON_pp','SPN',y) =0.3;
CapacityFactor(r,'windON_pp','SD',y) =0.1;
CapacityFactor(r,'windON_pp','SN',y) =0.15;
CapacityFactor(r,'windON_pp','FD',y) =0.2;
CapacityFactor(r,'windON_pp','FN',y) =0.3;

CapacityFactor(r,'windOFF_pp','WD',y) = 0.4;
CapacityFactor(r,'windOFF_pp','WN',y) =0.5;
CapacityFactor(r,'windOFF_pp','SPD',y) =0.3;
CapacityFactor(r,'windOFF_pp','SPN',y) =0.4;
CapacityFactor(r,'windOFF_pp','SD',y) =0.2;
CapacityFactor(r,'windOFF_pp','SN',y) =0.25;
CapacityFactor(r,'windOFF_pp','FD',y) =0.3;
CapacityFactor(r,'windOFF_pp','FN',y) =0.4;

CapacityFactor(r,'pv_pp','WD',y) = 0.1;
CapacityFactor(r,'pv_pp','WN',y) =0;
CapacityFactor(r,'pv_pp','SPD',y) =0.4;
CapacityFactor(r,'pv_pp','SPN',y) =0;
CapacityFactor(r,'pv_pp','SD',y) =0.8;
CapacityFactor(r,'pv_pp','SN',y) =0;
CapacityFactor(r,'pv_pp','FD',y) =0.4;
CapacityFactor(r,'pv_pp','FN',y) =0;

loop(y,CapacityFactor(r,'hydro_dam_pp','WD',y) = (0.0011*(y.val-2006)+0.2239));
loop(y,CapacityFactor(r,'hydro_dam_pp','WN',y) = (0.0011*(y.val-2006)+0.2239));
loop(y,CapacityFactor(r,'hydro_dam_pp','SPD',y) = (-0.0016*(y.val-2006)+0.4112));
loop(y,CapacityFactor(r,'hydro_dam_pp','SPN',y) = (-0.0016*(y.val-2006)+0.4112));
loop(y,CapacityFactor(r,'hydro_dam_pp','SD',y) = (-0.0008*(y.val-2006)+0.2247));
loop(y,CapacityFactor(r,'hydro_dam_pp','SN',y) = (-0.0008*(y.val-2006)+0.2247));
loop(y,CapacityFactor(r,'hydro_dam_pp','FD',y) = (0.0011*(y.val-2006)+0.3684));
loop(y,CapacityFactor(r,'hydro_dam_pp','FN',y) = (0.0011*(y.val-2006)+0.3684));

loop(y,CapacityFactor(r,'psh_pp','WD',y) = (0.0011*(y.val-2006)+0.2239));
loop(y,CapacityFactor(r,'psh_pp','WN',y) = (0.0011*(y.val-2006)+0.2239));
loop(y,CapacityFactor(r,'psh_pp','SPD',y) = (-0.0016*(y.val-2006)+0.4112));
loop(y,CapacityFactor(r,'psh_pp','SPN',y) = (-0.0016*(y.val-2006)+0.4112));
loop(y,CapacityFactor(r,'psh_pp','SD',y) = (-0.0008*(y.val-2006)+0.2247));
loop(y,CapacityFactor(r,'psh_pp','SN',y) = (-0.0008*(y.val-2006)+0.2247));
loop(y,CapacityFactor(r,'psh_pp','FD',y) = (0.0011*(y.val-2006)+0.3684));
loop(y,CapacityFactor(r,'psh_pp','FN',y) = (0.0011*(y.val-2006)+0.3684));

loop(y,CapacityFactor(r,'hydro_ror_pp','WD',y) = (0.0019*(y.val-2006)+0.3894));
loop(y,CapacityFactor(r,'hydro_ror_pp','WN',y) = (0.0019*(y.val-2006)+0.3894));
loop(y,CapacityFactor(r,'hydro_ror_pp','SPD',y) = (-0.0026*(y.val-2006)+0.7702));
loop(y,CapacityFactor(r,'hydro_ror_pp','SPN',y) = (-0.0026*(y.val-2006)+0.7702));
loop(y,CapacityFactor(r,'hydro_ror_pp','SD',y) = (-0.0016*(y.val-2006)+0.4531));
loop(y,CapacityFactor(r,'hydro_ror_pp','SN',y) = (-0.0016*(y.val-2006)+0.4531));
loop(y,CapacityFactor(r,'hydro_ror_pp','FD',y) = (0.001*(y.val-2006)+0.5528));
loop(y,CapacityFactor(r,'hydro_ror_pp','FN',y) = (0.001*(y.val-2006)+0.5528));

CapacityFactor(r,t,l,y)$(CapacityFactor(r,t,l,y) = 0) = 1; 

AvailabilityFactor(r,t,y) = 1;

parameter OperationalLife(r,t) /
  UTOPIA.coal_pp 35
  UTOPIA.ccgt_pp 20
  UTOPIA.oil_pp 35
  UTOPIA.geothermal_pp 50
  UTOPIA.windON_pp 20
  UTOPIA.windOFF_pp 30
  UTOPIA.pv_pp 20
  UTOPIA.bio_pp 20
  UTOPIA.hydro_dam_pp 80
  UTOPIA.hydro_ror_pp 30
  UTOPIA.nuclear_pp 60
/;

OperationalLife(r,t)$(OperationalLife(r,t) = 0) = 1;

parameter ResidualCapacity(r,t,y) 
    loop(y$(y.val < 2022), 
    ResidualCapacity("utopia","coal_pp",y)=5.658;
    ResidualCapacity("utopia","ccgt_pp",y)=43.991;
    ResidualCapacity("utopia","windON_pp",y)=11.9;
    ResidualCapacity("utopia","pv_pp",y)=25.064;
    ResidualCapacity("utopia","hydro_dam_pp",y)=10.502;
    ResidualCapacity("utopia","hydro_ror_pp",y)=6.661;
    ResidualCapacity("utopia","psh_pp",y)=7.741;
    ResidualCapacity("utopia","geothermal_pp",y)=0.817;
    ResidualCapacity("utopia","bio_pp",y)=7.233;
    ResidualCapacity("utopia","oil_pp",y)=3.809;
    ResidualCapacity("utopia","nuclear_pp",y)=0;
    );
    loop(y$(2022 <= y.val and y.val <= 2024), ResidualCapacity("utopia","coal_pp",y)=ResidualCapacity("utopia","coal_pp",y-1)*(1-.01) ;);
    loop(y$(y.val > 2023), ResidualCapacity("utopia","coal_pp",y)=ResidualCapacity("utopia","coal_pp",y-1)*(1-.50););
    loop(y$(2022 <= y.val and y.val <= 2035), ResidualCapacity("utopia","ccgt_pp",y)=ResidualCapacity("utopia","ccgt_pp",y-1)*(1-.05) ;);
    loop(y$(y.val > 2035), ResidualCapacity("utopia","ccgt_pp",y)=ResidualCapacity("utopia","ccgt_pp",y-1)*(1-.20););
    loop(y$(2022 <= y.val and y.val <= 2035), ResidualCapacity("utopia","windON_pp",y)=ResidualCapacity("utopia","windON_pp",y-1)*(1-.01) ;);
    loop(y$(y.val > 2035), ResidualCapacity("utopia","windON_pp",y)=ResidualCapacity("utopia","windON_pp",y-1)*(1-.15););
    loop(y$(2022 <= y.val and y.val <= 2030), ResidualCapacity("utopia","pv_pp",y)=ResidualCapacity("utopia","pv_pp",y-1)*(1-.01) ;);
    loop(y$(y.val > 2030), ResidualCapacity("utopia","pv_pp",y)=ResidualCapacity("utopia","pv_pp",y-1)*(1-.15););
    loop(y$(2022 <= y.val and y.val <= 2055), ResidualCapacity("utopia","hydro_dam_pp",y)=ResidualCapacity("utopia","hydro_dam_pp",y-1)*(1-.01) ;);
    loop(y$(y.val > 2055), ResidualCapacity("utopia","hydro_dam_pp",y)=ResidualCapacity("utopia","hydro_dam_pp",y-1)*(1-.15););
    loop(y$(2022 <= y.val and y.val <= 2040), ResidualCapacity("utopia","hydro_ror_pp",y)=ResidualCapacity("utopia","hydro_ror_pp",y-1)*(1-.02) ;);
    loop(y$(y.val > 2040), ResidualCapacity("utopia","hydro_ror_pp",y)=ResidualCapacity("utopia","hydro_ror_pp",y-1)*(1-.15););
    loop(y$(2022 <= y.val and y.val <= 2055), ResidualCapacity("utopia","psh_pp",y)=ResidualCapacity("utopia","psh_pp",y-1)*(1-.01) ;);
    loop(y$(y.val > 2055), ResidualCapacity("utopia","psh_pp",y)=ResidualCapacity("utopia","psh_pp",y-1)*(1-.15););
    loop(y$(2022 <= y.val and y.val <= 2060), ResidualCapacity("utopia","geothermal_pp",y)=ResidualCapacity("utopia","geothermal_pp",y-1)*(1-.05) ;);
    loop(y$(2022 <= y.val and y.val <= 2040), ResidualCapacity("utopia","bio_pp",y)=ResidualCapacity("utopia","bio_pp",y-1)*(1-.05) ;);
    loop(y$(y.val > 2040), ResidualCapacity("utopia","bio_pp",y)=ResidualCapacity("utopia","bio_pp",y-1)*(1-.15););
    loop(y$(2022 <= y.val and y.val <= 2024), ResidualCapacity("utopia","oil_pp",y)=ResidualCapacity("utopia","oil_pp",y-1)*(1-.01) ;);
    loop(y$(y.val > 2024), ResidualCapacity("utopia","oil_pp",y)=ResidualCapacity("utopia","oil_pp",y-1)*(1-.50););
    
    display ResidualCapacity;


$if set no_initial_capacity ResidualCapacity(r,t,y) = 0;

parameter InputActivityRatio(r,t,f,m,y) / 
  UTOPIA.oil_refinery.oil_crude.1.(2020*2060) 1.02 
  UTOPIA.coal_pp.coal.1.(2020*2060) 2.63
  UTOPIA.ccgt_pp.gas.1.(2020*2060) 1.78
  UTOPIA.oil_pp.oil_ref.1.(2020*2060) 2.86
  UTOPIA.geothermal_pp.geo_heat.1.(2020*2060) 1 
  UTOPIA.windON_pp.wind.1.(2020*2060) 1
  UTOPIA.windOFF_pp.wind.1.(2020*2060) 1
  UTOPIA.pv_pp.sun.1.(2020*2060) 1
  UTOPIA.bio_pp.biomass.1.(2020*2060) 3.23
  UTOPIA.hydro_ror_pp.water.1.(2020*2060) 1
  UTOPIA.hydro_dam_pp.water.1.(2020*2060) 1
  UTOPIA.psh_pp.water.1.(2020*2060) 1.15 
  UTOPIA.nuclear_pp.electricity.1.(2020*2060) 1
  UTOPIA.psh_pp.electricity.2.(2020*2060) 1.15 
  /;


parameter OutputActivityRatio(r,t,f,m,y) /
  UTOPIA.coal_market.coal.1.(2020*2060) 1
  UTOPIA.gas_market.gas.1.(2020*2060) 1
  UTOPIA.oil_market.oil_crude.1.(2020*2060) 1
  UTOPIA.biomass_market.biomass.1.(2020*2060) 1
  UTOPIA.rainfall.water.1.(2020*2060) 1
  UTOPIA.sun_market.sun.1.(2020*2060) 1
  UTOPIA.wind_market.wind.1.(2020*2060) 1
  UTOPIA.uranium_market.uranium.1.(2020*2060) 1
  UTOPIA.oil_refinery.oil_ref.1.(2020*2060) 1 
  UTOPIA.coal_pp.electricity.1.(2020*2060) 1
  UTOPIA.ccgt_pp.electricity.1.(2020*2060) 1
  UTOPIA.oil_pp.electricity.1.(2020*2060) 1
  UTOPIA.geothermal_pp.electricity.1.(2020*2060) 1
  UTOPIA.windON_pp.electricity.1.(2020*2060) 1
  UTOPIA.windOFF_pp.electricity.1.(2020*2060) 1
  UTOPIA.pv_pp.electricity.1.(2020*2060) 1
  UTOPIA.bio_pp.electricity.1.(2020*2060) 1
  UTOPIA.hydro_ror_pp.electricity.1.(2020*2060) 1
  UTOPIA.hydro_dam_pp.electricity.1.(2020*2060) 1
  UTOPIA.nuclear_pp.electricity.1.(2020*2060) 1
  UTOPIA.psh_pp.electricity.1.(2020*2060) 1 
  UTOPIA.psh_pp.water.2.(2020*2060) 1 
/;

*------------------------------------------------------------------------   
* Parameters - Technology costs       
*------------------------------------------------------------------------
#[M€/GW]
parameter CapitalCost / 
  UTOPIA.coal_market.(2020*2060) 0
  UTOPIA.gas_market.(2020*2060) 0
  UTOPIA.oil_market.(2020*2060) 0
  UTOPIA.biomass_market.(2020*2060) 0
  UTOPIA.rainfall.(2020*2060) 0
  UTOPIA.sun_market.(2020*2060) 0
  UTOPIA.wind_market.(2020*2060) 0
  UTOPIA.uranium_market.(2020*2060) 0
  UTOPIA.oil_refinery.(2020*2060) 0 
  UTOPIA.coal_pp.(2020*2060) 2000
  UTOPIA.ccgt_pp.(2020*2060) 900
  UTOPIA.oil_pp.(2020*2060) 1800

*UTOPIA.geothermal_pp.2020 3500
*UTOPIA.wind_pp.2020 1350
*UTOPIA.pv_pp.2020 1200
*UTOPIA.bio_pp.2020 3500
*UTOPIA.hydro_ror_pp.2020 2300
*UTOPIA.hydro_dam_pp.2020 1900
*UTOPIA.psh_pp.2020 1900 
 UTOPIA.nuclear_pp.(2020*2060) 4000
/;

loop(y,CapitalCost("UTOPIA","geothermal_pp",y) = 3500* (1-0.003846)**(y.val-2020));
loop(y,CapitalCost("UTOPIA","wind_pp",y) = 1350* (1-0.012996)**(y.val-2020) );
*loop(y,CapitalCOst("UTOPIA","windOFF",y) = 3200 * (1-0.0105)**(y.val-2020));
loop(y,CapitalCost("UTOPIA","pv_pp",y) = 1200* (1-0.03128)**(y.val-2020) );
loop(y,CapitalCost("UTOPIA","bio_pp",y) = 3500* (1-0.003029)**(y.val-2020) );
loop(y,CapitalCost("UTOPIA","hydro_ror_pp",y) = 2300* (1-0.006109)**(y.val-2020) );
loop(y,CapitalCost("UTOPIA","hydro_dam_pp",y) = 1900* (1-0.004287)**(y.val-2020) );
loop(y,CapitalCost("UTOPIA","psh_pp",y) = 1900* (1-0.004287)**(y.val-2020) );
*UTOPIA.oil_refinery.(2020*2060) 0 #it is not binding, so it can install as much as it wants

*[M€/PJ]
parameter VariableCost(r,t,m,y) / 
  UTOPIA.coal_pp.1.(2020*2060) 13.3 
  UTOPIA.ccgt_pp.1.(2020*2060) 15.31
  UTOPIA.oil_pp.1.(2020*2060) 14.33
  UTOPIA.geothermal_pp.1.(2020*2060) 5.22
  UTOPIA.windON_pp.1.(2020*2060) 0
  UTOPIA.windOFF_pp.1.(2020*2060) 0
  UTOPIA.pv_pp.1.(2020*2060) 0
  UTOPIA.bio_pp.1.(2020*2060) 124.6 
  UTOPIA.hydro_ror_pp.1.(2020*2060) 0 
  UTOPIA.hydro_dam_pp.1.(2020*2060) 0
  UTOPIA.psh_pp.1.(2020*2060) 0
  UTOPIA.psh_pp.2.(2020*2060) 0
  UTOPIA.nuclear_pp.1.(2020*2060) 0
/;

 VariableCost(r,t,m,y)$(VariableCost(r,t,m,y) = 0) = 1e-5;

*[M€/GW/a]
parameter FixedCost / 
  
  UTOPIA.coal_pp.(2020*2060) 35
  UTOPIA.ccgt_pp.(2020*2060) 10.5
  UTOPIA.oil_pp.(2020*2060) 32
  UTOPIA.geothermal_pp.(2020*2060) 170
  UTOPIA.windON_pp.(2020*2060) 38
  UTOPIA.windOFF_pp.(2020*2060) 100
  UTOPIA.pv_pp.(2020*2060) 23 
  UTOPIA.bio_pp.(2020*2060) 70 
  UTOPIA.hydro_ror_pp.(2020*2060) 100
  UTOPIA.hydro_dam_pp.(2020*2060) 55
  UTOPIA.psh_pp.(2020*2060) 48
  UTOPIA.nuclear_pp.(2020*2060) 0.11
  
/;

*------------------------------------------------------------------------   
* Parameters - Storage       
*------------------------------------------------------------------------

parameter TechnologyToStorage(r,m,t,s) /
  UTOPIA.1.rainfall.dam 1
  UTOPIA.2.psh_pp.dam 1
/;

parameter TechnologyFromStorage(r,m,t,s) /
  UTOPIA.1.hydro_dam_pp.dam  1
  UTOPIA.1.psh_pp.dam  1
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

CapacityOfOneTechnologyUnit(r,t,y) = 0;

parameter TotalAnnualMaxCapacity(r,t,y) /
  UTOPIA.hydro_dam_pp.(2020*2060) 12.5 
  UTOPIA.psh_pp.(2020*2060) 9.11 
  UTOPIA.hydro_ror_pp.(2020*2060) 9 

  UTOPIA.coal_pp.(2020*2060) 1e+3
  UTOPIA.ccgt_pp.(2020*2060) 1e+3
  UTOPIA.oil_pp.(2020*2060) 1e+3
  UTOPIA.geothermal_pp.(2020*2060) 0.817
  UTOPIA.windON_pp.(2020*2060) 1e+3
  UTOPIA.pv_pp.(2020*2060) 1e+3
  UTOPIA.bio_pp.(2020*2060) 1e+3

/;

TotalAnnualMaxCapacity(r,t,y)$(TotalAnnualMaxCapacity(r,t,y) = 0) = 99999;


parameter TotalAnnualMinCapacity(r,t,y) /
/;

TotalAnnualMaxCapacityInvestment(r,t,y) = 99999999;

TotalAnnualMinCapacityInvestment(r,t,y) = 0;

parameter TotalAnnualMaxCapacityInvestment(r,t,y) /

  UTOPIA.coal_pp.(2020*2060) 1e-5
  UTOPIA.ccgt_pp.(2020*2060) 10
  UTOPIA.oil_pp.(2020*2060) 1e-5
  UTOPIA.geothermal_pp.(2020*2060) 0.2
  UTOPIA.windON_pp.(2020*2060) 10
  UTOPIA.windOFF_pp.(2020*2060) 10
  UTOPIA.pv_pp.(2020*2060) 10
  UTOPIA.bio_pp.(2020*2060) 15


/;


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
/;

parameter ReserveMarginTagFuel(r,f,y) /
/;

parameter ReserveMargin(r,y) /
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
*MtonCO2/TJ
parameter EmissionActivityRatio(r,t,e,m,y) /
  UTOPIA.coal_pp.CO2.1.(2020*2060)  0.28979
  UTOPIA.ccgt_pp.CO2.1.(2020*2060)  0.122217
  UTOPIA.bio_pp.CO2.1.(2020*2060)  0
  UTOPIA.oil_pp.CO2.1.(2020*2060)  0.299875
  UTOPIA.oil_refinery.CO2.1.(2020*2060)  7300 
  UTOPIA.bio_pp.CO2.1.(2020*2060)  0.06388
*UTOPIA.pv_pp.CO2.1.(2020*2060)  0.013889
*UTOPIA.hydro_dam_pp.CO2.1.(2020*2060)  0.00667
*UTOPIA.hydro_ror_pp.CO2.1.(2020*2060)  0.00667
*UTOPIA.psh_pp.CO2.1.(2020*2060)  0.00667
*UTOPIA.geothermal_pp.CO2.1.(2020*2060) 0.010556 
*UTOPIA.wind_pp.CO2.1.(2020*2060)  0.0031944
*UTOPIA.windOFF_pp.CO2.1.(2020*2060)  0.0031944
*UTOPIA.nuclear_pp.CO2.1.(2020*2060)  0.00333
/;

EmissionsPenalty(r,e,y) = 0;

AnnualExogenousEmission(r,e,y) = 0;

AnnualEmissionLimit(r,e,y) = 9999;

ModelPeriodExogenousEmission(r,e) = 0;

ModelPeriodEmissionLimit(r,e) = 9999;