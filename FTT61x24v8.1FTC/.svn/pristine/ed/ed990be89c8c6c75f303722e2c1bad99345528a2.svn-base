%Copyright 2014 Jean-Francois Mercure, jm801@cam.ac.uk
%This program is distributed under the Lesser GNU General Public License (LGPL)
%This file is part of FTT21x24v4.

% FTT21x24v3 is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% FTT21x24v3 is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with FTT21x24v3.  If not, see <http://www.gnu.org/licenses/>.


function [LCOE, dLCOE, TLCOE, dTLCOE, LCOEs, dLCOEs, MC, dMC] = FTT21x24v8LCOE(Costs,r,T,FiT,CF,Unc)
%---function [LCOE, dLCOE, TLCOE, dTLCOE, LCOEs, dLCOEs] = FTT21x24v3LCOE(Costs,r,T,FiT,P,CF,Sflex)
%---M is the 3D matrix of costs as appears in spreadsheet FTT24x20v1.xls x NWR regions
%---M = [Carbon std Overnight std Fuel std OM std Lifetime Leadtime CapFactor]
%---r is the discount rate vector (international)
%---T is a tax/subsidy/Fit matrix (NETxNWR) subsidy is negative
%---P is the price of electricity vector NWR for FiTs
%---Overnight changes here according to learning and space depletion (renewables)
%---Fuel costs change according to resource depletion (fossil)
%---OM and the rest don't change
%---Output LCOE is a matrix of levelised costs NETxNWR
%---dLCOE is the statistical variation of the cost

NWR = size(Costs,3);
NET = size(Costs,1);
LCOE = zeros(NET,NWR);
TLCOE = zeros(NET,NWR); %LCOEs depend on the load band
dLCOE = zeros(NET,NWR);
dTLCOE = zeros(NET,NWR);
LCOEs = zeros(NET,NWR);
TLCOEs = zeros(NET,NWR);
MC = zeros(NET,NWR); %MCs don't depend on the load band
dMC = zeros(NET,NWR);

for i = 1:NWR
    M = Costs(:,:,i);
    %Lifetime (years) matrix lenght max lifetime, width 24
    LifeT = ones(max(M(:,9)+M(:,10)),1)*M(:,9)';
    %LeadTime (years) matrix length max lifetime, width 24
    LeadT = ones(max(M(:,9)+M(:,10)),1)*M(:,10)';
    %Time matrix (24 times the same vector)
    t = [0:max(M(:,9)+M(:,10))-1]'*ones(1,NET);
    %Discount rate the same at every time value
    rr = ones(length(t),1)*r(:,i)';

    %Capacity Factors (%) matrix length max lifetime, width 24
    CapFact = ones(max(M(:,9)+M(:,10)),1)*(CF(:,i)'+(CF(:,i)'==0));

    %Lifetime vector of CO2 costs
    CO2t = (ones(length(t),1)*M(:,1)').*(t >= LeadT & t < LifeT+LeadT);
    dCO2t = 0.*(t >= LeadT & t < LifeT+LeadT).*Unc(2);
    %Lifetime vector of overnight costs (= overnight if t<=LeadT, 0 otherwise)
    %Overnight is (in M) in $/kW => conversion to $/MWh requires 8766hours/year*1000
    Ot = (ones(length(t),1)*M(:,3)').*(t<LeadT)./LeadT./CapFact/8766*1000;
    dOt = (ones(length(t),1)*M(:,4)').*(t<LeadT)./LeadT./CapFact/8766*1000.*Unc(2);
    %Overnight with subsidy 
    TOt = (ones(length(t),1)*(M(:,3).*(1+T(:,i)))').*(t<LeadT)./LeadT./CapFact/8766*1000;
    dTOt = (ones(length(t),1)*(M(:,4).*(1+T(:,i)))').*(t<LeadT)./LeadT./CapFact/8766*1000.*Unc(2);
    %Lifetime vector of fuel costs (= Fuel if t>LeadT, 0 otherwise)
    Ft = (ones(length(t),1)*M(:,5)').*(t >= LeadT & t < LifeT+LeadT);
    dFt = (ones(length(t),1)*M(:,6)').*(t >= LeadT & t < LifeT+LeadT).*Unc(2);
    %Lifetime vector of O&M costs
    OMt = (ones(length(t),1)*M(:,7)').*(t >= LeadT & t < LifeT+LeadT);
    dOMt = (ones(length(t),1)*M(:,8)').*(t >= LeadT & t < LifeT+LeadT).*Unc(2);

    %Calculate LCOE:
    %Without subsidies
    LCOE(:,i) = sum((CO2t + Ot + Ft + OMt)./(1+rr).^t)./sum((t>=LeadT & t< LifeT+LeadT)./(1+rr).^t);
    dLCOE(:,i) = sum(sqrt(dCO2t.^2 + dOt.^2 + dFt.^2 + dOMt.^2)./(1+rr).^t)./sum((t>=LeadT & t<LifeT+LeadT)./(1+rr).^t);
    %Without carbon costs or subsidies
    LCOEs(:,i) = sum((Ot + Ft + OMt)./(1+rr).^t)./sum((t>=LeadT & t< LifeT+LeadT)./(1+rr).^t);
    dLCOEs(:,i) = sum(sqrt(dOt.^2 + dFt.^2 + dOMt.^2)./(1+rr).^t)./sum((t>=LeadT & t<LifeT+LeadT)./(1+rr).^t);
    %With subsidies
    TLCOE(:,i) = sum((CO2t + TOt + Ft + OMt)./(1+rr).^t)./sum((t>=LeadT & t< LifeT+LeadT)./(1+rr).^t);
    dTLCOE(:,i) = sum(sqrt(dCO2t.^2 + dTOt.^2 + dFt.^2 + dOMt.^2)./(1+rr).^t)./sum((t>=LeadT & t<LifeT+LeadT)./(1+rr).^t);
    TLCOE(FiT(:,i)>0,i) = TLCOE(FiT(:,i)>0,i) - FiT(FiT(:,i)>0,i);
    %Calculate marginal costs (they do not have the investment term nor discounting)
    MC(:,i) = M(:,1) + M(:,5) + M(:,7);
    dMC(:,i) = sqrt(M(:,2).^2 + M(:,6).^2 + M(:,8).^2);

end
