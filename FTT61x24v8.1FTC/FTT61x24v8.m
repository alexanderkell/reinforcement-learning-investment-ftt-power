%Copyright 2015 Jean-Francois Mercure, jm801@cam.ac.uk
%This program is distributed under the Lesser GNU General Public License (LGPL)
%This file is part of FTT61x24v8.

% FTT61x24v8 is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% FTT61x24v8 is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with FTT61x24v8.  If not, see <http://www.gnu.org/licenses/>.

function Out = FTT61x24v8(CostSheet,HistoricalG,HistoricalE,CapacityFactors,CSCData,Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet,dt,NET,NWR,EndYear);

%---FTT20x24: Third prototype of the ETM in 20 world regions
%---ETM24: Second prototype of the ETM single global region
%---SmallETM: First prototype 6 technologies
%---Based on cost distributions
%---24 Technologies
%---Using costs from IEA Projected costs of generating electricity
%---Uses excel spreadsheet ETM24v2.xls
%---Starting from SmallETMv1:
%---SmallETMv2:
%---    Added learning using:
%---        Equation for Demand D, investment I
%---        Equation for Capacity U, cumulative investment W
%---        Learning equation decreasing costs C
%---    Added to spreadsheet
%---        Decomission rates
%---        IEA projection data for demand D following new policies scenario
%---        IEA 2008 data for starting capacity U and capacity factors
%---        IEA 2008 data for starting shares S
%---        Starting cumulative investment W set equal to U
%---SmallETMv3
%---    Added calculation of CO2 emissions
%---    Added a carbon price as exogenous, starting with today's price and
%---        increasing at specified rate
%---    Added cost associated with carbon price and rates of emissions per technology
%---    Added taxes/subsidies (constant throughout)
%---    Allowed Aij to be not symmetric, where switching times from i to j need
%---        not be equal to that from j to i
%---    Added in spreadsheet values for Aij from plant lifetimes
%---SmallETMv4
%---    Added the dynamic limits of shares: gas, wind and solar are
%---        interdependent, along with static values for the demand profile
%---        and storage
%---    Changed Aij to use plant lifetime and build times: Aij = 10/sqrt(ti*tj)
%---ETM24v1
%---    New ETM: upgraded to 24 technologies
%---    Used cost values by making my own statistics of values in
%---        Proj. Costs. Gen. Elect., IEA, 2010
%---        Technologies are the ones for which this ref. has data
%---    Used Learning rates from various sources (not TCET): McDonald, IEA,guesses
%---    Used matrix Aij as 10/ti*10/tj,
%---        ti: lifetime, tj: lead time
%---    Strong interaction between technologies (ex: CCGT and Biogas)
%---    Added emission factors from IPCC Guidelines 2006
%---        Biomass CCS have negative emissions and get money from carbon trading
%---    Added matrix of spillover learning Bij
%---        Mixes learning in different categories
%---ETM24v2
%---    Added in the code the calculation of the levelised costs LCOE
%---        [LCOE, dLCOE] = ETM24LCOE(Costs,r)
%---        Reads cost data from spreadsheet
%---        Rebuilds LCOE the same way as was done previously in excel
%---        Rebuilds LCOE at each time step
%---    Added cost curves
%---        [Costs,Depletion] = ETM24CostCurves(Costs,GWh',U',CCurves);
%---        Using for now functional form: C(U) = -B/log(U/Umax) + C0
%---        Caution!!!: Share limits Shat and cost curves can clash:
%---            If we force to keep a share, we end up using more resouce than available
%---        LCOE calculation uses cost curves to change Ft, It or Capacity factors
%---            as resources get depleted
%---        Added variable Depletion which calculates % resources left
%---        Added variable GWh which cumulates energy produced
%---    Updated shares limit equation using only one line (!!!)
%---        Uses conditional information from spreadsheet (baseload, flexible or variable)
%---    Changed share limits system to remove their 'stickyness'
%---        We have Gi_min, Gj_max, Gj_min and Gi_max
%---        Shares stop at limit but can now bounce back, don't stick to limit
%---ETM24v3
%---    Set of equations relating S to U are inconsistent. Need a change.
%---    See Latex notes: SHARES ARE OF CAPACITY, NOT GENERATION
%---    This version changes equations for U, I, E, W, but not S
%---    We move away completely from Anderson + Winne, the source of the inconsistency
%---    Equation for investment and => capacity of A+W was inconsistent.
%---    Now the cost curves work properly
%---    Verified consistency for values for capacity, generation, emissions
%---    Made the capacity factors time dependent
%---        Flexible sources CF change as if variable renewables or demandprofile change
%---        Variable renewable CF change when number of units change since they all 
%---            have differenc CFs
%---    MADE SYSTEM INDEPENDENT OF TIME INTERVAL dt
%---        In some cases where changes dSij are large, using shorter dt prevents crashes
%---        When dSij is too large compared to dt, S sometimes go negative or complex
%---        Empirical observation: system may crash if Aij*dt > 5
%---        System gives very similar results for smaller and smaller dt 
%---            (dt = 1/4 is a good value)
%---    NOTE: This version (v3) is working and extensively tested.
%---          It follows exactly the equations that describe it
%---          See Tyndall Working Paper 148
%---ETM24v4
%---    We have built a new set of cost-supply curves for 20 regions and 13
%---      types of natural resources. ETM24v4 is still a single region model
%---      and we use it to test the global aggregated cost-supply curves. It
%---      should compare favourably with (v3), i.e. improved accuracy.
%---      However, no conceptual changes are included, apart from the following:
%---    1- Cost-supply curves are now interpolations into data given by CSC_GUI_v3
%---    2- Cost-supply curves progress according to total generation value (G(t))
%---    3- We do not need the 'resources' sheet of ETM24v3.xls
%---    4- Instead we read the text file ETM24v4CSCData.txt
%---    Some Cost calues in the new excel spreadsheet are updated (ETM24v4.xls)
%---    We get however problems with the cost curves for fossil fuels 
%---      compared with Rogner curves, which were better behaved. 
%---    Additional fix: there was a missing constraint for baseload capacity
%---      This is now represented as a second share limit Shat2
%---    The model description is accepted in Energy Policy!!
%---      Calculations for this were made using a hybrid Rogner/New CSCurves version
%---      ETM24v3-ResUpdate.m
%---ETM24v4.5
%---    Major change: we introduced the inverse price problem for stock resources.
%---      Stock resource fuel terms are now calculated using fuel prices (marginal costs)
%---      Prices are calculated in ETM24v45CostCurves.m and held in variable P
%---      P is a vector 13 elements long: Number of Natural Resources types NNR
%---      i.e. now stock resources are supplied by a range of resource costs
%---      The depletion occurs with exploitation frequency nu0 (See Tyndall Paper 2)
%---      !!This apparently fixes the problem for Stock resources and we 
%--       can now remove the Rogner curves!!
%---    Added historical data for plotting from IEA electricity generation data
%---      This data is now included in ETM24v45.xls
%---    For generation projections to fit historical data, we now start
%---      from generation data and find the capacities from assumed CFs
%---    The construction of a GUI enables to better separate the code from the assumptions. 
%---      The assumptions Spreadsheet(s) should now be kept separate
%---      We have 2 scenarios at this point
%---ETM24v5
%---    Many assumptions are made time dependent:
%---      Electricity demand, carbon price, non-power demand for resources 
%---      and time dependent subsidies/taxes are specified in the spreadsheet
%---      We now have up to 10 scenarios in memory simultaneously
%---    This is the most stable version and possibly final for the global model
%---    It finally uses correctly all of the cost-supply curves of the paper but 
%---      also including biogas and offshore (not in the paper)
%---    External assumptions were all derived from Terry's E3MG book simulations
%---FTT20x24v1
%---    We now multiply the model by 20 or 21 E3MG regions
%---      Dimensionality changes: all variables are 3D prisms (NET, NWR, t)
%---      with time in the 3rd dimension. Assumptions file is consequently larger
%---      Region definition can be changed!! If we have the right assumptions
%---    We are now using all individual cost-supply curves for renewables (180 curves)
%---      and the inverse problem (global) for traded fossil fuels (4 densities)
%---    The speed was improved dramatically by replacing the erf function by tanh (factor ~2x)
%---      It was also improved by using the symmetry dSij = -dSji (factor ~2x)
%---      (4.21min -> 1.00min for 2008 -> 2050 in 21 regions, 15s for reading the xlsx)
%---    A functionality for saving and loading calculated scenarios was added to the GUI
%---    A functionality for exporting results into excel or text files was added
%---    A spreadsheet of common LCOE adjustments for all scenarios was added
%---      This simplifies and enables the baseline to have zero technology support or taxes
%---      A good check was performed whether share limits are respected IMPORTANT!!
%---        The model when outside limits gives very strange results
%---FTT20x24v2
%---    Changed the way the GUI saves the data, now into Common Data Format files
%---    Changed the structure of the Excel spreadsheet to make changes more copy-pastable
%---FTT21x24v2
%---    After integration into E3MG, this has become a MPhil student use version
%---    E3MG-FTT2 (E3MGCCv1) can use the same input spreadsheets
%---    Outputs of the 2 models are not identical, but to make them is
%---    difficult given that E3MG-FTT has the economy endogenous and iterates
%---FTT21x24v3
%---    This version was tested by Tomohiro and Kerensa in 2014
%---    Also opensource and available on 4CMR website
%---    In Jan 2015, for use in LE course EP06, I tried to make outputs identical.
%---    LCOEs we not defined in exactly the same way, fixed. Still differences
%---FTT21x24v4
%---    Here I make the regulations time series instead of F matrices
%---    I also remove the use of spreadsheet based location of parameters
%---    Simplified the scenario management in the interface
%---FTT53x24v5
%---    We bring back E3ME-FTT version into Matlab for students, in 53
%---    regions, using the same input spreadsheets, to make the models identical
%---    For this I scrap the FTT:Power interface and use the more advanced FTT-Tr one
%---FTT59x24v6
%---    Add new E3ME regions into FTT
%---    Add new gamma parameters similar to FTT-Tr to make diffusion continuous across start of simulation
%---    For this, add new interface. These numbers will be used in E3ME
%---FTT59x24v7
%---    Major upgrade regarding data and start date. We now use IEA Proj Costs 2015
%---        Start date of simulation changes from 2008 to 2013
%---        Changes to the natural resources database for solar and wind capacity factors
%---        Changes were made first in E3ME NERC version 
%---FTT59x24v8Unc
%---    Includes new parameters for uncertainty and sensitivity analysis
%---FTT61v24v8FTC
%---    New major development with electricity market
%---    Includes 61 E3ME regions


hw = waitbar(0,'Calculation in progress');

%---Classification dimensions
%NET = 24; %Number of Energy Technologies
NNR = 14; %Number of Natural Resource Types
NTC = 6; %Number of traded energy commodities

%---Define variables
%Time is in the 3rd dimension!!! 
%Always use NET x NWR x Time in order

%  Matrices are 3D prisms with time in the 3rd dimension
%
%           time
%            .
%           .
%          .
%      /         /
%   t /         /
%    /         /
%  _/___i_____/
%  |         |   /
% j|         |NWR
%  |         | /
%  |_________|/
%      NET

N = (EndYear-2013)/dt+1;
HN = 44; %Number of historical data points
t = 2013+dt*[0:N-1]';
tScaling = 5; %Scaling relative to the standard matrix 10/tau*10/t in the excel spreadsheet
              %Note: the scaling should be such that it gives 20*1/tau*1/t
A = zeros(NET,NET,NWR); %Matrices of time constants
REG = zeros(NET,NWR,N); %Time series of regulations (1 or 0)
Costs = zeros(NET,12,NWR,N); %Costs matrix time dependent
S = zeros(NET,NWR,N);     %Shares
HS = zeros(NET,NWR,N+HN-1);     %Shares
Shat = zeros(NET,NWR,N);     %Share Limits
Shat2 = zeros(NET,NWR,N);     %Share Limits
dSij = zeros(NET,NET,NWR);%Exchange in shares between i and j
LCOE = zeros(NET,NWR,N);     %Levelised Cost excluding taxes ($/MWh)
dLCOE = zeros(NET,NWR,N);     %std Levelised Costs excluding ($/MWh)
LCOEs = zeros(NET,NWR,N);     %Levelised Cost excluding taxes and carbon price($/MWh)
dLCOEs = zeros(NET,NWR,N);     %std Levelised Costs excluding ($/MWh)
TLCOE = zeros(NET,NWR,N);    %Levelised Cost including taxes ($/MWh)
dTLCOE = zeros(NET,NWR,N);    %std Levelised Cost including taxes ($/MWh)
TLCOEg = zeros(NET,NWR,N);    %Levelised Cost including taxes and gamma values($/MWh)
U = zeros(NET,NWR,N);     %Total capacity (GW)
HU = zeros(NET,NWR,N+HN-1);     %Total capacity (GW)
CF = zeros(NET,NWR,N);    %Capacity factor 
HCF = zeros(NET,NWR,N+HN-1);    %Capacity factor 
W = zeros(NET,N);     %Cumulative investment (GW) is global (learning is global)
I = zeros(NET,NWR,N);     %Investment in new capacity (GW)
D = zeros(NTC,NWR,N);     %Total electricity demand (GWh)
E = zeros(NET,NWR,N);     %Emissions of CO2 during year t (Mt/y)
HE = zeros(NET,NWR,N+HN-1);     %Emissions & Historical emissions of CO2 during year t (Mt/y)
G = zeros(NET,NWR,N);    %Generation: Elect produced by technology (GWh)
HG = zeros(NET,NWR,N+HN-1);    %Generation & Historical: Elect produced by technology (GWh) (-1 is for the repeated year 2013)
P = zeros(NTC,NWR,N);    %Carrier Prices by commodity (international) 6 carriers
T = zeros(NET,NWR,N);     %Taxes and subsidies
MWKA = zeros(NET,NWR,N);     %Taxes and subsidies
isRelT = zeros(NET,NWR);  %Switch that determines whether taxes are relative to the price of electricity
isInclT = zeros(NET,NWR);  %Switch that determines whether taxes are relative to the price of electricity
TPED = zeros(NNR,NWR,N);     %Total Primary Energy use by resource (in PJ/y (fuels) or TWh/y (non-fuel renewables))
CumE = zeros(1,NWR,N);  %Cumulative emissions of CO2 for all tech. from beginning (t)
CarbP = zeros(1,NWR,N); %Price of emitting a ton of carbon ($/tCO2)
Utot = zeros(1,NWR);    %Total capacity per country (GW)
dUk = zeros(NET,NWR);     %Exogenous change in capacity
dSk = zeros(NET,NWR);     %Exogenous change in capacity

%---Format Historical Data
Ht = HistoricalG(6,4:47)';
for k=1:NWR
    HG(:,k,1:HN) = permute(HistoricalG(7+(k-1)*27:30+(k-1)*27,4:47),[1 3 2]);
    HE(:,k,1:HN) = permute(HistoricalE(7+(k-1)*27:30+(k-1)*27,4:47),[1 3 2])/1000; %Factor 1000 IEA Mt -> Gt
end

%---Format Assumptions Data
%Lists for plot legends:
TechList = {'1- Nuclear','2- Oil','3- Coal','4- Coal + CCS','5- IGCC','6- IGCC + CCS','7- CCGT','8- CCGT + CCS','9- Solid Biomass','10- S Biomass CCS','11- BIGCC','12- BIGCC + CCS','13- Biogas','14- Biogas + CCS','15- Tidal','16- Large Hydro','17- Onshore','18- Offshore','19- Solar PV','20- CSP','21- Geothermal','22- Wave','23- Fuel Cells','24- CHP'};
RegionsList = {'1 Belgium','2 Denmark','3 Germany','4 Greece','5 Spain','6 France','7 Ireland','8 Italy','9 Luxembourg','10 Netherlands','11 Austria','12 Portugal','13 Finland','14 Sweden','15 UK','16 Czech Republic','17 Estonia','18 Cyprus','19 Latvia','20 Lithuania','21 Hungary','22 Malta','23 Poland','24 Slovenia','25 Slovakia','26 Bulgaria','27 Romania','28 Norway','29 Switzerland','30 Iceland','31 Croatia','32 Turkey','33 Macedonia','34 USA','35 Japan','36 Canada','37 Australia','38 New Zealand','39 Russian Federation','40 Rest of Annex I','41 China','42 India','43 Mexico','44 Brazil','45 Argentina','46 Colombia','47 Rest of Latin America','48 Korea','49 Taiwan','50 Indonesia','51 Rest of ASEAN','52 OPEC excl Venezuela','53 Rest of world','54 Ukraine','55 Saudi Arabia','56 Nigeria','57 South Africa','58 Rest of Africa','59 Africa OPEC','60 Malaysia','61 Kazakhstan'};
FuelsList = {'1- Electricity','2- Uranium','3- Coal','4- Oil','5- Gas','6- Biofuels'};
%Global Data:
%Costs

% SALAS: Reads from excel file
MCosts = CostSheet(7:30,3:22);
%Variable Sources (logical: 1 = true)
Svar = MCosts(:,18);
%Flexible Sources (logical: 1 = true)
Sflex = MCosts(:,19);
%Baseload Sources (logical: 1 = true)
Sbase = MCosts(:,20);
%Learning exponents (we take b here as positive, due to the equation convention)
b = -MCosts(:,16);
%Gamma parameters for LCOE adjustment
Gam = CostSheet(89:112,3:63);
%CO2 Emission in tonne / GWh
CO2 = MCosts(:,15)*ones(1,NWR);
%Discount rate is technology specific
r = MCosts(:,17)*ones(1,NWR);
%Share Uncertainty
Gb = (MCosts(:,1)*0+.1)*ones(1,NWR);
%Decomission rates
d = 1./MCosts(:,9)*ones(1,NWR);
dd = zeros(NET,NWR,HN);
%Starting prices for the first inverse price calculation ($/GJ)
P(:,:,1) = [.1 4.5 .5 2.5 0 0]'*ones(1,NWR);
%Resource Efficiency
REfficiency = MCosts(:,14);
%CSC type (nren Fuel, ren Fuel, Investment,CF) 0,1,2 or 3
CSCType = MCosts(:,12);

%Spillover learning matrix
B = CostSheet(61:84,3:26);

%Intermittency of renewables
MRIT = .6;

%Regional Data:
%Matrices and parameters
for k = 1:NWR
    %---Matrices
    %Frequencies
    A(:,:,k) = RegSheet([5:28]+27*(k-1),29:52);
end
%---Parameters

%Demand
year = DPSheet(3,3:47);
%Demand profile dD/D (fraction of demand which is peak time)
dDovD = interp1N(year'*ones(1,NWR),DPSheet(4:64,3:47)',t*ones(1,NWR));
%Energy Storage generation normalised by the demand
EStorage = interp1N(year'*ones(1,NWR),DPSheet(67:127,3:47)',t*ones(1,NWR));
%Demand profile dU/U (required capacity to cover peak time)
dUovU = interp1N(year'*ones(1,NWR),DPSheet(130:190,3:47)',t*ones(1,NWR));
%Energy Storage capacity normalised by the demand
UStorage = interp1N(year'*ones(1,NWR),DPSheet(193:253,3:47)',t*ones(1,NWR));
for k = 1:NWR
    %Electicity demand GWh: corresponds to end of year demand
    %Note that D() corresponds to current demand
    %1-U, 2- Oil, 3- Coal, 4- Coal, 5- Biomass, 6- Electricity
    D(6,k,:) = permute(interp1(year'+dt,DPSheet(256+k-1,3:47)',t),[3 2 1])*1000; %Electricity in TWh->GWh
    CarbP(1,k,:) = permute(interp1(year'+dt,CO2PSheet(68+k-1,8:52)',t),[3 2 1]); %Carbon Prices
    %Non Power demand for fuels PJ
    D(2,k,:) = permute(interp1(year'+dt,DPSheet(382+k-1,3:47)',t),[3 2 1]); %Oil PJ
    D(3,k,:) = permute(interp1(year'+dt,DPSheet(319+k-1,3:47)',t),[3 2 1]); %Coal PJ
    D(4,k,:) = permute(interp1(year'+dt,DPSheet(445+k-1,3:47)',t),[3 2 1]); %Gas PJ
    %Interpolate regulations
    %REGa = RegSheet([5:28]+25*(k-1),2:46)'; REGb = (REGa == -1); REGa(REGb) = NaN;
    %REGc = interp1N(year',REGa,t);
    %REGd = interp1N(year',+REGb,t);
    %REGc(REGd~=0)=-1;
    %REG(:,k,:) = permute(REGc,[2 3 1]);
    REG(:,k,1:4:end-3) = permute(RegSheet([5:28]+27*(k-1),58:58+EndYear-2013-1),[1 3 2]);
    REG(:,k,2:4:end-2) = permute(RegSheet([5:28]+27*(k-1),58:58+EndYear-2013-1),[1 3 2]);
    REG(:,k,3:4:end-1) = permute(RegSheet([5:28]+27*(k-1),58:58+EndYear-2013-1),[1 3 2]);
    REG(:,k,4:4:end) = permute(RegSheet([5:28]+27*(k-1),58:58+EndYear-2013-1),[1 3 2]);
    %Exogenous capacity
    MWKAa = MWKASheet([5:28]+25*(k-1),2:46)'; 
    MWKAb = (MWKAa == -1); 
    MWKAa(MWKAb) = NaN;
    MWKAc = interp1N(year',MWKAa,t);
    MWKAd = interp1N(year',+MWKAb,t);
    MWKAc(MWKAd~=0)=-1;
    MWKA(:,k,:) = permute(MWKAc,[2 3 1]);
    MWKA(isnan(MWKA)) = -1;
    %MWKA(isnan(MWKA)) = -1;
    %MWKA(:,k,1:4:end-3) = permute(MWKASheet([5:28]+25*(k-1),4:4+EndYear-2013-1)',[2 3 1]);
    %MWKA(:,k,2:4:end-2) = permute(MWKASheet([5:28]+25*(k-1),4:4+EndYear-2013-1)',[2 3 1]);
    %MWKA(:,k,3:4:end-1) = permute(MWKASheet([5:28]+25*(k-1),4:4+EndYear-2013-1)',[2 3 1]);
    %MWKA(:,k,4:4:end) = permute(MWKASheet([5:28]+25*(k-1),4:4+EndYear-2013-1)',[2 3 1]);
end
%Starting values in simulation variables
%Capacity Factors for flexible systems
CF(:,:,1) = CapacityFactors(5:5+NET-1,3:3+NWR-1);
for k = 1:NWR
    %Starting Generation (in GWh)
    G(:,k,1) = HistoricalG(7+(k-1)*27:30+(k-1)*27,48);
    %Subsidy/Taxes schemes
    T(:,k,:) = permute(interp1N(year',SubSheet([5:28]+25*(k-1),2:46)',t),[2 3 1]);
    %Subsidy/Taxes schemes
    FiT(:,k,:) = permute(interp1N(year',FiTSheet([5:28]+25*(k-1),2:46)',t),[2 3 1]);
    %First year cost matrices
    Costs(:,:,k,1) = MCosts(:,1:12);
    Costs(:,12,k,1) = Gam(:,k);
end

%Starting Capacities (in GW)
U(:,:,1) = G(:,:,1)./CF(:,:,1)/8766;
%Starting Shares
S(:,:,1) = U(:,:,1)./(ones(NET,1)*sum(U(:,:,1),1));

%Calculation of capacity factors for flexible capacity (below rated values)
CFflexbase = .85; CFvarbase = .85;
CFbase(1,:) = (sum(CF(Sbase==1,:,1).*S(Sbase==1,:,1),1)./sum(S(Sbase==1,:,1),1));
CFvar(1,:) = (sum(CF(Svar==1,:,1).*S(Svar==1,:,1),1)./sum(S(Svar==1,:,1),1));
CFvar(1,isnan(CFvar(1,:))) = 0;
CFbase(1,isnan(CFbase(1,:))) = CFflexbase;
SSbase(1,:) = sum(S(Sbase==1,:,1),1);
SSvar(1,:) = sum(S(Svar==1,:,1),1);
SSflex(1,:) = sum(S(Sflex==1,:,1),1);
%Find average system capacity factors
CFbar(1,:) = CFflexbase.*(SSflex(1,:)+SSbase(1,:).*CFbase(1,:)/CFflexbase+SSvar(1,:)*(1/CFflexbase-MRIT)-dUovU(1,:))./(1-dDovD(1,:));

%---Recreate historical variables from data (mostly for the purpose of
%calculating starting W)
%Historical CF (Note: inaccurate)
for t = 1:HN
    HCF(:,:,t) = CF(:,:,1);
    %Historical U (Note: inaccurate)
    HU(:,:,t) = HG(:,:,t)./HCF(:,:,t)/8766;
    %Historical S
    HS(:,:,t) = HU(:,:,t)./(ones(NET,1)*sum(HU(:,:,t),1));
    %decommission rate
    dd(:,:,t) = d;
end
HCF(:,:,HN) = CF(:,:,1);
HU(:,:,HN) = U(:,:,1);
HS(:,:,HN) = S(:,:,1);

%Starting cumulative investment
%W(t=0) = sum(Historical decommissions) + sum(Changes in capacity)
W1 = trapz(1:HN'*ones(1,NET),sum(permute(dd.*HU(:,:,1:HN),[3 1 2]),3))'+trapz(2:HN'*ones(1,NET),sum(permute(HU(:,:,2:HN)-HU(:,:,1:HN-1),[3 1 2]),3))';
W2 = sum(permute(U(:,:,1),[3 1 2]),3)';
%W(:,1) = max(W1,W2);
W(:,1) = CostSheet(7:30,24);

%Investment
I(:,:,1) = 0;
%First year carbon costs from emissions 
%(remember: these costs are /unit energy) in $/t * t/GWh / 1000 = $/MWh
Costs(:,1,:,1) = permute(CO2(:,1)*CarbP(1,:,1),[1 3 2])/1000;
Costs(:,2,1,1) = 0; %No std at this point
%Starting levelised costs from starting costs:
[Costs(:,:,:,1),TPED(:,:,1),CFvar2,P(:,:,1),CSCData] = FTT61x24v8CostCurves(Costs(:,:,:,1),G(:,:,1),P(:,:,1),CSCData,D(:,:,1),REfficiency,CSCType,dt);
%update the capacity factors for renewables which depend on the cost curves
CF(Svar==1,:,1) = CFvar2(Svar==1)*ones(1,NWR);

%First LCOE point
[LCOE(:,:,1), dLCOE(:,:,1), TLCOE(:,:,1), dTLCOE(:,:,1), LCOEs(:,:,1), dLCOEs(:,:,1), MC(:,:,1), dMC(:,:,1)] = FTT61x24v8LCOE(Costs(:,:,:,1),r,T(:,:,1),FiT(:,:,1),CF(:,:,1),Unc);
%With gamma values
TLCOEg(:,:,1) = TLCOE(:,:,1) + Gam;
%Price of electricity: averaged LCOE by shares of G
P(6,:,1) = sum(S(:,:,1).*CF(:,:,1).*(TLCOE(:,:,1).*~isInclT + LCOE(:,:,1).*isInclT))./sum(S(:,:,1).*CF(:,:,1),1);

%Grid allocation of production
for k = 1:NWR
    %-- Determine the dispatch of capacity:
    %1- Calculate the shape of the Residual Load Duration Curve (RLDC) using Uckerdt et al. (2017)
    [RLDC(:,k,t),Curt(k,t),Ustor(k,t),CostStor(k,t)] = FTT61x24v8RLDC(Sw,Ss,k,Backup)
    %2- Dispatch the capacity of flexible systems based on marginal cost
    SLB(:,:,k,t) = FTT61x24v8DSPCH(MC(:,k,t-1),RLDC(:,k,t),S(:,k,t),DD);
    %3- Calculate average capacity factors for all systems according to which load bands they operate in (var are in load band 6)
    CF(:,k,t) = CFLB*SLB;
    %Reduce the CF of intermittent renewables by the curtailment factor
    %CF(Svar,k,t) = CF(Svar,k,t)*(1-Curt);
    %update the capacity factors for renewables which depend on the cost curves
    CF(Svar==1,k,1) = CFvar2(Svar==1,k)*(1-Curt);
end
%Recalculate LCOE with dispatched CFs
[LCOE(:,:,1), dLCOE(:,:,1), TLCOE(:,:,1), dTLCOE(:,:,1), LCOEs(:,:,1), dLCOEs(:,:,1), MC(:,:,1), dMC(:,:,1)] = FTT61x24v8LCOE(Costs(:,:,:,1),r,T(:,:,1),FiT(:,:,1),CF(:,:,1),Unc);

%Re-calculate starting Capacities (in GW) with new capacity factors
%U(:,:,1) = G(:,:,1)./CF(:,:,1)/8766;
%U(isnan(U)|isinf(U))=0;
%U(:,:,1) = S(:,:,1).*(ones(NET,1)*(D(6,:,1)/8766./sum(S(:,:,1).*CF(:,:,1),1)));
%Starting Shares
%S(:,:,1) = U(:,:,1)./(ones(NET,1)*sum(U(:,:,1),1));
%Emissions first year 
E(:,:,1) = CO2.*G(:,:,1)/1e9;
%Starting share limits
Shat(:,:,1) = (1*(Sflex == 1)+ -1*(Svar == 1))*ones(1,NWR).*(ones(NET,1)*(dUovU(1,:) - UStorage(1,:)) + ...
    ones(NET,1)*MRIT*(sum(S(Svar==1,:,1),1) - sum(S(Sflex==1,:,1),1)))+S(:,:,1);
Shat(Sbase == 1,:,1) = 1;
Shat2(:,:,1) = ones(NET,1)*(sum(S(:,:,1).*CF(:,:,1),1) - .5*dUovU(1,:) + UStorage(1,:)...
    - sum(S(Sbase==1,:,1),1) - sum(S(Svar==1,:,1),1)) + S(:,:,1);
Shat2(Sflex == 1,:,1) = 1;
%=======================
%MODEL DYNAMIC CALCULATION
clear t
for t = 2:N
    if mod(t,5)==0
        if ~ishandle(hw)
            break;
        else
            waitbar(t/N);
        end
    end
    if t == 100
        Bidon = 0;
    end
    %Update share limits:
%     MES1(:,J) = MWSLt(:,J) + (Sflex(:,J) - Svar(:,J))*(MEDK(J) - MEKS(J) + MRIT(J)*SSvar(J) - SSflex(J))
    Shat(:,:,t) = (1*(Sflex == 1)+ -1*(Svar == 1))*ones(1,NWR).*(ones(NET,1)*(dUovU(t,:) - UStorage(t,:)) + ...
        ones(NET,1)*MRIT*(sum(S(Svar==1,:,t-1),1) - sum(S(Sflex==1,:,t-1),1)))+S(:,:,t-1);
    Shat(Sbase == 1,:,t) = 1;
    Shat2(:,:,t) = ones(NET,1)*(sum(S(:,:,t-1).*CF(:,:,t-1),1) - .5*dUovU(t,:) + UStorage(t,:) - ...
        sum(S(Sbase==1,:,t-1),1) - sum(S(Svar==1,:,t-1),1)) + S(:,:,t-1);
    Shat2(Sflex == 1,:,t) = 1;
%     MES2(:,J) = MWSLt(:,J) + (CFbar(J) - .5*MEDK(J) + MEKS(J) - SSbase(J) - MRIT(J)*SSvar(J))
    %Whether regulations
    %WHERE (MEWR >= 0.0 .AND. MEWK > 0.0) isReg = .5 + .5*TANH(1.25*(MEWK - MEWR)/MEWK)
    isReg = (.5 + .5*tanh(1.25*(U(:,:,t-1)-REG(:,:,t))./U(:,:,t-1))).*(REG(:,:,t) >= 0);
    isReg(isnan(isReg)) = 0;

    for k = 1:NWR
        for i = 1:NET
            %!Components of the constraints matrix Gij
            %Gijmax(I) = Svar(I,J)*TANH(1.25*(MIN(MES1(I,J),MES2(I,J))-MWSLt(I,J))/dG) + Sflex(I,J) + SBase(I,J)*TANH(1.25*(MES2(I,J) - MWSLt(I,J))/dG)
            %Gijmin(I) = Svar(I,J) + Sflex(I,J)*TANH(-1.25*(MES1(I,J) - MWSLt(I,J))/dG) + Sbase(I,J)
            Gmax(i) = Svar(i)*tanh(1.25*((min(Shat(i,k,t),Shat2(i,k,t))-S(i,k,t-1))/Gb(i,k))) + ...
                Sflex(i) + Sbase(i)*tanh(1.25*((Shat2(i,k,t)-S(i,k,t-1))/Gb(i,k)));
            Gmin(i) = Svar(i) + Sflex(i)*tanh(1.25*(-(Shat(i,k,t)-S(i,k,t-1))/Gb(i))) + Sbase(i);
            if (S(i,k,t-1) > 0 & MWKA(i,k,t) < 0)
                for j = 1:i-1
                    if (S(j,k,t-1) > 0 & MWKA(j,k,t) < 0)
%                         !NOTE: TANH(1.25 X) is a cheap approx way to reproduce the normal CDF, i.e. ERF(X)), 1.414 = sqrt(2)
%                         dFij = 1.414*SQRT(MTDLt(I,J)*MTDLt(I,J) + MTDLt(K,J)*MTDLt(K,J))
%                         Fij = 0.5*(1+TANH(1.25*(MTCLt(K,J)-MTCLt(I,J))/dFij))
%                         !Preferences are either from investor choices (Fij) or enforced by policy (isReg, MEWR)
%                         !(isReg = 1 if either: MEWR <= MEWK or MWKA > 0, otherwise no REG -> isReg = 0)
%                         F(I,K) = Fij*(1.0-isReg(I,J))*(1.0-isReg(K,J)) + isReg(K,J)*(1.0-isReg(I,J)) + .5*(isReg(I,J)*isReg(K,J))
%                         F(K,I) = (1.0-Fij)*(1.0-isReg(K,J))*(1.0-isReg(I,J)) + isReg(I,J)*(1.0-isReg(K,J)) + .5*(isReg(K,J)*isReg(I,J))
%                         !-------Shares equation!! Core of the model!!------------------ 
%                         !(see eq 1 in Mercure EP 48 799-811 (2012) )
%                         dSij(I,K) = MWSLt(I,J)*MWSLt(K,J)*(BMWA(I,J,K)*F(I,K)*Gijmax(I)*Gijmin(K) - BMWA(K,J,I)*F(K,I)*Gijmax(K)*Gijmin(I))*dt/tScaling
%                         dSij(K,I) = -dSij(I,K)
%                         !-------Shares equation!! Core of the model!!------------------ 
                        %the use of erft(x) [i.e. tanh(1.25x)] instead of erf(x) is 2x faster with no changes of results
                        dFij = 1.414*sqrt(dTLCOE(i,k,t-1)*dTLCOE(i,k,t-1)+dTLCOE(j,k,t-1)*dTLCOE(j,k,t-1));
                        Fij = 0.5*(1+tanh(1.25*(TLCOEg(j,k,t-1)-TLCOEg(i,k,t-1))/dFij));
                        FF(i,j,k) = Fij*(1-isReg(i,k))*(1-isReg(j,k)) + isReg(j,k)*(1-isReg(i,k)) + .5*(isReg(i,k)*isReg(j,k));
                        FF(j,i,k) = (1-Fij)*(1-isReg(j,k))*(1-isReg(i,k)) + isReg(i,k)*(1-isReg(j,k)) + .5*(isReg(j,k)*isReg(i,k));
%                         GG(i,j,k) = 1;
%                         GG(j,i,k) = 1;
                        GG(i,j,k) = Gmax(i)*Gmin(j);
                        GG(j,i,k) = Gmax(j)*Gmin(i);
                        dSij(i,j,k) = (S(i,k,t-1)^Unc(1)*S(j,k,t-1)*A(i,j,k)*FF(i,j,k)*GG(i,j,k)- ...
                                      S(i,k,t-1)*S(j,k,t-1)^Unc(1)*A(j,i,k)*FF(j,i,k)*GG(j,i,k))*dt/tScaling;
                        dSij(j,i,k) = -dSij(i,j,k);
                    end
                end
            end
        end
        % !Add exogenous capacity changes (if any):
        % !Where MWKA>0 we have exogenously defined shares
        % Utot = SUM(MWKLt(:,J))
        Utot(k) = sum(U(:,k,t-1),1);
        % WHERE (MWKA(:,J) >= 0.0) dUk = MWKA(:,J)-MWKLt(:,J)
        dUk(:,k) = (MWKA(:,k,t)>=0).*(MWKA(:,k,t)-U(:,k,t-1));
        % !Changes of shares that are exogenous:
        % !dSk = dUk/Utot - Uk dUtot/Utot^2  (Chain derivative)
        % dSk = dUk/Utot - MWKLt(:,J)*dUtot/(Utot*Utot)
        dSk(:,k) = dUk(:,k)/Utot(k) - U(:,k,t-1).*sum(dUk(:,k))/(Utot(k)*Utot(k));
        % 
        %!Differential equation: add endog changes dSij and exog changes dSk to lagged shares MWSLt
        %MEWS(:,J) = MWSLt(:,J) + SUM(dSij,dim=2) + dSk
        %Shares equation (sum over j in each region)
        S(:,k,t) = S(:,k,t-1) + permute(sum(dSij,2),[1 3 2]) + dSk;

        %-- Determine the dispatch of capacity:
        %1- Calculate the shape of the Residual Load Duration Curve (RLDC) using Uckerdt et al. (2017)
        [RLDC(:,k,t),Curt(k,t),Ustor(k,t),CostStor(k,t)] = FTT61x24v8RLDC(Sw,Ss,k,Backup)
        %2- Dispatch the capacity of flexible systems based on marginal cost
        SLB(:,:,k,t) = FTT61x24v8DSPCH(MC(:,k,t-1),RLDC(:,k,t),S(:,k,t),DD);
        %3- Calculate average capacity factors for all systems according to which load bands they operate in (var are in load band 6)
        CF(:,k,t) = CFLB*SLB;
        %Reduce the CF of intermittent renewables by the curtailment factor
        %CF(Svar,k,t) = CF(Svar,k,t)*(1-Curt);

%     %Observed capacity factors (ratio of time capacity is actually used)
%     %Base load capacity factors never change
%     CF(Sbase == 1,:,t) = CF(Sbase == 1,:,t-1);
%     %Capacity factors for variable renewables
%     CF(Svar == 1,:,t) = CF(Svar == 1,:,t-1);
% 
%     %Calculation of capacity factors for flexible capacity (below rated values)
%     CFflexbase = .85; 
%     CFbase(t,:) = (sum(CF(Sbase==1,:,t).*S(Sbase==1,:,t),1)./sum(S(Sbase==1,:,t),1));
%     CFvar(t,:) = (sum(CF(Svar==1,:,t).*S(Svar==1,:,t),1)./sum(S(Svar==1,:,t),1));
%     CFvar(t,isnan(CFvar(t,:))) = 0;
%     CFbase(t,isnan(CFbase(t,:))) = CFflexbase;
%     SSbase(t,:) = sum(S(Sbase==1,:,t),1);
%     SSvar(t,:) = sum(S(Svar==1,:,t),1);
%     SSflex(t,:) = sum(S(Sflex==1,:,t),1);
%     %Calculate the average system capacity factor. When renewables or peak demand increase, it goes down,
%     CFbar(t,:) = CFflexbase.*(SSflex(t,:)+SSbase(t,:).*CFbase(t,:)/CFflexbase+SSvar(t,:)*(1/CFflexbase-MRIT)-dUovU(t,:))./(1-dDovD(t,:));
%     %Obtain unknown capacity factors for flexible systems, which take up the slack
%     %We allocate changes in CFbar according to CF values themselves (logistic function)
%     CFbarA(t,:) = sum(S(:,:,t-1).*CF(:,:,t-1),1);
%     Num = CF(Sflex==1,:,t-1).*(ones(sum(Sflex==1),1)*CFbarA(t,:)-S(Sflex==1,:,t-1).*CF(Sflex==1,:,t-1));
%     Denom = ones(sum(Sflex==1),1)*(1./sum(S(Sflex==1,:,t-1).*CF(Sflex==1,:,t-1).*(ones(sum(Sflex==1),1)*CFbarA(t,:)-S(Sflex==1,:,t-1).*CF(Sflex==1,:,t-1)),1));
%     CF(Sflex==1,:,t) = CF(Sflex==1,:,t-1);% + Num.*Denom.*(ones(sum(Sflex==1),1)*(CFbar(t,:)-CFbar(t-1,:)));
    end

    %Capacity
    U(:,:,t) = S(:,:,t).*(ones(NET,1)*(D(6,:,t)/8766./sum(S(:,:,t).*CF(:,:,t),1)));
    %Energy Generation by technology (in GWh/y)
    G(:,:,t) = U(:,:,t).*CF(:,:,t)*8766;
    %Capacity Investment: I = dU/dt + U*d (only positive changes of capacity + decommissions, in GW/y)
    I(:,:,t) = (U(:,:,t)-U(:,:,t-1))/dt.*((U(:,:,t)-U(:,:,t-1)) > 0) + U(:,:,t-1).*d;
    %Cumulative investment (using spillover knowledge mixing matrix B) a global process
    W(:,t) = W(:,t-1) + sum((B*I(:,:,t)),2)*dt;
    %CO2 emissions during year t (in Gt/y) in t/GWh * GWh/y /1e9
    E(:,:,t) = CO2.*G(:,:,t)/1e9;
    %Some costs don't change
    Costs(:,:,:,t) = Costs(:,:,:,t-1);
    %Carbon costs from emissions (remember: these costs are /unit energy) in $/t * t/GWh / 1000 = $/MWh
    Costs(:,1,:,t) = permute(CO2(:,1)*CarbP(1,:,t),[1 3 2])/1000;
    Costs(:,2,1,1) = 0; %No std at this point
    %Investment cost reductions from learning
    Costs(:,3,:,t) = Costs(:,3,:,t-1) - permute((Unc(3).*b.*(W(:,t)-W(:,t-1))./W(:,t))*ones(1,NWR),[1 3 2]).*Costs(:,3,:,t-1);
    Costs(:,4,:,t) = Costs(:,4,:,t-1) - permute((Unc(3).*b.*(W(:,t)-W(:,t-1))./W(:,t))*ones(1,NWR),[1 3 2]).*Costs(:,4,:,t-1); 
    %Investment costs and fuel costs from depletion and remaining resources
    [Costs(:,:,:,t),TPED(:,:,t),CFvar2(:,:),P(:,:,t),CSCData] = FTT61x24v8CostCurves(Costs(:,:,:,t),G(:,:,t),P(:,:,t-1),CSCData,D(:,:,t),REfficiency,CSCType,dt);
    %Update new average capacity factors for variable renewables given by cost curves and curtailment
    CF(Svar==1,:,t) = CFvar2(Svar==1,:)*(1-Curt);

    %Resulting new levelised costs LCOE
    [LCOE(:,:,t), dLCOE(:,:,t), TLCOE(:,:,t), dTLCOE(:,:,t), LCOEs(:,:,t), dLCOEs(:,:,t), MC(:,:,t), dMC(:,:,t)] = FTT61x24v8LCOE(Costs(:,:,:,t),r,T(:,:,t),FiT(:,:,t),CF(:,:,t),Unc);
    %LCOE including taxes/subsidies: (Note: isRelT is a switch for the type of subsidy scheme e.g. feed-in tariffs)
    %Note: a feed-on tariff has no effect on the dLCOE
    %Add gamma values
    TLCOEg(:,:,t) = TLCOE(:,:,t) + Gam;
    
    %Price of electricity
    %E3ME line: MEWP(8,:) = SUM( (MEWS*MEWL*MECC) ,dim=1)/CFbar
    %isInclT indicates whether FiTs are paid for by the grid or not
    P(6,:,t) = sum(S(:,:,t).*CF(:,:,t).*(TLCOE(:,:,t).*~isInclT + LCOE(:,:,t).*isInclT))./sum(S(:,:,t).*CF(:,:,t),1); %add cost of storage here?
end
if ishandle(hw)
    close(hw);
end


%=========================
%----Combine historical and simulated data
t = 2013 + dt*[0:N-1]';
%figure(1); clf;
%Note that the 2013 point repeats:
Ht = [Ht ; t(2:end)];
HG(:,:,45:end) = G(:,:,2:end);
HE(:,:,45:end) = E(:,:,2:end);
HCF(:,:,45:end) = CF(:,:,2:end);
HU(:,:,45:end) = U(:,:,2:end);
HS(:,:,45:end) = S(:,:,2:end);
%Remove NaN's that originate from no data in historical G
HS(isnan(HS)) = 0;

%------------Variable structure For Gui:
%We permute 2 dimensions so that we can plot more easily:
%The time dimension goes from last to first (NET, NWR, t) -> (t, NET, NWR)
%     ____i____
%    /        /|
%  j/        /NWR
%  /___NET__/  |
%  |        |  |
%  |        |T |
% t|        |i |
%  |        |m
%  |        |e
%      .     
%      .
%      .
%NET x Time x NWR (Gives 2D matrices per region identical to ETM24)
Out.t = t;
Out.Ht = Ht;
Out.D = permute(D,[3 1 2]);
Out.Names.D = {'Demand (GWh/y or GJ/y)'};
Out.S = permute(HS,[3 1 2]);
Out.Names.S = {'Market Shares'};
Out.G = permute(HG,[3 1 2]);
Out.Names.G = {'Electricity Generation (GWh/y)'};
Out.U = permute(HU,[3 1 2]);
Out.Names.U = {'Capacity (GW)'};
Out.E = permute(HE,[3 1 2]);
Out.Names.E = {'Emissions (Gt/y)'};
Out.CF = permute(CF,[3 1 2]);
Out.Names.CF = {'Capacity Factors'};
Out.LCOE = permute(LCOE,[3 1 2]);
Out.Names.LCOE = {'Levelised Cost ( 2013USD/MWh )'};
Out.TLCOE = permute(TLCOE,[3 1 2]);
Out.Names.TLCOE = {'Levelised Cost inc Taxes ( 2013USD/MWh )'};
Out.LCOEs = permute(LCOEs,[3 1 2]);
Out.Names.LCOEs = {'Levelised Cost excl CO2 price ( 2013USD/MWh )'};
Out.W = permute(W,[2 1 3]); %Note: W is global
Out.Names.W = {'Cumulative Capacity ( GW )'};
Out.I = permute(I,[3 1 2]);
Out.Names.I = {'Capacity Investment ( GW/year )'};
Out.P = permute(P,[3 1 2]);
Out.Names.P = {'Energy Prices ( USD/GJ or USD/MWh )'};
Out.TPED = permute(TPED,[3 1 2]);
Out.Names.TPED = {'Primary Energy Demand ( GJ/y )'};
Out.T = permute(T,[3 1 2]);
Out.Names.T = {'Subsidies'};
Out.FCosts = permute(Costs(:,5,:,:),[4 1 2 3]);
Out.Names.FCosts = {'Fuel Costs ( 2013USD/MWh )'};
Out.ICosts = permute(Costs(:,3,:,:),[4 1 2 3]);
Out.Names.ICosts = {'Investment Costs ( 2013USD/kW )'};
Out.CFCosts = permute(Costs(:,11,:,:),[4 1 2 3]);
Out.Names.CFCosts = {'Capacity Factor Costs'};
Out.CO2Costs = permute(Costs(:,1,:,:),[4 1 2 3]);
Out.Names.FCosts = {'Carbon Costs ( 2013USD/MWh )'};
Out.Shat = permute(Shat,[3 1 2]);
Out.Names.Shat = {'Share Limits 1'};
Out.Shat2 = permute(Shat2,[3 1 2]);
Out.Names.Shat2 = {'Share Limits 2'};
Out.CFbar = CFbar;
Out.Names.CFbar = {'Opt Average CF'};
Out.CFbarA = CFbarA;
Out.Names.CFbarA = {'Average CF'};
Out.CFvar = CFvar;
Out.Names.CFvar = {'CF Var'};
Out.CFbase = CFbase;
Out.Names.CFbase = {'CF Baseload'};
Out.SSbase = SSbase;
Out.Names.SSbase = {'Shares Baseload'};
Out.SSvar = SSvar;
Out.Names.SSvar = {'Shares Var'};
Out.SSflex = SSflex;
Out.Names.SSflex = {'Shares Flex'};

%Out.CO2 = CO2;

end