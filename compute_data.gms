ContinousDepreciation(r,t)$(OperationalLife(r,t) <> 0) = 1 - exp( 1 / ( - OperationalLife(r,t) + (0.01/2) * OperationalLife(r,t)**2) ); 
ContinousDepreciation(r,t)$(OperationalLife(r,t) = 0) = 1; 
ContinousDepreciation(r,t)$(ContinousDepreciation(r,t) < 0) = 0; 
ContinousDepreciation(r,t)$(ContinousDepreciation(r,t) > 1) = 1; 

*** define the renewable technology and fuel tags
RETagTechnology(r,t,y)$renewable_tech(t) = 1;
RETagFuel(r,f,y)$renewable_fuel(f) = 1;