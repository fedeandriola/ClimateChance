$include "Data/utopia_data.gms"

set TECHNOLOGY /
* new technologies
        SPV 'Solar power plants'
        WPP 'Wind power plants'
        BPP 'Biomass Power plants'
        HPP 'Hydro power plants'
        GPP 'Geothermal power plants'
        SUN 'Energy input from the sun'
        WIN 'Energy input from the wind'
        BIW 'Energy input from the biowaste'
        HYD 'Energy input from the water flow'
        GEO 'Energy input from the earth'
        

set FUEL / 
* new fuels 
        SOL 'Solar'
        WND 'Wind'
        BIO 'Biomass'
        HDR 'Hydro'
        GTH 'Geothermal'/;

set renewable_tech(TECHNOLOGY) /SPV,WPP,BPP,HPP,GPP/; 
set renewable_fuel(FUEL) /SOL,WND,BIO,HDR,GTH/; 

set power_plants(TECHNOLOGY) / SPV, WPP,BPP,HPP,GPP/;
set fuel_production_fict(TECHNOLOGY) /SUN, WIN,BIW,HYD,GEO/;????
set secondary_production(TECHNOLOGY) /SUN, WIN,BIW,HYD,GEO/;????

set primary_fuel(FUEL) / SOL, WND, BIO, HDR, GTH /;

# Characterize SOLAR technology
OperationalLife(r,'SPV') = 15;
CapacityFactor(r,'SPV','ID',y) = 0.4;
CapacityFactor(r,'SPV','IN',y) = 0;
CapacityFactor(r,'SPV','SD',y) = 0.8;
CapacityFactor(r,'SPV','SN',y) = 0;
CapacityFactor(r,'SPV','WD',y) = 0.1;
CapacityFactor(r,'SPV','WN',y) = 0;

InputActivityRatio(r,'SPV','SOL',m,y) = 1; #IEA convention
OutputActivityRatio(r,'SPV','ELC',m,y) = 1; 
OutputActivityRatio(r,'SUN','SOL',m,y) = 1; 

CapitalCost(r,'SPV',y) = 1000;
CapitalCost(r,'SUN',y) = 0; #the sun is free
VariableCost(r,'SPV',m,y) = 1e-5;
FixedCost(r,'SPV',y) = 25;


# Characterize WIND technology
OperationalLife(r,'WPP') = 15;

CapacityFactor(r,'WPP','ID',y) = 0.2;
CapacityFactor(r,'WPP','IN',y) = 0.3;
CapacityFactor(r,'WPP','SD',y) = 0.1;
CapacityFactor(r,'WPP','SN',y) = 0.15;
CapacityFactor(r,'WPP','WD',y) = 0.3;
CapacityFactor(r,'WPP','WN',y) = 0.4;

InputActivityRatio(r,'WPP','WND',m,y) = 1; #IEA convention
OutputActivityRatio(r,'WPP','ELC',m,y) = 1; 
OutputActivityRatio(r,'WIN','WND',m,y) = 1; 

CapitalCost(r,'WPP',y) = 1200;
CapitalCost(r,'WIN',y) = 0; #the wind is free
VariableCost(r,'WPP',m,y) = 1e-5;
FixedCost(r,'WPP',y) = 38;


# Characterize BIOMASS technology
OperationalLife(r,'BPP') = 20;

CapacityFactor(r,'BPP','ID',y) = 0.72;
CapacityFactor(r,'BPP','IN',y) = 0.72;
CapacityFactor(r,'BPP','SD',y) = 0.72;
CapacityFactor(r,'BPP','SN',y) = 0.72;
CapacityFactor(r,'BPP','WD',y) = 0.72;
CapacityFactor(r,'BPP','WN',y) = 0.72;

InputActivityRatio(r,'BPP','BIO',m,y) = 1; #IEA convention
OutputActivityRatio(r,'BPP','ELC',m,y) = 0.35;
OutputActivityRatio(r,'BIW','BIO',m,y) = 1; #IEA convention

CapitalCost(r,'BPP',y) = 3000;
CapitalCost(r,'BIW',y) = 0; #BIOMASS is free
VariableCost(r,'BPP',m,y) = 1e-5;
FixedCost(r,'BPP',y) = 70;


# Characterize HYDRO technology
OperationalLife(r,'WPP') = 100;

CapacityFactor(r,'HPP','ID',y) = 0.4;
CapacityFactor(r,'HPP','IN',y) = 0.4;
CapacityFactor(r,'HPP','SD',y) = 0.35;
CapacityFactor(r,'HPP','SN',y) = 0.35;
CapacityFactor(r,'HPP','WD',y) = 0.42;
CapacityFactor(r,'HPP','WN',y) = 0.42;

InputActivityRatio(r,'HPP','HDR',m,y) = 1; #IEA CONVENTION
OutputActivityRatio(r,'HPP','ELC',m,y) = 0.9;
OutputActivityRatio(r,'HYD','HDR',m,y) = 1;

CapitalCost(r,'HPP',y) = 2100,
CapitalCost(r,'HYD',y) = 0; #WATER is free
VariableCost(r,'HPP',m,y) = 1e-5;
FixedCost(r,'HPP',y) = 100;


# Characterize GEOTHERMAL technology
OperationalLife(r,'GPP') = 50;

CapacityFactor(r,'GPP','ID',y) = 0.82;
CapacityFactor(r,'GPP','IN',y) = 0.82;
CapacityFactor(r,'GPP','SD',y) = 0.82;
CapacityFactor(r,'GPP','SN',y) = 0.82;
CapacityFactor(r,'GPP','WD',y) = 0.82;
CapacityFactor(r,'GPP','WN',y) = 0.82;

InputActivityRatio(r,'GPP','GTH',m,y) = 1; #IEA convention
OutputActivityRatio(r,'GPP','ELC',m,y) = 1; #IEA convention
OutputActivityRatio(r,'GEO','GTH',m,y) = 1; #IEA convention

CapitalCost(r,'GPP',y) = 3500,
CapitalCost(r,'GEO',y) = 0; #GEOTHERMAL is free
VariableCost(r,'GPP',m,y) = 1e-5;
FixedCost(r,'GPP',y) = 170;