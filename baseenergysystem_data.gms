*** WE NEED TO POPULATE FIRST THE STRUCTURE OF THE MODEL
CIAO BABE TEST
*Define the time horizon 
SLAY queen
set     YEAR    / 2020*2050 /;
* mode of operations are a characteristic of technologies, useful for certain type of technologies that can be used in two different ways 
* e.g. a cogeneration power plant can be used in electricity generation mode or in heat generation mode
set     MODE_OF_OPERATION   / 1, 2, 3 /;
* the different regions of the model (only one for now)
set     REGION  / "WORLD" /;
* the different seasons of the model, useful to characterize variable demand and supply (e.g. renewables)
set     SEASON / 1 /;
* the different moments of the day, useful to characterize variable demand and supply (e.g. renewables) between day and night
set     DAYTYPE / 1 /;
* collector set for possible permulations of season and daytype
set     TIMESLICE / "ALLYEAR" /;
* this set is needed for characterizing storage technologies
set     DAILYTIMEBRACKET / 1 /;
* what type of emissions exists (we can then associate them to fuels)
set     EMISSION / "CO2" /;

* LET's NOW START WITH OUR SUPER SIMPLE ENERGY SISTEM

*Define the technologies of the model. We have three: refineries, oil power plant, and our final appliance (say light bulbs)
set     TECHNOLOGY   / "refineries", "oil_power_plant", "light_bulbs" /;

* let's also classify them in different categories (might become useful for reporting)
set power_plants(TECHNOLOGY) / "oil_power_plant" /;
set fuel_transformation(TECHNOLOGY) / "refineries" /;
set appliances(TECHNOLOGY) /"light_bulbs" /;

renewable_tech(t) = no;

*Define the fuels of the model. We have three: crude oil (primary energy), gasoline (secondary) and electricity (secondary)
*but note that final demand is also defined as a fuel! So it's actually four...
set     FUEL    / "crude_oil", "gasoline", "electricity", "lighting" /;

** NOTE THAT ALL TYPE OF FUELS (i.e. ENERGY FLOWS) ARE DEFINED AS FUELS
* we can conceptualize divide them as primary, secondary, and final demand. 
* primary fuels are input to the system, but not outputs (i.e. they are not produced by any technology)
set primary_fuel(FUEL) / "crude_oil" /;
* secondary fuels are both input and output of the system
set secondary_carrier(FUEL) / "gasoline", "electricity" /;
* final demand is only output of the system
set final_demand(FUEL) / "lighting" /;

renewable_fuel(f) = no;
** what I just described is a modelling convention. Osemosys is flexible enough to allow more complex interactions. 
** For example, lighting could be an input for the refineries (you need light for the operators..). 
** However, the self-use for energy-producting technologies is usually accounted for in efficiencies, whicn allows to define the flow
* from primary to final energy in a linear way. 

*** I need to populate the storage set with a dummy or the model will not compile.
set STORAGE /dummy/;

*** HERE, I AM INITIALIZING ALL PARAMETERS OF THE MODEL TO DEFAULT VALUES AFTER POPULATING THE SETS:
* By default, values are initialized as such that the technologies are not active
$include "Model/osemosys_init.gms"

* ANYWAY... LET'S START BUILDING THE MODEL
* the central parameters of the model are InputActivityRatio and OutputActivityRatio. Let's define them. 
* InputActivityRatio(r,t,f,m,y);
* OutputActivityRatio(r,t,f,m,y);
* THESE PARAMETERS SERVE TWO FUNCTIONS:
* (1) they define the efficiency of the technologies
* (2) they define the flows of energy in the system (i.e. the TYPE of FUEL(S) that is produced and consumed by each technology)
* this is the central concept of how to build energy systems in OSeMOSYS
* as you can see, they are a function or region r, technology t, fuel f, mode of operation m, and year y.
* but we have only one region, one mode of operation, and let's assume no variation in time. 
* then, the core of the set dependencies become the technology and the fuel.

* let's start with the refineries.
* here, we are saying that one unit of activity of refineries (e.g. one barrel of crude oil processed) requires one unit of crude oil
InputActivityRatio(r,"refineries","crude_oil",m,y) = 1;
* and that one unit of activity of refineries produces 0.9 units of gasoline
OutputActivityRatio(r,"refineries","gasoline",m,y) = 0.9;
* therefore, the overall efficiency of the refineries is 90%

* now, the oil power plant
* here, we are saying that one unit of activity of the oil power plant (e.g. one MWh of electricity produced) requires 3 units of gasoline
* this is equivalent of assuming an efficiency of 33.3%
InputActivityRatio(r,"oil_power_plant","gasoline",m,y) = 3;
* and that one MWh of electricity produced by the power plant produced 0.95 MWh of electricity (due to grid losses)
OutputActivityRatio(r,"oil_power_plant","electricity",m,y) = 0.95;
* as you can imagine, the total efficiency of the oil power plant in producing electricity is 31.7% (i.e. 0.95/3)

* finally, the light bulbs
* here, we are saying that one unit of activity of the light bulbs (e.g. one MWh of electricity consumed) requires 1 unit of electricity    
InputActivityRatio(r,"light_bulbs","electricity",m,y) = 1;
* and that one unit of activity of the light bulbs produces 0.2 unit of lighting (80% is wasted as heat)
OutputActivityRatio(r,"light_bulbs","lighting",m,y) = 0.2;
* NB this introduces the concept of useful energy, a deeper concept than final energy (final energy is the energy that reaches the end user, useful energy is the energy that is actually used for the intended purpose)

*** WE NOW BUILT THE SKELETON (i.e. THE NODES AND CONNECTIONS) OF THE MODEL
*** NOW LET'S DEFINE THE FINAL DEMANDS AND CHARACTERIZE TECHNOLOGIES.

* let's start with the final demands
* we have only one final demand, lighting
* we need to define the demand for lighting in each year (let's assume constant, for now)
AccumulatedAnnualDemand(r,"lighting",y) = 10;

* NB we can also specify a time profile for the demand, but we will do it later

* now, let's define the technologies: each is characterized by costs (capital, fixed and variable), capacity and availability factors
*** costs (per year)
*overnight costs of construction
CapitalCost(r,"refineries",y) = 100;
CapitalCost(r,"oil_power_plant",y) = 1000;
CapitalCost(r,"light_bulbs",y) = 0.001;

** yearly fixed cost (regardless of activity)
FixedCost(r,"refineries",y) = 50;
FixedCost(r,"oil_power_plant",y) = 30;
FixedCost(r,"light_bulbs",y) = 0;

** variable cost (per unit of activity)
VariableCost(r,"refineries",m,y) = 10;
VariableCost(r,"oil_power_plant",m,y) = .4;
VariableCost(r,"light_bulbs",m,y) = 0;

* lifetime of the technologies
OperationalLife(r,"refineries") = 50;
OperationalLife(r,"oil_power_plant") = 30;
OperationalLife(r,"light_bulbs") = 2;

* availability factor of the technologies, i.e. max percentage of time they can actually operate over a year
AvailabilityFactor(r,"refineries",y) = 0.9;
AvailabilityFactor(r,"oil_power_plant",y) = 0.8;
AvailabilityFactor(r,"light_bulbs",y) = 1;

* you also have the parameter CapacityFactor, that depends on the timeslice. 
* This can be used to mimick the supply curve of renewables. We'll see how in another exercise

* The reserve margin is specified by Reserve Margin (by default=0), for fuel ReserveMarginTagFuel, provided by technology ReserveMarginTagTechnology
ReserveMarginTagFuel(r,"electricity",y) = 1;
ReserveMarginTagTechnology(r,"oil_power_plant",y) = 1;

* Finally, we want to characterize emissions. 
* As you can see, the EmissionActivityRatio(r,t,e,m,y) depends on the technology, NOT the fuel. 
* this is convenient to track direct process emissions (for example chemicals and cement)
* to attribute emission to a fuel, it is convenient to create a fictional technology for each primary fuel (and assign an emission coefficient to them)
* LET'S DO IT: mind that thanks to $onrecursive we can redefine static sets

set TECHNOLOGY /"oil_market"/;

* this technologies produces crude oil for no inputs and with 100% efficiency
OutputActivityRatio(r,"oil_market","crude_oil",m,y) = 1;

* there are no fixed costs but a variable cost that identifies the price of the crude oil
VariableCost(r,"oil_market",m,y) = 50;

* operational life is virtually infinite (more than the time horizon of the model)
OperationalLife(r,"oil_market") = 1000;

AvailabilityFactor(r,"oil_market",y) = 1;

* infinite initial capacity
ResidualCapacity(r,"oil_market",y) = 99999;

* and, because fictional technology and fuel map 1 to 1, the emission equal the stechiometric emissions of crude oil
EmissionActivityRatio(r,"oil_market","CO2",m,y) = 0.075;