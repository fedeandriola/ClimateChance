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
*       waste_market 'waste'   avendo aggregato le biomaase mi sembra ridondante 
        biomass_market 'biomass'
        oil_market 'oil market'
        sun_market 'sun market'
        wind_market 'wind market'
        uranium_market 'uranium market'
        rainfall 'rainfall'
        oil_refinery 'refineries' # perchè abbiamo tenuto le oil refineries? abbiamo il prezzo del petrolio, ci servono davvero?
        coal_pp 'coal'
*       coal_usc_pp 'coal usc' aggregato in coal PP
        ccgt_pp 'combined cycle gas turbine'
*       wte_pp 'waste to energy'
        bio_pp 'bio energy'
        oil_pp 'oil power plant' #considerati qui dentro anche gli altri conmbustibili simili
        geothermal_pp 'geothermal'
        windON_pp 'windON'
        windOFF_pp 'windOFF'
        pv 'solar panels'
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
        waste 'Waste'
        biomass 'Biomass'
        oil_crude 'Oil Crude'
        oil_ref 'oil refined'
        water 'water from rainfall'
        sun 'sun'
        wind 'wind'
        geo_heat 'geothermal heat'
        uranium 'uranium'
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
set power_plants(TECHNOLOGY) / coal_pp, ccgt_pp, bio_pp, oil_pp, geothermal_pp, windON_pp, pv, hydro_ror_pp, hydro_dam_pp, psh_pp, nuclear_pp/;
set storage_plants(TECHNOLOGY) / hydro_dam_pp /;
set fuel_transformation(TECHNOLOGY) / oil_refinery /;
set appliances(TECHNOLOGY) /electricity_demand /;
#set unmet_demand(TECHNOLOGY) / /;
#set transport(TECHNOLOGY) / TXD, TXE, TXG /;
set primary_sources(TECHNOLOGY) / coal_market, gas_market, biomass_market, oil_market, rainfall, sun_market, wind_market, uranium_market /;
#set secondary_imports(TECHNOLOGY) / IMPDSL1, IMPGSL1 /;

set renewable_tech(TECHNOLOGY) / geothermal_pp, windON_pp, pv, hydro_ror_pp/; 
set renewable_fuel(FUEL) /water, sun, wind, geo_heat/; 

#set fuel_production(TECHNOLOGY);
#set fuel_production_fict(TECHNOLOGY) /RIV/;
#set secondary_production(TECHNOLOGY) /COAL, NUCLEAR, HYDRO, STOR_HYDRO, DIESEL_GEN, SRE/;

#Characterize fuels 
set primary_fuel(FUEL) / coal, gas, waste, biomass, oil_crude, uranium /;
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
#  ID.(2020*2060)  .3333   
#  IN.(2020*2060)  .1667
#*6mesi
  SD.(2020*2060)  .1667
  SN.(2020*2060)  .0833
*3mesi
  WD.(2020*2060)  .1667
  WN.(2020*2060)  .0833
*3mesi
/;

DiscountRate(r) = 0.05;

DaySplit(y,lh) = 12/(24*365); #ma la notte non la stiamo considerando da otto ore?

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

DaysInDayType(y,ls,ld) = 7; #sette giorni in una settimana

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

*   UTOPIA.electricity.2020 1135.44
*   UTOPIA.electricity.2021 1146.18
*   UTOPIA.electricity.2022 1156.92
*   UTOPIA.electricity.2023 1167.66
*   UTOPIA.electricity.2024 1178.4
*   UTOPIA.electricity.2025 1189.14
*   UTOPIA.electricity.2026 1199.88
*   UTOPIA.electricity.2027 1210.62
*   UTOPIA.electricity.2028 1221.36
*   UTOPIA.electricity.2029 1232.1
*   UTOPIA.electricity.2030 1242.84
*   UTOPIA.electricity.2031 1253.58
*   UTOPIA.electricity.2032 1264.32
*   UTOPIA.electricity.2033 1275.06
*   UTOPIA.electricity.2034 1285.8
*   UTOPIA.electricity.2035 1296.54
*   UTOPIA.electricity.2036 1307.28
*   UTOPIA.electricity.2037 1318.02
*   UTOPIA.electricity.2038 1328.76
*   UTOPIA.electricity.2039 1339.5
*   UTOPIA.electricity.2040 1350.24
*   UTOPIA.electricity.2041 1360.98
*   UTOPIA.electricity.2042 1371.72
*   UTOPIA.electricity.2043 1382.46
*   UTOPIA.electricity.2044 1393.2
*   UTOPIA.electricity.2045 1403.94
*   UTOPIA.electricity.2046 1414.68
*   UTOPIA.electricity.2047 1425.42
*   UTOPIA.electricity.2048 1436.16
*   UTOPIA.electricity.2049 1446.9
*   UTOPIA.electricity.2050 1457.64
*   UTOPIA.electricity.2051 1457.64
*   UTOPIA.electricity.2052 1457.64
*   UTOPIA.electricity.2053 1457.64
*   UTOPIA.electricity.2054 1457.64
*   UTOPIA.electricity.2055 1457.64
*   UTOPIA.electricity.2056 1457.64
*   UTOPIA.electricity.2057 1457.64
*   UTOPIA.electricity.2058 1457.64
*   UTOPIA.electricity.2059 1457.64
*   UTOPIA.electricity.2060 1457.64
*   UTOPIA.electricity.2061 1457.64
*   UTOPIA.electricity.2062 1457.64
*   UTOPIA.electricity.2063 1457.64
*   UTOPIA.electricity.2064 1457.64
*   UTOPIA.electricity.2065 1457.64
*   UTOPIA.electricity.2066 1457.64
*   UTOPIA.electricity.2067 1457.64
*   UTOPIA.electricity.2068 1457.64
*   UTOPIA.electricity.2069 1457.64
*   UTOPIA.electricity.2070 1457.64
*   UTOPIA.electricity.2071 1457.64
*   UTOPIA.electricity.2072 1457.64
*   UTOPIA.electricity.2073 1457.64
*   UTOPIA.electricity.2074 1457.64
*   UTOPIA.electricity.2075 1457.64
*   UTOPIA.electricity.2076 1457.64
*   UTOPIA.electricity.2077 1457.64
*   UTOPIA.electricity.2078 1457.64
*   UTOPIA.electricity.2079 1457.64
*   UTOPIA.electricity.2080 1457.64
*   UTOPIA.electricity.2081 1457.64
*   UTOPIA.electricity.2082 1457.64
*   UTOPIA.electricity.2083 1457.64
*   UTOPIA.electricity.2084 1457.64
*   UTOPIA.electricity.2085 1457.64
*   UTOPIA.electricity.2086 1457.64
*   UTOPIA.electricity.2087 1457.64
*   UTOPIA.electricity.2088 1457.64
*   UTOPIA.electricity.2089 1457.64
*   UTOPIA.electricity.2090 1457.64
*   UTOPIA.electricity.2091 1457.64
*   UTOPIA.electricity.2092 1457.64
*   UTOPIA.electricity.2093 1457.64
*   UTOPIA.electricity.2094 1457.64
*   UTOPIA.electricity.2095 1457.64
*   UTOPIA.electricity.2096 1457.64
*   UTOPIA.electricity.2097 1457.64
*   UTOPIA.electricity.2098 1457.64
*   UTOPIA.electricity.2099 1457.64
*   UTOPIA.electricity.2060 1457.64


* /;


parameter SpecifiedDemandProfile(r,f,l,y) / 
  UTOPIA.electricity.WD.(2020*2060)  .14
  UTOPIA.electricity.WN.(2020*2060)  .08
  UTOPIA.electricity.SPD.(2020*2060)  .19
  UTOPIA.electricity.SPN.(2020*2060)  .07
  UTOPIA.electricity.SD.(2020*2060)  .17
  UTOPIA.electricity.SN.(2020*2060)  .09
  UTOPIA.electricity.FD.(2020*2060)  .16
  UTOPIA.electricity.FN.(2020*2060)  .07
/;
#se definiamo specified annual demand non va definita



parameter AccumulatedAnnualDemand(r,f,y) /  
 /;

*------------------------------------------------------------------------   
* Parameters - Performance       
*------------------------------------------------------------------------

CapacityToActivityUnit(r,t)$power_plants(t) = 31.536; #PJ/GW/y

CapacityToActivityUnit(r,t)$(CapacityToActivityUnit(r,t) = 0) = 1;

* RSP 4.5        -((0,016875 *(y.val -2020))*0,75* 0,003)) riduzione percentuale di impianti termici al variare della temperatura dei fiumi
* RSP 8.5        -((0,036875 *(y.val -2020))*0,75* 0,003)) riduzione percentuale di impianti termici al variare della temperatura dei fiumi
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

CapacityFactor(r,'pv','WD',y) = 0.1;
CapacityFactor(r,'pv','WN',y) =0;
CapacityFactor(r,'pv','SPD',y) =0.4;
CapacityFactor(r,'pv','SPN',y) =0;
CapacityFactor(r,'pv','SD',y) =0.8;
CapacityFactor(r,'pv','SN',y) =0;
CapacityFactor(r,'pv','FD',y) =0.4;
CapacityFactor(r,'pv','FN',y) =0;

loop(y,CapacityFactor(r,'hydro_dam_pp','WD',y) = (0.0004*(y.val-2006)+0.2411));
loop(y,CapacityFactor(r,'hydro_dam_pp','WN',y) = (0.0004*(y.val-2006)+0.2411));
loop(y,CapacityFactor(r,'hydro_dam_pp','SPD',y) = (-0.0006*(y.val-2006)+0.3739));
loop(y,CapacityFactor(r,'hydro_dam_pp','SPN',y) = (-0.0006*(y.val-2006)+0.3739));
loop(y,CapacityFactor(r,'hydro_dam_pp','SD',y) = (-0.000005*(y.val-2006)+0.2012));
loop(y,CapacityFactor(r,'hydro_dam_pp','SN',y) = (-0.000005*(y.val-2006)+0.2012));
loop(y,CapacityFactor(r,'hydro_dam_pp','FD',y) = (0.0009*(y.val-2006)+0.3411));
loop(y,CapacityFactor(r,'hydro_dam_pp','FN',y) = (0.0009*(y.val-2006)+0.3411));

loop(y,CapacityFactor(r,'psh_pp','WD',y) = (0.0004*(y.val-2006)+0.2411));
loop(y,CapacityFactor(r,'psh_pp','WN',y) = (0.0004*(y.val-2006)+0.2411));
loop(y,CapacityFactor(r,'psh_pp','SPD',y) = (-0.0006*(y.val-2006)+0.3739));
loop(y,CapacityFactor(r,'psh_pp','SPN',y) = (-0.0006*(y.val-2006)+0.3739));
loop(y,CapacityFactor(r,'psh_pp','SD',y) = (-0.000005*(y.val-2006)+0.2012));
loop(y,CapacityFactor(r,'psh_pp','SN',y) = (-0.000005*(y.val-2006)+0.2012));
loop(y,CapacityFactor(r,'psh_pp','FD',y) = (0.0009*(y.val-2006)+0.3411));
loop(y,CapacityFactor(r,'psh_pp','FN',y) = (0.0009*(y.val-2006)+0.3411));

loop(y,CapacityFactor(r,'hydro_ror_pp','WD',y) = (0.0006*(y.val-2006)+0.4251));
loop(y,CapacityFactor(r,'hydro_ror_pp','WN',y) = (0.0006*(y.val-2006)+0.4251));
loop(y,CapacityFactor(r,'hydro_ror_pp','SPD',y) = (-0.0007*(y.val-2006)+0.7069));
loop(y,CapacityFactor(r,'hydro_ror_pp','SPN',y) = (-0.0007*(y.val-2006)+0.7069));
loop(y,CapacityFactor(r,'hydro_ror_pp','SD',y) = (-0.0006*(y.val-2006)+0.423));
loop(y,CapacityFactor(r,'hydro_ror_pp','SN',y) = (-0.0006*(y.val-2006)+0.423));
loop(y,CapacityFactor(r,'hydro_ror_pp','FD',y) = (0.0011*(y.val-2006)+0.5324));
loop(y,CapacityFactor(r,'hydro_ror_pp','FN',y) = (0.0011*(y.val-2006)+0.5324));

CapacityFactor(r,t,l,y)$(CapacityFactor(r,t,l,y) = 0) = 1; 

AvailabilityFactor(r,t,y) = 1;

parameter OperationalLife(r,t) /
  UTOPIA.coal_pp 35
  UTOPIA.ccgt_pp 20
  UTOPIA.oil_pp 35
  UTOPIA.geothermal_pp 50
  UTOPIA.windON_pp 20
  UTOPIA.windOFF_pp 30
  UTOPIA.pv 20
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
    ResidualCapacity("utopia","pv",y)=25.064;
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
    loop(y$(2022 <= y.val and y.val <= 2030), ResidualCapacity("utopia","pv",y)=ResidualCapacity("utopia","pv",y-1)*(1-.01) ;);
    loop(y$(y.val > 2030), ResidualCapacity("utopia","pv",y)=ResidualCapacity("utopia","pv",y-1)*(1-.15););
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


$if set no_initial_capacity ResidualCapacity(r,t,y) = 0; #sono sbagliati perchè queste sono le efficienze, a noi serve l'inverso :)
#da completare
parameter InputActivityRatio(r,t,f,m,y) / 
  UTOPIA.oil_refinery.oil_crude.1.(2020*2060) 1.02 
  UTOPIA.coal_pp.coal.1.(2020*2060) 2.63
  UTOPIA.ccgt_pp.gas.1.(2020*2060) 1.78
  UTOPIA.oil_pp.oil_ref.1.(2020*2060) 2.86
  UTOPIA.geothermal_pp.geo_heat.1.(2020*2060) 1 
  UTOPIA.windON_pp.wind.1.(2020*2060) 1
  UTOPIA.windOFF_pp.wind.1.(2020*2060) 1
  UTOPIA.pv.sun.1.(2020*2060) 1
  UTOPIA.bio_pp.biomass.1.(2020*2060) 3.23
  UTOPIA.hydro_ror_pp.water.1.(2020*2060) 1
  UTOPIA.hydro_dam_pp.water.1.(2020*2060) 1
  UTOPIA.psh_pp.water.1.(2020*2060) 1.15 
  UTOPIA.nuclear_pp.electricity.1.(2020*2060) 1
  UTOPIA.psh_pp.electricity.2.(2020*2060) 1.15 
  /;
*UTOPIA.oil_refinery.oil_crude.1.(2020*2060) 1.02 #da trovare
*UTOPIA.geothermal_pp.geo_heat.1.(2020*2060) 1 #IEA assumption for renewables
*UTOPIA.psh_pp.water.1.(2020*2060) 1.15 #turbine mode
*UTOPIA.psh_pp.electricity.2.(2020*2060) 1.15 #pumping mode


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
  UTOPIA.pv.electricity.1.(2020*2060) 1
  UTOPIA.bio_pp.electricity.1.(2020*2060) 1
  UTOPIA.hydro_ror_pp.electricity.1.(2020*2060) 1
  UTOPIA.hydro_dam_pp.electricity.1.(2020*2060) 1
  UTOPIA.nuclear_pp.electricity.1.(2020*2060) 1
  UTOPIA.psh_pp.electricity.1.(2020*2060) 1 
  UTOPIA.psh_pp.water.2.(2020*2060) 1 
/;
*UTOPIA.psh_pp.electricity.1.(2020*2060) 1 #turbine mode
*UTOPIA.psh_pp.water.2.(2020*2060) 1 #pumping mode


# By default, assume for imported secondary fuels the same efficiency of the internal refineries
* InputActivityRatio(r,'IMPDSL1','OIL',m,y)$(not OutputActivityRatio(r,'SRE','DSL',m,y) eq 0) = 1/OutputActivityRatio(r,'SRE','DSL',m,y); 
* InputActivityRatio(r,'IMPGSL1','OIL',m,y)$(not OutputActivityRatio(r,'SRE','GSL',m,y) eq 0) = 1/OutputActivityRatio(r,'SRE','GSL',m,y); 

*------------------------------------------------------------------------   
* Parameters - Technology costs       
*------------------------------------------------------------------------
#[M€/GW]aa
parameter CapitalCost / 
  UTOPIA.coal_market.(2020*2060) 0
  UTOPIA.gas_market.(2020*2060) 0
  UTOPIA.oil_market.(2020*2060) 0
  UTOPIA.biomass_market.(2020*2060) 0
  UTOPIA.rainfall.(2020*2060) 0
  UTOPIA.sun_market.(2020*2060) 0
  UTOPIA.wind_market.(2020*2060) 0
  UTOPIA.uranium_market (2020*2060) 0
  UTOPIA.oil_refinery.(2020*2060) 0 
  UTOPIA.coal_pp.(2020*2060) 2000
  UTOPIA.ccgt_pp.(2020*2060) 900
  UTOPIA.oil_pp.(2020*2060) 1800
  UTOPIA.geothermal_pp.(2020*2060) 3500
  UTOPIA.windON_pp.(2020*2060) 1350
  UTOPIA.windOFF_pp.(2020*2060) 3200
  UTOPIA.pv.(2020*2060) 1200
  UTOPIA.bio_pp.(2020*2060) 3500
  UTOPIA.hydro_ror_pp.(2020*2060) 2300
  UTOPIA.hydro_dam_pp.(2020*2060) 1900
  UTOPIA.psh_pp.(2020*2060) 1900 
  UTOPIA.nuclear_pp.(2020*2060) 4000

/;
*UTOPIA.oil_refinery.(2020*2060) 0 #it is not binding, so it can install as much as it wants

*[M€/PJ/a]
parameter VariableCost(r,t,m,y) / 
  UTOPIA.coal_pp.1.(2020*2060) 13.3 
  UTOPIA.ccgt_pp.1.(2020*2060) 15.31
  UTOPIA.oil_pp.1.(2020*2060) 14.33
  UTOPIA.geothermal_pp.1.(2020*2060) 5.22
  UTOPIA.windON_pp.1.(2020*2060) 0
  UTOPIA.windOFF_pp.1.(2020*2060) 0
  UTOPIA.pv.1.(2020*2060) 0
  UTOPIA.bio_pp.1.(2020*2060) 124.6 
  UTOPIA.hydro_ror_pp.1.(2020*2060) 0 
  UTOPIA.hydro_dam_pp.1.(2020*2060) 0
  UTOPIA.psh_pp.1.(2020*2060) 0
  UTOPIA.psh_pp.2.(2020*2060) 0
  UTOPIA.nuclear_pp.(2020*2060) 0
/;
*UTOPIA.coal_pp.1.(2020*2060) 13.3 #max tra normali e USC
*UTOPIA.bio_pp.1.(2020*2060) 124.6 # usato bioenergy considerando che il WTE è poco

 VariableCost(r,t,m,y)$(VariableCost(r,t,m,y) = 0) = 1e-5;

*[M€/GW/a]
parameter FixedCost / 
  
  UTOPIA.coal_pp.(2020*2060) 35
  UTOPIA.ccgt_pp.(2020*2060) 10.5
  UTOPIA.oil_pp.(2020*2060) 32
  UTOPIA.geothermal_pp.(2020*2060) 170
  UTOPIA.windON_pp.(2020*2060) 38
  UTOPIA.windOFF_pp.(2020*2060) 100
  UTOPIA.pv.(2020*2060) 23 
  UTOPIA.bio_pp.(2020*2060) 70 
  UTOPIA.hydro_ror_pp.(2020*2060) 100
  UTOPIA.hydro_dam_pp.(2020*2060) 55
  UTOPIA.psh_pp.(2020*2060) 48
  UTOPIA.nuclear_pp.(2020*2060) 0.11
  
/;
*UTOPIA.coal_pp.(2020*2060) 35 #max tra normali e USC
*UTOPIA.pv.(2020*2060) 23 #media tra rooftop e US
*UTOPIA.bio_pp.(2020*2060) 70 # usato bioenergy
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
  UTOPIA.ccgt_pp.(2020*2060) 10.5
  UTOPIA.oil_pp.(2020*2060) 1e+3
  UTOPIA.geothermal_pp.(2020*2060) 0.8
  UTOPIA.windON_pp.(2020*2060) 1e+3
  UTOPIA.pv.(2020*2060) (((1e+3)+0.8)/2)
  UTOPIA.bio_pp.(2020*2060) 1e+3
  UTOPIA.nuclear_pp.(2020*2030) 0

*questi valori sono stati presi da OSeMOSYS progetto vecchio
/;
*UTOPIA.hydro_dam_pp.(2020*2060) 12.5 #assuming 85% of the potential already exploited
*UTOPIA.psh_pp.(2020*2060) 9.11 #assuming 85% of the potential already exploited
*UTOPIA.hydro_ror_pp.(2020*2060) 9 #assuming 75% of the potential already exploited
TotalAnnualMaxCapacity(r,t,y)$(TotalAnnualMaxCapacity(r,t,y) = 0) = 99999;


parameter TotalAnnualMinCapacity(r,t,y) /
/;

TotalAnnualMaxCapacityInvestment(r,t,y) = 99999999;

TotalAnnualMinCapacityInvestment(r,t,y) = 0;
#da verificare i parametri
parameter TotalAnnualMaxCapacityInvestment(r,t,y) /

  UTOPIA.coal_pp.(2020*2060) 1e-5
  UTOPIA.ccgt_pp.(2020*2060) 1e-5
  UTOPIA.oil_pp.(2020*2060) 1e-5
  UTOPIA.geothermal_pp.(2020*2060) 0.2
  UTOPIA.windON_pp.(2020*2060) 0
  UTOPIA.windOFF_pp.(2020*2060) 0
  UTOPIA.pv.(2020*2060) 10
  UTOPIA.bio_pp.(2020*2060) 1e+3
*questi valori sono statiu presi da OSeMOSYS progetto vecchio

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
  UTOPIA.coal_pp.CO2.1.(2020*2060)  0.258929
  UTOPIA.ccgt_pp.CO2.1.(2020*2060)  0.109524
  UTOPIA.bio_pp.CO2.1.(2020*2060)  0.039583
  UTOPIA.oil_pp.CO2.1.(2020*2060)  0.163393
  
/;

EmissionsPenalty(r,e,y) = 0;

AnnualExogenousEmission(r,e,y) = 0;

AnnualEmissionLimit(r,e,y) = 9999;

ModelPeriodExogenousEmission(r,e) = 0;

ModelPeriodEmissionLimit(r,e) = 9999;