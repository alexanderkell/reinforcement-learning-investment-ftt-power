function varargout = FTT61x24SetGamGUIv2(varargin)
% FTT61X24SETGAMGUIV2 MATLAB code for FTT61x24SetGamGUIv2.fig
%      FTT61X24SETGAMGUIV2, by itself, creates a new FTT61X24SETGAMGUIV2 or raises the existing
%      singleton*.
%
%      H = FTT61X24SETGAMGUIV2 returns the handle to a new FTT61X24SETGAMGUIV2 or the handle to
%      the existing singleton*.
%
%      FTT61X24SETGAMGUIV2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FTT61X24SETGAMGUIV2.M with the given input arguments.
%
%      FTT61X24SETGAMGUIV2('Property','Value',...) creates a new FTT61X24SETGAMGUIV2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before FTT61x24SetGamGUIv2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to FTT61x24SetGamGUIv2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help FTT61x24SetGamGUIv2

% Last Modified by GUIDE v2.5 21-May-2019 13:09:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @FTT61x24SetGamGUIv2_OpeningFcn, ...
                   'gui_OutputFcn',  @FTT61x24SetGamGUIv2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before FTT61x24SetGamGUIv2 is made visible.
function FTT61x24SetGamGUIv2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to FTT61x24SetGamGUIv2 (see VARARGIN)

% Choose default command line output for FTT61x24SetGamGUIv2
handles.output = hObject;


%Get scenario data
hFTT = getappdata(0,'hFTT');
handles.DataScenario = getappdata(hFTT,'DataScenario');
handles.dt = getappdata(hFTT,'dt');
handles.CostSheet = getappdata(hFTT,'CostSheet');
handles.HistoricalG = getappdata(hFTT,'HistoricalG');
handles.HistoricalE = getappdata(hFTT,'HistoricalE');
handles.CapacityFactors = getappdata(hFTT,'CapacityFactors');
handles.CSCData = getappdata(hFTT,'CSCData');
handles.EndYear = getappdata(hFTT,'EndYear');
handles.kk = getappdata(hFTT,'kk'); %Scenario number
handles.CostsFileName = getappdata(hFTT,'CostsFileName');
%Region number
handles.k = getappdata(hFTT,'R');
set(handles.RegEdit,'String',num2str(handles.k));
dt = handles.dt;
EndYear = handles.EndYear;
%Number of years over which to evaluate slope differences
handles.Tint = str2num(get(handles.TintEdit,'string'));
Tint = handles.Tint;
N=Tint/dt;       %Number of simulation points

%function Out = FTT59x24v6(CostSheet,HistoricalG,HistoricalE,CapacityFactors,CSCData,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet,dt,NET,NWR,EndYear);

CostSheet = handles.CostSheet;
HistoricalG = handles.HistoricalG;
HistoricalE = handles.HistoricalE;
CapacityFactors = handles.CapacityFactors;
CSCData = handles.CSCData;
SubSheet = handles.DataScenario.SubSheet;
FiTSheet = handles.DataScenario.FiTSheet;
RegSheet = handles.DataScenario.RegSheet;
DPSheet = handles.DataScenario.DPSheet;
CO2PSheet = handles.DataScenario.CO2PSheet;
MWKASheet = handles.DataScenario.MWKASheet;
Unc = ones(20,1);

%---Classification dimensions
NET = 24; %Number of Energy Technologies
NNR = 14; %Number of Natural Resource Types
NTC = 6; %Number of traded energy commodities
NWR = 61; %Number of world regions
NLB = 6;  %Number of load bands

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
HG = zeros(NET,NWR,N+HN-1);    %Generation & Historical: Elect produced by technology (GWh) (-1 is for the repeated year 2017)
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
GLB = zeros(NLB,NWR,N);  %Generation per load bands normalised to total demand
ULB = zeros(NLB,NWR,N);  %Corresponding capacity per load band, normalised
SLB3 = zeros(NET,NLB,NWR,N);  %Shares of capacity by tech x load bands in electricity market
SGLB3 = zeros(NET,NLB,NWR,N);  %Shares of generation of tech x load bands in electricity market
S1LB3 = zeros(NET,NLB,NWR,N);  %Shares of capacity tech x load bands in electricity market
S2LB3 = zeros(NET,NLB,NWR,N);  %Shares of load bands tech x load bands in electricity market
CFLB3 = zeros(NET,NLB,NWR,N);  %Capacity factors for each tech x load bands in electricity market
ULB3 = zeros(NET,NLB,NWR,N);  %Capacities of tech x load bands in electricity market
GLB3 = zeros(NET,NLB,NWR,N);  %Generation for each tech x load bands in electricity market

%---Format Historical Data
Ht = HistoricalG(6,4:47)';
for k=1:NWR
    %Before 2013
    HG(:,k,1:HN) = permute(HistoricalG(7+(k-1)*27:30+(k-1)*27,4:47),[1 3 2]);
    HE(:,k,1:HN) = permute(HistoricalE(7+(k-1)*27:30+(k-1)*27,4:47),[1 3 2])/1000; %Factor 1000 IEA Mt -> Gt
    %Between 2013 and 2017
    HG(:,k,HN+1:HN+16) = permute(interp1N([2013:2017]',HistoricalG(7+(k-1)*27:30+(k-1)*27,47:51)',2013+dt*[1:16]'),[2 3 1]);
    HE(:,k,HN+1:HN+16) = permute(interp1N([2013:2017]',HistoricalE(7+(k-1)*27:30+(k-1)*27,47:51)'/1000,2013+dt*[1:16]'),[2 3 1]); %Factor 1000 IEA Mt -> Gt    
end

%---Format Assumptions Data
%Lists for plot legends:
TechList = {'1- Nuclear','2- Oil','3- Coal','4- Coal + CCS','5- IGCC','6- IGCC + CCS','7- CCGT','8- CCGT + CCS','9- Solid Biomass','10- S Biomass CCS','11- BIGCC','12- BIGCC + CCS','13- Biogas','14- Biogas + CCS','15- Tidal','16- Large Hydro','17- Onshore','18- Offshore','19- Solar PV','20- CSP','21- Geothermal','22- Wave','23- Fuel Cells','24- CHP'};
RegionsList = {'1 Belgium','2 Denmark','3 Germany','4 Greece','5 Spain','6 France','7 Ireland','8 Italy','9 Luxembourg','10 Netherlands','11 Austria','12 Portugal','13 Finland','14 Sweden','15 UK','16 Czech Republic','17 Estonia','18 Cyprus','19 Latvia','20 Lithuania','21 Hungary','22 Malta','23 Poland','24 Slovenia','25 Slovakia','26 Bulgaria','27 Romania','28 Norway','29 Switzerland','30 Iceland','31 Croatia','32 Turkey','33 Macedonia','34 USA','35 Japan','36 Canada','37 Australia','38 New Zealand','39 Russian Federation','40 Rest of Annex I','41 China','42 India','43 Mexico','44 Brazil','45 Argentina','46 Colombia','47 Rest of Latin America','48 Korea','49 Taiwan','50 Indonesia','51 Rest of ASEAN','52 OPEC excl Venezuela','53 Rest of world','54 Ukraine','55 Saudi Arabia','56 Nigeria','57 South Africa','58 Rest of Africa','59 Africa OPEC','60 Malaysia','61 Kazakhstan'};
FuelsList = {'1- Electricity','2- Uranium','3- Coal','4- Oil','5- Gas','6- Biofuels'};
%Global Data:
%Costs
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
P(:,:,1) = [.1 4.0 .5 2.5 0 0]'*ones(1,NWR);
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
    G(:,k,1) = HistoricalG(7+(k-1)*27:30+(k-1)*27,47); %in 2013
    %Subsidy/Taxes schemes
    T(:,k,:) = permute(interp1N(year',SubSheet([5:28]+25*(k-1),2:46)',t),[2 3 1]);
    %Subsidy/Taxes schemes
    FiT(:,k,:) = permute(interp1N(year',FiTSheet([5:28]+25*(k-1),2:46)',t),[2 3 1]);
    %First year cost matrices
    Costs(:,:,k,1) = MCosts(:,1:12);
end

%Matrix of suitability of technologies by load band
DD = CostSheet(144:167,3:8);
%Matrix of top band of technologies (highest band they can operate in)
DT = CostSheet(144:167,12:17);

%Investment
I(:,:,1) = 0;
%First year carbon costs from emissions 
%(remember: these costs are /unit energy) in $/t * t/GWh / 1000 = $/MWh
Costs(:,1,:,1) = permute(CO2(:,1)*CarbP(1,:,1),[1 3 2])/1000;
Costs(:,2,1,1) = 0; %No std at this point
%Starting levelised costs from starting costs:
[Costs(:,:,:,1),TPED(:,:,1),CFvar2,P(:,:,1),CSCData] = FTT61x24v8CostCurves(Costs(:,:,:,1),G(:,:,1),P(:,:,1),CSCData,D(:,:,1),REfficiency,CSCType,dt);
%update the capacity factors for renewables which depend on the cost curves
CF(Svar==1,:,1) = CFvar2(Svar==1,:);
%?????????Temp Fix:??????????? WAVE HAS ZERO CF EVERYWHERE
%CF(CF==0)=0.01;

%First MC point
[LCOE(:,:,1), dLCOE(:,:,1), TLCOE(:,:,1), dTLCOE(:,:,1), LCOEs(:,:,1), dLCOEs(:,:,1), MC(:,:,1), dMC(:,:,1)] = FTT61x24v8LCOE(Costs(:,:,:,1),r,T(:,:,1),FiT(:,:,1),CF(:,:,1),Unc);

%Starting Capacities (in GW) (for renewables only, for the RLDC)
U(:,:,1) = G(:,:,1)./(CF(:,:,1)+(CF(:,:,1)==0))/8766;
%Starting Shares (for renewables only, for the RLDC)
S(:,:,1) = U(:,:,1)./(ones(NET,1)*sum(U(:,:,1),1));

%Grid allocation of production
for k = 1:NWR
    %---- Determine the dispatch of capacity:
    %1--- Calculate the shape of the Residual Load Duration Curve (RLDC) using Uckerdt et al. (2017)
    [ULB(:,k,1),GLB(:,k,1),Curt(k,1),Ustor(k,1),CostStor(k,1)] = FTT61x24v8RLDC(G(:,k,1),CF(:,k,1),S(:,k,1),k);
    %2--- Dispatch the capacity of flexible systems based on marginal cost
    %SGLB3 -> shares of generation, with CFLB3 capacity factors
    [SGLB3(:,:,k,1),CFLB3(:,:,k,1),Shat(:,k,1),Shat2(:,k,1)] = FTT61x24v8DSPCH(MC(:,k,1),dMC(:,k,1),GLB(:,k,1),ULB(:,k,1),S(:,k,1),CF(:,k,1),Curt(k,1),DD,DT);
    %3--- Calculate average capacity factors for all systems according to which load bands they operate in (var are in load band 6)
    %Shares of capacity by tech x load band:
    %Note that the average capacity factor is 1/sum(ULB(:,k,1)
    SLB3(:,:,k,1) = SGLB3(:,:,k,1)./CFLB3(:,:,k,1)/sum(ULB(:,k,1));
    %Generation by tech x load band
    GLB3(:,:,k,1) = SGLB3(:,:,k,1).*D(6,k,1);
    %Capacity by tech x load band
    ULB3(:,:,k,1) = GLB3(:,:,k,1)./CFLB3(:,:,k,1);
    %Shares of tech by tech x load band (NOTE: sum(SLB3,1) = 1)
    S1LB3(:,:,k,1) = SLB3(:,:,k,1)./(ones(NET,1)*sum(SLB3(:,:,k,1),1));
    %Shares of load bands by tech x load band (NOTE: sum(S2LB3,2) = 1)
    S2LB3(:,:,k,1) = SLB3(:,:,k,1)./(sum(SLB3(:,:,k,1),2)*ones(1,NLB) + (sum(SLB3(:,:,k,1),2)==0)*ones(1,NLB));
    %Capacity factors averaged over all load bands
    Bidon = sum(S2LB3(:,:,k,1).*CFLB3(:,:,k,1),2);
    CF(:,k,1) = Bidon + (Bidon ==0).*CF(:,k,1);
end
%Update capacity factors of VRE for curtailment
CF(Svar==1,:,1) = CFvar2(Svar==1,:).*(1-ones(sum(Svar),1)*Curt(:,1)');

%Starting Capacities (in GW)
U(:,:,1) = G(:,:,1)./(CF(:,:,1) + (CF(:,:,1)==0))/8766;
%Starting Shares
S(:,:,1) = U(:,:,1)./(ones(NET,1)*sum(U(:,:,1),1));

%---Recreate historical variables from data (mostly for the purpose of
%calculating starting W)
%Historical CF (Note: inaccurate)
for t = 1:HN
    HCF(:,:,t) = CF(:,:,1) + (CF(:,:,1)==0);
    %Historical U (Note: inaccurate)
    HU(:,:,t) = HG(:,:,t)./(HCF(:,:,t))/8766;
    %Historical S
    HS(:,:,t) = HU(:,:,t)./(ones(NET,1)*sum(HU(:,:,t),1));
    %decommission rate
    dd(:,:,t) = d;
end

%Starting cumulative investment
%W(t=0) = sum(Historical decommissions) + sum(Changes in capacity)
W1 = trapz(1:HN'*ones(1,NET),sum(permute(dd.*HU(:,:,1:HN),[3 1 2]),3))'+trapz(2:HN'*ones(1,NET),sum(permute(HU(:,:,2:HN)-HU(:,:,1:HN-1),[3 1 2]),3))';
W2 = sum(permute(U(:,:,1),[3 1 2]),3)';
%W(:,1) = max(W1,W2);
W(:,1) = CostSheet(7:30,24);


%First LCOE point with dispatched CFs
[LCOE(:,:,1), dLCOE(:,:,1), TLCOE(:,:,1), dTLCOE(:,:,1), LCOEs(:,:,1), dLCOEs(:,:,1), MC(:,:,1), dMC(:,:,1)] = FTT61x24v8LCOE(Costs(:,:,:,1),r,T(:,:,1),FiT(:,:,1),CF(:,:,1),Unc);
%With gamma values
TLCOEg(:,:,1) = TLCOE(:,:,1) + Gam;
%Price of electricity: averaged LCOE by shares of G
P(6,:,1) = sum(S(:,:,1).*CF(:,:,1).*(TLCOE(:,:,1).*~isInclT + LCOE(:,:,1).*isInclT))./sum(S(:,:,1).*CF(:,:,1),1);

%Emissions first year 
E(:,:,1) = CO2.*G(:,:,1)/1e9;

%=======================
%MODEL DYNAMIC CALCULATION
clear t
%Since costs are 2013 values while start date is in 2017, estimate learning:
for t = 2:16 %2013 to 2016 incl
    %Historical Generation (in GWh) and emissions (in GtCO2)
    G(:,:,t) = HG(:,:,HN+t);
    E(:,:,t) = HE(:,:,HN+t);
    %Capacities (in GW) 
    CF(:,:,t) = CF(:,:,t-1);    
    U(:,:,t) = G(:,:,t)./(CF(:,:,t)+(CF(:,:,t)==0))/8766;
    %Shares 
    S(:,:,t) = U(:,:,t)./(ones(NET,1)*sum(U(:,:,t),1));
    %Grid allocation of production
    for k = 1:NWR
        %---- Determine the dispatch of capacity:
        %1--- Calculate the shape of the Residual Load Duration Curve (RLDC) using Uckerdt et al. (2017)
        [ULB(:,k,t),GLB(:,k,t),Curt(k,t),Ustor(k,t),CostStor(k,t)] = FTT61x24v8RLDC(G(:,k,t),CF(:,k,t),S(:,k,t),k);
        %2--- Dispatch the capacity of flexible systems based on marginal cost
        %SGLB3 -> shares of generation, with CFLB3 capacity factors
        [SGLB3(:,:,k,t),CFLB3(:,:,k,t),Shat(:,k,t),Shat2(:,k,t)] = FTT61x24v8DSPCH(MC(:,k,t-1),dMC(:,k,t-1),GLB(:,k,t),ULB(:,k,t),S(:,k,t),CF(:,k,t-1),Curt(k,t),DD,DT);
        %3--- Calculate average capacity factors for all systems according to which load bands they operate in (var are in load band 6)
        %Shares of capacity by tech x load band:
        %Note that the average capacity factor is 1/sum(ULB(:,k,t)
        SLB3(:,:,k,t) = SGLB3(:,:,k,t)./CFLB3(:,:,k,t)/sum(ULB(:,k,t));
        %Generation by tech x load band
        GLB3(:,:,k,t) = SGLB3(:,:,k,t).*D(6,k,t);
        %Capacity by tech x load band
        ULB3(:,:,k,t) = GLB3(:,:,k,t)./CFLB3(:,:,k,t);
        %Shares of tech by tech x load band (NOTE: sum(SLB3,t) = t)
        S1LB3(:,:,k,t) = SLB3(:,:,k,t)./(ones(NET,1)*sum(SLB3(:,:,k,t),1));
        %Shares of load bands by tech x load band (NOTE: sum(S2LB3,2) = t)
        S2LB3(:,:,k,t) = SLB3(:,:,k,t)./(sum(SLB3(:,:,k,t),2)*ones(1,NLB) + (sum(SLB3(:,:,k,t),2)==0)*ones(1,NLB));
        %Capacity factors averaged over all load bands
        CF(:,k,t) = sum(S2LB3(:,:,k,t).*CFLB3(:,:,k,t),2);
        CF(:,k,t) = CF(:,k,t) + (CF(:,k,t) ==0).*CF(:,k,t-1);
    end    %Capacity Investment: I = dU/dt + U*d (only positive changes of capacity + decommissions, in GW/y)
    I(:,:,t) = (U(:,:,t)-U(:,:,t-1))/dt.*((U(:,:,t)-U(:,:,t-1)) > 0) + U(:,:,t-1).*d;
    %Cumulative investment (using spillover knowledge mixing matrix B) a global process
    W(:,t) = W(:,t-1) + sum((B*I(:,:,t)),2)*dt;
    %Some costs don't change
    Costs(:,:,:,t) = Costs(:,:,:,t-1);
    %Carbon costs from emissions (remember: these costs are /unit energy) in $/t * t/GWh / 1000 = $/MWh
    Costs(:,1,:,t) = permute(CO2(:,1)*CarbP(1,:,t),[1 3 2])/1000;
    Costs(:,2,1,t) = 0; %No std at this point
    %Investment cost reductions from learning
    Costs(:,3,:,t) = Costs(:,3,:,t-1) - permute(Unc(3).*b.*(W(:,t)-W(:,t-1))./(W(:,t)+(W(:,t)==0)).*(W(:,t)>0)*ones(1,NWR),[1 3 2]).*Costs(:,3,:,t-1);
    Costs(:,4,:,t) = Costs(:,4,:,t-1) - permute(Unc(3).*b.*(W(:,t)-W(:,t-1))./(W(:,t)+(W(:,t)==0)).*(W(:,t)>0)*ones(1,NWR),[1 3 2]).*Costs(:,4,:,t-1); 
    %Resulting new levelised costs LCOE
    [LCOE(:,:,t), dLCOE(:,:,t), TLCOE(:,:,t), dTLCOE(:,:,t), LCOEs(:,:,t), dLCOEs(:,:,t), MC(:,:,t), dMC(:,:,t)] = FTT61x24v8LCOE(Costs(:,:,:,t),r,T(:,:,t),FiT(:,:,t),CF(:,:,t),Unc);
    P(:,:,t) = P(:,:,t-1);
end
%Add new technologies
for k = 1:NWR
    %Starting Generation (in GWh)
    G(:,k,t) = HistoricalG(7+(k-1)*27:30+(k-1)*27,52); %in 2013
end
%Starting Capacities (in GW)
U(:,:,t) = G(:,:,t)./(CF(:,:,t) + (CF(:,:,t)==0))/8766;
%Starting Shares
S(:,:,t) = U(:,:,t)./(ones(NET,1)*sum(U(:,:,t),1));

%Whether regulations
isReg = (REG(:,:,t) > 0).*(1 + tanh(2*1.25*(U(:,:,t-1)-REG(:,:,t))./REG(:,:,t)));
isReg(REG(:,:,t) == 0) = 1;

%hw = waitbar(0,'Calculation in progress');
% for k=1:NWR  
%    for i=1:NET  
%        %Calculate the slope of the historical shares in time over the last
%        %Tint years
%        P = polyfit([2017-Tint:1:2017],permute(HS(i,k,HN-Tint:HN),[1 3 2]),1);
%        waitbar(k/NWR/2)
%        Phist(i,k) = P(1);
%    end
% end  
%handles.Phist = Phist;

handles.Gam = Gam;
handles.TLCOE = TLCOE;
handles.dTLCOE = dTLCOE;
handles.Shat = Shat;
handles.Shat2 = Shat2;
handles.MWKA = MWKA;
handles.U = U;
handles.D = D;
handles.CF = CF;
handles.isReg = isReg;
handles.HS = HS;
%handles.Phist = Phist;
handles.S = S;
handles.A = A;
handles.Tint = Tint;
handles.Gb = Gb;
handles.NET = NET;
handles.NWR = NWR;
handles.NLB = NLB;
handles.dt = dt;
handles.tScaling = tScaling;
handles.Unc = Unc;
handles.MRIT = MRIT;
handles.GLB = GLB;
handles.SLB3 = SLB3;
handles.SGLB3 = SGLB3;
handles.CFLB3 = CFLB3;
handles.DD = DD;
handles.DT = DT;
handles.G = G;
handles.MC = MC;
handles.dMC = dMC;

%Calculate slope differences:
% for k = 1:NWR
%     handles.k = k;
%     handles.f0(:,k) = EvalGam(handles);
%     waitbar((k+NWR)/NWR/2)
% end
close(hw);
%Set max and min Gam
if str2num(get(handles.MaxGamEdit,'string')) < max(Gam(:,k))
    handles.MaxGam = num2str(max(Gam(:,k)));
    set(handles.MaxGamEdit,'string',handles.MaxGam);
else
    handles.MaxGam = str2num(get(handles.MaxGamEdit,'string'));
end
if str2num(get(handles.MinGamEdit,'string')) < min(Gam(:,k))
    handles.MinGam = num2str(min(Gam(:,k)));
    set(handles.MaxGamEdit,'string',handles.MinGam);
else
    handles.MinGam = str2num(get(handles.MinGamEdit,'string'));
end
%Set values in sliders and edit fields
%Note: the eval function is used in order to be able to have a for stucture
for i = 1:NET
    j = num2str(i);
    Gami = Gam(i,k);
    eval(['set(handles.slider' j ',''value'',(Gami-handles.MinGam)/(handles.MaxGam-handles.MinGam))']);
    eval(['set(handles.edit' j ',''string'',Gami)']);
    TLCOEi = TLCOE(i,k);
    eval(['set(handles.C' j ',''string'',TLCOEi)']);
%     f0i = handles.f0(i,k);
%     eval(['set(handles.O' j ',''string'',f0i)']);
    Si = S(i,k,1)*100;
    eval(['set(handles.S' j ',''string'',Si)']);
end
%Set total
% set(handles.Ototal,'string',num2str(sum(abs(handles.f0(:,k)))));
% set(handles.OldOtotal,'string',num2str(sum(abs(handles.f0(:,k)))));
%set(handles.AvgLCOE,'string',num2str(sum(TLCOE(:,k,1).*S(:,k,1))));
RegStr = {'1 Belgium','2 Denmark','3 Germany','4 Greece','5 Spain','6 France','7 Ireland','8 Italy','9 Luxembourg','10 Netherlands','11 Austria','12 Portugal','13 Finland','14 Sweden','15 UK','16 Czech Republic','17 Estonia','18 Cyprus','19 Latvia','20 Lithuania','21 Hungary','22 Malta','23 Poland','24 Slovenia','25 Slovakia','26 Bulgaria','27 Romania','28 Norway','29 Switzerland','30 Iceland','31 Croatia','32 Turkey','33 Macedonia','34 USA','35 Japan','36 Canada','37 Australia','38 New Zealand','39 Russian Federation','40 Rest of Annex I','41 China','42 India','43 Mexico','44 Brazil','45 Argentina','46 Colombia','47 Rest of Latin America','48 Korea','49 Taiwan','50 Indonesia','51 Rest of ASEAN','52 OPEC excl Venezuela','53 Rest of world','54 Ukraine','55 Saudi Arabia','56 Nigeria','57 South Africa','58 Rest of Africa','59 Africa OPEC','60 Malaysia','61 Kazakhstan'};
set(handles.RegionLabel,'string',RegStr{k});
handles.k = str2num(get(handles.RegEdit,'string'));
UpdateAll(hObject, handles)
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes FTT61x24SetGamGUIv2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function f = EvalGam(handles)
    Gam = handles.Gam;
    TLCOE = handles.TLCOE;
    dTLCOE = handles.dTLCOE;
    Shat = handles.Shat;
    Shat2 = handles.Shat2;
    MWKA = handles.MWKA;
    U = handles.U;
    D = handles.D;
    CF = handles.CF;
    isReg = handles.isReg;
    HS = handles.HS;
    %Phist = handles.Phist;
    S = handles.S;
    k = handles.k;
    A = handles.A;
    Tint = handles.Tint;
    Gb = handles.Gb;
    NET = handles.NET;
    NWR = handles.NWR;
    NLB = handles.NLB;
    dt = handles.dt;
    tScaling = handles.tScaling;
    dSij = zeros(NET,NET,NWR);%Exchange in shares between i and j
    Unc = handles.Unc;
    MRIT = handles.MRIT;
    GLB = handles.GLB;
    SLB3 = handles.SLB3;
    SGLB3 = handles.SGLB3;
    CFLB3 = handles.CFLB3;
    DD = handles.DD;
    DT = handles.DT;
    G = handles.G;
    MC = handles.MC;
    dMC = handles.dMC;

    %Function that replicates approx model run
    N=Tint/dt+1;
    HN = 44; %Number of historical data points

    %Calculate the simulated shares over the first Tint years
    for t = 17:16+N
        %Costs in log space for the cost comparison (see Wikipedia 'Lognormal distribution')
        TLCOEg = TLCOE(:,k,16) + Gam;
        for i = 1:NET
            %!Components of the constraints matrix Gij
            Gmax(i) = tanh(1.25*(Shat(i,k,t-1)-S(i,k,t-1))/Gb(i,k));
            Gmin(i) = tanh(1.25*(-(Shat2(i,k,t-1)-S(i,k,t-1))/Gb(i,k)));
            
            if (S(i,k,t-1) > 0 & MWKA(i,k,t) < 0)
                for j = 1:i-1
                    if (S(j,k,t-1) > 0 & MWKA(j,k,t) < 0)
%                         !-------Shares equation!! Core of the model!!------------------ 
                        %the use of erft(x) [i.e. tanh(1.25x)] instead of erf(x) is 2x faster with no changes of results
                        dFij = 1.414*sqrt(dTLCOE(i,k,16)*dTLCOE(i,k,16)+dTLCOE(j,k,16)*dTLCOE(j,k,16));
                        Fij = 0.5*(1+tanh(1.25*(TLCOEg(j,k,1)-TLCOEg(i,k,1))/dFij));
                        FF(i,j,k) = Fij*(1-isReg(i,k))*(1-isReg(j,k)) + isReg(j,k)*(1-isReg(i,k)) + .5*(isReg(i,k)*isReg(j,k));
                        FF(j,i,k) = (1-Fij)*(1-isReg(j,k))*(1-isReg(i,k)) + isReg(i,k)*(1-isReg(j,k)) + .5*(isReg(j,k)*isReg(i,k));
                        GG(i,j,k) = Gmax(i)*Gmin(j);
                        GG(j,i,k) = Gmax(j)*Gmin(i);
                        dSij(i,j,k) = (S(i,k,t-1)^Unc(1)*S(j,k,t-1)*A(i,j,k)*FF(i,j,k)*GG(i,j,k)- ...
                                      S(i,k,t-1)*S(j,k,t-1)^Unc(1)*A(j,i,k)*FF(j,i,k)*GG(j,i,k))*dt/tScaling;
                        dSij(j,i,k) = -dSij(i,j,k);
                    end
                end
            end
        end
        % !Add exogenous capacity changes (if any) and correct for regulations:
        % !Where MWKA>0 we have exogenously defined shares
        Utot(k) = sum(U(:,k,t-1),1);
        dUkMK(:,k) = (MWKA(:,k,t)>=0).*(MWKA(:,k,t)-U(:,k,t-1));
        % Regulations are stated in capacity, not shares. As total capacity
        % grows, we incorrectly add shares to tech. regulated out e.g. hydro
        % Where isReg > 0 we must take that out again. % Capacity growth is approximated by the % demand growth
        dUkREG(:,k) = -(D(6,k,t)-D(6,k,t-1))/D(6,k,t-1)*Utot(k)*S(:,k,t-1).*isReg(:,k);
        % Total capacity corrections:
        dUk(:,k) = dUkMK(:,k) + dUkREG(:,k);
        
        % Convert capacity corrections to shares:
        % !dSk = dUk/Utot - Uk dUtot/Utot^2  (Chain derivative)
        dSk(:,k) = dUk(:,k)/Utot(k) - U(:,k,t-1).*sum(dUk(:,k))/(Utot(k)*Utot(k));
        
        %!Differential equation: add endog changes dSij and corrections dSk to lagged shares MWSLt
        %Shares equation (sum over j in each region)
        S(:,k,t) = S(:,k,t-1) + permute(sum(dSij(:,:,k),2),[1 3 2]) + dSk(:,k);
        
        %-- Determine the dispatch of capacity:
        %---- Determine the dispatch of capacity:
        %1--- Calculate the shape of the Residual Load Duration Curve (RLDC) using Uckerdt et al. (2017)   
        [ULB(:,k,t),GLB(:,k,t),Curt(k,t),Ustor(k,t),CostStor(k,t)] = FTT61x24v8RLDC(G(:,k,t-1),CF(:,k,t-1),S(:,k,t),k);
        %2--- Dispatch the capacity of flexible systems based on marginal cost
        %SGLB3 -> shares of generation, with CFLB3 capacity factors
        [SGLB3(:,:,k,t),CFLB3(:,:,k,t),Shat(:,k,t),Shat2(:,k,t)] = FTT61x24v8DSPCH(MC(:,k),dMC(:,k),GLB(:,k,t),ULB(:,k,t),S(:,k,t),CF(:,k,t-1),Curt(k,t),DD,DT);
        %3--- Calculate average capacity factors for all systems according to which load bands they operate in (var are in load band 6)
        %Shares of capacity by tech x load band:
        %Note that the average capacity factor is 1/sum(ULB(:,k,t)
        SLB3(:,:,k,t) = SGLB3(:,:,k,t)./CFLB3(:,:,k,t)/sum(ULB(:,k,t));
        %Generation by tech x load band
        GLB3(:,:,k,t) = SGLB3(:,:,k,t).*D(6,k,t);
        %Capacity by tech x load band
        ULB3(:,:,k,t) = GLB3(:,:,k,t)./CFLB3(:,:,k,t);
        %Shares of tech by tech x load band (NOTE: sum(SLB3,t) = 1)
        S1LB3(:,:,k,t) = SLB3(:,:,k,t)./(ones(NET,1)*sum(SLB3(:,:,k,t),1));
        %Shares of load bands by tech x load band (NOTE: sum(S2LB3,2) = 1)
        S2LB3(:,:,k,t) = SLB3(:,:,k,t)./(sum(SLB3(:,:,k,t),2)*ones(1,NLB) + (sum(ULB3(:,:,k,t),2)==0)*ones(1,NLB));
        %Capacity factors averaged over all load bands
        CF(:,k,t) = sum(S2LB3(:,:,k,t).*CFLB3(:,:,k,t),2);
        %Capacity
        U(:,k,t) = S(:,k,t).*(ones(NET,1)*(D(6,k,t)/8766./sum(S(:,k,t).*CF(:,k,t),1)));
        %Energy Generation by technology (in GWh/y)
        G(:,k,t) = U(:,k,t).*CF(:,k,t)*8766;
    end
    TechStr = {'1- Nuclear','2- Oil','3- Coal','4- Coal + CCS','5- IGCC','6- IGCC + CCS','7- CCGT','8- CCGT + CCS','9- Solid Biomass','10- S Biomass CCS','11- BIGCC','12- BIGCC + CCS','13- Biogas','14- Biogas + CCS','15- Tidal','16- Large Hydro','17- Onshore','18- Offshore','19- Solar PV','20- CSP','21- Geothermal','22- Wave','23- Fuel Cells','24- CHP'};
    figure(99);
    tt = [[2017-Tint:2013] [2013+dt:dt:2017+Tint]];
    YY = [permute(HS(:,k,HN-Tint+4:HN),[1 3 2]) permute(S(:,k,1:16+Tint/dt),[1 3 2])];
    Lim = get(gca,'ylim');
    %Note that a piece of the shares is in the history and a piece is in the simulation over history, and then the simulation
    GamplotXCat(tt',YY','',TechStr,Lim);
    %Calculate the function to be minimised: the square of the relative slope difference
    Psim = (S(:,k,end)-S(:,k,1))/Tint;
    %f = abs((Phist(:,k)-Psim).*Psim);
    %f = (Phist(:,k)-Psim);
    f = 0;


function SliderUpdate(hObject, handles, i)
%function that calculates and updates upon slider movement
NET = 24;
MinGam = str2num(get(handles.MinGamEdit,'string'));
MaxGam = str2num(get(handles.MaxGamEdit,'string'));
k = handles.k;
Gam = handles.Gam;
for i = 1:NET
    j = num2str(i);
    eval(['Gam(i,k) = MinGam + get(handles.slider' j ',''value'')*(MaxGam-MinGam);']);
    Gami = Gam(i,k);
    eval(['set(handles.edit' j ',''string'',Gami)']);
end

%ReCalculate slope differences:
handles.Gam = Gam;
handles.f(:,k) = EvalGam(handles);

%Update results
for i = 1:NET
    j = num2str(i);
%    fi = handles.f(i);
%    eval(['set(handles.O' j ',''string'',fi)']);    
end
%Set total
%set(handles.Ototal,'string',num2str(sum(abs(handles.f))));
% Update handles structure
guidata(hObject, handles);

function GamUpdate(hObject, handles, i)
%function that calculates and updates upon slider movement

NET = 24;
MaxGam = str2num(get(handles.MaxGamEdit,'string'));
MinGam = str2num(get(handles.MinGamEdit,'string'));
Gam = handles.Gam;
k = handles.k;

for i = 1:NET
    j = num2str(i);
    eval(['Gam(i,k) = str2num(get(handles.edit' j ',''string''));']);
    slideri = (Gam(i,k)-MinGam)/(MaxGam-MinGam);
    eval(['set(handles.slider' j ',''value'',slideri)']);
end

%ReCalculate slope differences:
handles.f(:,k) = EvalGam(handles);

%Update results
for i = 1:NET
    j = num2str(i);
%     fi = handles.f(i);
%     eval(['set(handles.O' j ',''string'',fi)']);    
end
%Set total
% set(handles.Ototal,'string',num2str(sum(abs(handles.f))));
handles.Gam = Gam;
% Update handles structure
guidata(hObject, handles);

function UpdateAll(hObject, handles)
NET = 24;
Gam = handles.Gam;
k = handles.k;
%ReCalculate slope differences:
handles.f(:,k) = EvalGam(handles);
for i = 1:NET
    j = num2str(i);
    Gami = Gam(i,k);
    eval(['set(handles.slider' j ',''value'',(Gami-handles.MinGam)/(handles.MaxGam-handles.MinGam))']);
    eval(['set(handles.edit' j ',''string'',Gami)']);
    TLCOEi = handles.TLCOE(i,k);
    eval(['set(handles.C' j ',''string'',TLCOEi)']);
%     fi = handles.f(i);
%     eval(['set(handles.O' j ',''string'',fi)']);    
    Si = handles.S(i,k)*100;
    eval(['set(handles.S' j ',''string'',Si)']);
end
%Set total
%set(handles.Ototal,'string',num2str(sum(abs(handles.f))));
%set(handles.OldOtotal,'string',num2str(sum(abs(handles.f0(:,k)))));
%set(handles.AvgLCOE,'string',num2str(sum(handles.TLCOE(:,k).*handles.S(:,k))));
RegStr = {'1 Belgium','2 Denmark','3 Germany','4 Greece','5 Spain','6 France','7 Ireland','8 Italy','9 Luxembourg','10 Netherlands','11 Austria','12 Portugal','13 Finland','14 Sweden','15 UK','16 Czech Republic','17 Estonia','18 Cyprus','19 Latvia','20 Lithuania','21 Hungary','22 Malta','23 Poland','24 Slovenia','25 Slovakia','26 Bulgaria','27 Romania','28 Norway','29 Switzerland','30 Iceland','31 Croatia','32 Turkey','33 Macedonia','34 USA','35 Japan','36 Canada','37 Australia','38 New Zealand','39 Russian Federation','40 Rest of Annex I','41 China','42 India','43 Mexico','44 Brazil','45 Argentina','46 Colombia','47 Rest of Latin America','48 Korea','49 Taiwan','50 Indonesia','51 Rest of ASEAN','52 OPEC excl Venezuela','53 Rest of world','54 Ukraine','55 Saudi Arabia','56 Nigeria','57 South Africa','58 Rest of Africa','59 Africa OPEC','60 Malaysia','61 Kazakhstan'};
set(handles.RegionLabel,'string',RegStr{k});
% Update handles structure
guidata(hObject, handles);

function OfstBut_Callback(hObject, eventdata, handles)
%Offset gammas such that Petrol Econ is = 0
handles.k = str2num(get(handles.RegEdit,'string'));
k = handles.k;
handles.Gam(:,k) = handles.Gam(:,k) - handles.Gam(1,k);
UpdateAll(hObject, handles)

function ZeroBut_Callback(hObject, eventdata, handles)
%Sets all Gammas to zero
handles.k = str2num(get(handles.RegEdit,'string'));
k = handles.k;
handles.Gam(:,k) = 0;
UpdateAll(hObject, handles)

function BakBut_Callback(hObject, eventdata, handles)
%Sets all Gammas to last value saved
handles.k = str2num(get(handles.RegEdit,'string'));
k = handles.k;
handles.Gam(:,k) = handles.GamOld(:,k);
UpdateAll(hObject, handles)

function MaxGamEdit_Callback(hObject, eventdata, handles)

NET = 24;
MaxGam = str2num(get(handles.MaxGamEdit,'string'));
MinGam = str2num(get(handles.MinGamEdit,'string'));
Gam = handles.Gam;
k = handles.k;

for i = 1:NET
    j = num2str(i);
    eval(['Gam(i,k) = str2num(get(handles.edit' j ',''string''));']);
    if abs(Gam(i,k)) > MaxGam
        Gam(i,k) = sign(Gam(i,k))*MaxGam;
    end
end

for i = 1:NET
    j = num2str(i);
    Gami = Gam(i,k);
    eval(['set(handles.edit' j ',''string'',Gami)']);
    slideri = (Gam(i,k)-MinGam)/(MaxGam-MinGam);
    eval(['set(handles.slider' j ',''value'',slideri)']);
end
%ReCalculate slope differences:
handles.f(:,k) = EvalGam(handles);
%Update results
for i = 1:NET
    j = num2str(i);
%     fi = handles.f(i);
%     eval(['set(handles.O' j ',''string'',fi)']);    
end
%Set total
%set(handles.Ototal,'string',num2str(sum(abs(handles.f))));
% Update handles structure
guidata(hObject, handles);

function RegEdit_Callback(hObject, eventdata, handles)
%
NET = 24;
handles.k = str2num(get(handles.RegEdit,'string'));
k = handles.k;
Gam = handles.Gam;
%ReCalculate slope differences:
handles.f(:,k) = EvalGam(handles);
for i = 1:NET
    j = num2str(i);
    Gami = Gam(i,k);
    eval(['set(handles.slider' j ',''value'',(Gami-handles.MinGam)/(handles.MaxGam-handles.MinGam))']);
    eval(['set(handles.edit' j ',''string'',Gami)']);
    TLCOEi = handles.TLCOE(i,k);
    eval(['set(handles.C' j ',''string'',TLCOEi)']);
%     fi = handles.f(i);
%     eval(['set(handles.O' j ',''string'',fi)']);    
    Si = handles.S(i,k)*100;
    eval(['set(handles.S' j ',''string'',Si)']);
end
%Set total
% set(handles.Ototal,'string',num2str(sum(abs(handles.f))));
% set(handles.OldOtotal,'string',num2str(sum(abs(handles.f0(:,k)))));
%set(handles.AvgLCOE,'string',num2str(sum(handles.TLCOE(:,k).*handles.S(:,k))));
RegStr = {'1 Belgium','2 Denmark','3 Germany','4 Greece','5 Spain','6 France','7 Ireland','8 Italy','9 Luxembourg','10 Netherlands','11 Austria','12 Portugal','13 Finland','14 Sweden','15 UK','16 Czech Republic','17 Estonia','18 Cyprus','19 Latvia','20 Lithuania','21 Hungary','22 Malta','23 Poland','24 Slovenia','25 Slovakia','26 Bulgaria','27 Romania','28 Norway','29 Switzerland','30 Iceland','31 Croatia','32 Turkey','33 Macedonia','34 USA','35 Japan','36 Canada','37 Australia','38 New Zealand','39 Russian Federation','40 Rest of Annex I','41 China','42 India','43 Mexico','44 Brazil','45 Argentina','46 Colombia','47 Rest of Latin America','48 Korea','49 Taiwan','50 Indonesia','51 Rest of ASEAN','52 OPEC excl Venezuela','53 Rest of world','54 Ukraine','55 Saudi Arabia','56 Nigeria','57 South Africa','58 Rest of Africa','59 Africa OPEC','60 Malaysia','61 Kazakhstan'};
set(handles.RegionLabel,'string',RegStr{k});
% Update handles structure
guidata(hObject, handles);

function TintEdit_Callback(hObject, eventdata, handles)
%
NET = 24;
handles.Tint = str2num(get(handles.TintEdit,'string'));
k = handles.k;
Gam = handles.Gam;
%ReCalculate slope differences:
handles.f(:,k) = EvalGam(handles);
for i = 1:NET
    j = num2str(i);
    Gami = Gam(i,k);
    eval(['set(handles.slider' j ',''value'',(Gami-handles.MinGam)/(handles.MaxGam-handles.MinGam))']);
    eval(['set(handles.edit' j ',''string'',Gami)']);
    TLCOEi = handles.TLCOE(i,k);
    eval(['set(handles.C' j ',''string'',TLCOEi)']);
%     fi = handles.f(i);
%     eval(['set(handles.O' j ',''string'',fi)']);    
    Si = handles.S(i,k)*100;
    eval(['set(handles.S' j ',''string'',Si)']);
end
%Set total
% set(handles.Ototal,'string',num2str(sum(abs(handles.f))));
% set(handles.OldOtotal,'string',num2str(sum(abs(handles.f0(:,k)))));
%set(handles.AvgLCOE,'string',num2str(sum(handles.TLCOE(:,k).*handles.S(:,k))));
RegStr = {'1 Belgium','2 Denmark','3 Germany','4 Greece','5 Spain','6 France','7 Ireland','8 Italy','9 Luxembourg','10 Netherlands','11 Austria','12 Portugal','13 Finland','14 Sweden','15 UK','16 Czech Republic','17 Estonia','18 Cyprus','19 Latvia','20 Lithuania','21 Hungary','22 Malta','23 Poland','24 Slovenia','25 Slovakia','26 Bulgaria','27 Romania','28 Norway','29 Switzerland','30 Iceland','31 Croatia','32 Turkey','33 Macedonia','34 USA','35 Japan','36 Canada','37 Australia','38 New Zealand','39 Russian Federation','40 Rest of Annex I','41 China','42 India','43 Mexico','44 Brazil','45 Argentina','46 Colombia','47 Rest of Latin America','48 Korea','49 Taiwan','50 Indonesia','51 Rest of ASEAN','52 OPEC excl Venezuela','53 Rest of world','54 Ukraine','55 Saudi Arabia','56 Nigeria','57 South Africa','58 Rest of Africa','59 Africa OPEC'};
set(handles.RegionLabel,'string',RegStr{k});
% Update handles structure
guidata(hObject, handles);


function slider1_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 1)
function slider2_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 2)
function slider3_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 3)
function slider4_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 4)
function slider5_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 5)
function slider6_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 6)
function slider7_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 7)
function slider8_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 8)
function slider9_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 9)
function slider10_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 10)
function slider11_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 11)
function slider12_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 12)
function slider13_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 13)
function slider14_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 14)
function slider15_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 15)
function slider16_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 16)
function slider17_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 17)
function slider18_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 18)
function slider19_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 19)
function slider20_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 20)
function slider21_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 21)
function slider22_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 22)
function slider23_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 23)
function slider24_Callback(hObject, eventdata, handles)
SliderUpdate(hObject, handles, 24)

function edit1_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 1)
function edit2_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 2)
function edit3_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 3)
function edit4_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 4)
function edit5_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 5)
function edit6_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 6)
function edit7_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 7)
function edit8_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 8)
function edit9_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 9)
function edit10_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 10)
function edit11_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 11)
function edit12_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 12)
function edit13_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 13)
function edit14_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 14)
function edit15_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 15)
function edit16_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 16)
function edit17_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 17)
function edit18_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 18)
function edit19_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 19)
function edit20_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 20)
function edit21_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 21)
function edit22_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 22)
function edit23_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 23)
function edit24_Callback(hObject, eventdata, handles)
GamUpdate(hObject, handles, 24)


function SaveGamBut_Callback(hObject, eventdata, handles)
%Save gamma values back into xls file
%Gam(:,k) = handles.DataScenario.CostSheet(27*(k-1)+3:27*k,14);
k = handles.k;
xlswrite(handles.CostsFileName,handles.Gam,'Costs','C89:BK112');
handles.GamOld = handles.Gam;
guidata(hObject, handles);

function GamplotXCat(X,Y,Q,L,Lim)

S = size(Y,2);        
plot(X,Y(:,1:min(S,6)),'-');
if S > 6
    hold on;
    plot(X,Y(:,7:min(S,12)),'--');
end
if S > 12
    plot(X,Y(:,13:min(S,18)),':');
end
if S > 18
    plot(X,Y(:,19:min(S,24)),'-.');
end
if S > 24
    plot(X,Y(:,25:min(S,30)),'.');
end
if S > 30
    plot(X,Y(:,31:min(S,36)),'o');
end
if S > 36
    plot(X,Y(:,37:min(S,42)),'x');
end
if S > 42
    plot(X,Y(:,43:min(S,48)),'s');
end
if S > 48
    plot(X,Y(:,49:min(S,54)),'^');
end
if S > 54
    plot(X,Y(:,55:min(S,60)),'v');
end
if S > 60
    plot(X,Y(:,61:min(S,66)),'p');
end
if S > 66
    plot(X,Y(:,67:min(S,72)),'+');
end
if ~isempty(L)
    if ~isempty(Lim)
        set(gca,'ylim',Lim);
    end
    set(gca,'xlim',[min(X) max(X)]);
    LL = get(gca,'ylim');
    hold on; plot([2017 2017],LL,'--','color',[.5 .5 .5]);
    %set(gca,'linewidth',2,'fontweigh','bold','fontsize',16,'box','on');
    set(gca,'fontsize',10,'box','on');
    set(gca,'position',[0.099479         0.11      0.77028        0.815]);
    h = legend(L);
    set(gcf,'position',[1243         356         659         546]);
    set(h,'fontsize',6,'location','NorthEastOutside');
    ylabel(Q);
    hold off;
end


%===============================================================================
%==========Useless functions below==============================================
%===============================================================================

% --- Outputs from this function are returned to the command line.
function varargout = FTT61x24SetGamGUIv2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider23_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider24_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes during object creation, after setting all properties.
function slider25_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit9_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit13_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit14_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit14 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit15_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit16_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit17_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit22_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit23_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit24_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function edit25_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function RegEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RegEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function TintEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TintEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes during object creation, after setting all properties.
function MaxGamEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxGamEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MinGamEdit_Callback(hObject, eventdata, handles)
% hObject    handle to MinGamEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinGamEdit as text
%        str2double(get(hObject,'String')) returns contents of MinGamEdit as a double


% --- Executes during object creation, after setting all properties.
function MinGamEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinGamEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
