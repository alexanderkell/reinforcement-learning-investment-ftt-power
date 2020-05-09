%Copyright 2014 Jean-Francois Mercure, jm801@cam.ac.uk
%This program is distributed under the Lesser GNU General Public License (LGPL)
%This file is part of FTT21x24v3.

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


function [CostsOut,TPED,CF,POut,CSCDataOut] = FTT21x24v8CostCurves(CostsIn,G,P,CSCData,D,Efficiency,CSCType,dt)
%---Function that gives the costs as given by cost-supply curves as well as
%---    the inverse pricing problem
%---In the case of fossil fuels, it is the fuel costs that change
%---    with the price of carriers calculated here
%---    i.e. Coal, Oil, Gas, nuclear get more expensive with depletion
%---    Following the inverse problem (see Mercure&Salas2012b)
%---    This calculation is global!! It occurs once per time step, not per region
%---In the case of renewables, it is the 
%---        Capacity factor that changes (wind, solar, wave)
%---        Investment term (Hydro, Geothermal, Tidal)
%---        Fuel term for renewable fuels (biomass, biogas)
%---    i.e. best renewable sites taken first, then capacity factor decreases
%---
%---CostsIn is the 3D costs matrix at time t per region (Excel spreadsheet)
%---    New fuel costs values are given to exhaustible resources
%---    New capacity factors, Investment, fuel costs are given to renewables
%---G is the matrix NETxNWR of current energy generation by the technology in GWh/y (NET:24)
%---    This is because FTT works in GWh
%---P is the global vector of carrier prices in $/GJ (NNR:13)
%---CSCData are the cost curves for all technologies in TWh/y
%---    This is because CSC_gui_v3 works in TWh
%---    It is returned CSCDataOut since densities of stock resources gradually deplete

NET = 24;
% NWR = size(G,2);
NWR = 2;
NNR = 14;
CostsOut = CostsIn;

%======Add the capacities or energy sources for technologies that compete
%   for the same resources
%   (for ex.: Coal or Coal + CCS use the same fuel)
%   (       : All biomass are in competition except biogas)
%   (       : Solar PV and CSP compete for space)
%Moreover, the combined generation must not exceed the technical potentials
%GR is the variable of energy use by resource type (NNR:13)
%Convert back generation into fuel use (from GWh to PJ):
%Sum up competing technologies (from GWh to TWh)
%Note: the inclusion of components of D relates to exogenous non-power demand (GJ to PJ)
%Note: The CSCurves in CSCData are in TWh/y for renewables and PJ for fuels (including biofuels)
%      Costs are in $/MWh for renewables and $/GJ for fuels (including biofuels)
%Note:D(1) is in GWh/y (not use here), while D(2:6) is in PJ (non power demand)
%Efficiency = CostsIn(:,17)';
%Order of resources in the code
% 1	Nuclear     -> 1
% 2	Oil         -> 2
% 3	Coal        -> 3,4,5,6
% 4	Gas         -> 7,8
% 5	Biomass     -> 9,10,11,12
% 6	Biogas      -> 13
% 7 BiogasCCS   -> 14
% 8	Tidal       -> 15
% 9	Large Hydro -> 16
% 10 Onshore    -> 17
% 11 Offshore   -> 18
% 12 Solar      -> 19,20
% 13 Geothermal -> 21
% 14 Wave       -> 22
%Correspondence vector: tech to resource
j = [1 2 3 3 3 3 4 4 5 5 5 5 6 7 8 9 10 11 12 12 13 14 4 4]';
GR = zeros(NNR,NWR);
%==========Fossil Fuel Consumption============
%--------Prices of energy carriers
%nu values (see Mercure&Salas2012b)
for i = 1:NWR
    %Fossil fuel resources by region
    %Cost axis:
    %HistC = [CSCData(4,1):(CSCData(5,1)-CSCData(4,1))/(CSCData(6,1)-1):CSCData(5,1)]'*ones(1,4);
    for k = 1:4
        HistC(:,k,i) = [CSCData(4,[0:14:NWR*14-1]+k):(CSCData(5,[0:14:NWR*14-1]+k)-CSCData(4,[0:14:NWR*14-1]+k))./(CSCData(6,[0:14:NWR*14-1]+k)-1):CSCData(5,[0:14:NWR*14-1]+k)]';
        HistQ(:,k,i) = CSCData(7:996,(i-1)*14+k);
    end
    %U
    GR(1,i) = G(1,i)/Efficiency(1)*3.6/1000 + D(1,i);
    %Oil: 
    GR(2,i) = G(2,i)/Efficiency(2)*3.6/1000 + D(2,i);
    %Coal: 
    GR(3,i) = sum(G(3:6,i)./Efficiency(3:6),1)*3.6/1000 + D(3,i);
    %Gas
    GR(4,i) = sum(G([7 8 23 24],i)./Efficiency([7 8 23 24]),1)*3.6/1000 + D(4,i);
end

%U, Oil, Coal, Gas
nu = 1./[16 42 122 62];
%This function evaluates which new prices provides the requested supply
%It removes this particular supply from the exhaustible resource base
%Note that the prices of stock resources are the same for each region
POut = P;
for k = 1:4
    %The +1 in P() relates to that P(6,:) is electricity, and P(1:4,:) is U, oil, gas, coal, P(5,:) is biomass
    POut(k,:) = min(Inverse_Price(sum(GR(k,:)),sum(HistQ(:,k,:),3),HistC(:,k,1),min(P(k),100),nu(k))*ones(1,NWR),100); %In PJ (The histogram is in PJ, prices in $/GJ)
    for i = 1:NWR
        %HistQ(:,k,i) = HistQ(:,k,i) - nu(k)*HistQ(:,k,i).*FlowFossilProb(HistC(:,k,i),POut(k+1,1))*dt;
        HistQ(:,k,i) = HistQ(:,k,i) - nu(k)*HistQ(:,k,i).*FlowFossilProb(HistC(:,k,i),POut(k,:))*dt;
    end
end
%Temp hack to check rest of model
POut(1,:) = 0.255;
POut(2,:) = 5.689; 
POut(3,:) = 0.4246; 
POut(4,:) = 3.374; 


%Repack Fossil resources data:
CSCDataOut = CSCData;
for i = 1:NWR
    CSCDataOut(7:996,[1:4]+(i-1)*14) = HistQ(:,:,i);
end

%==========Renewables Consumption=============

for i = 1:NWR
    %Regional CSCurves
    %Fossil Quantities and costs
    %CSC_Q(:,1:4) = HistQ;
    %CSC_C(:,1:4) = HistC;
    for ii=5:max(j)
        if ((CSCData(5,(i-1)*14+ii)-CSCData(4,(i-1)*14+ii))/(CSCData(6,(i-1)*14+ii)-1) > 0)
            %Renewables quantities (equally spaced axis)
            CSC_Q(:,ii,i) = [CSCData(4,(i-1)*14+ii):(CSCData(5,(i-1)*14+ii)-CSCData(4,(i-1)*14+ii))/(CSCData(6,(i-1)*14+ii)-1):CSCData(5,(i-1)*14+ii)]';
            %Renewables costs
            CSC_C(:,ii,i) = CSCData(7:996,(i-1)*14+ii);
        else
            %Renewables quantities
            CSC_Q(:,ii,i) = [1:size(CSC_Q,1)];
            %Renewables costs
            CSC_C(:,ii,i) = 0;
        end
    end
    
    CF(:,i) = CostsIn(:,11,i);
    %Biomass (careful: the cost curve is in PJ)
    GR(5,i) = sum(G(9:12,i)./Efficiency(9:12))*3.6/1000 + D(5,i);
    %Biogas
    GR(6:7,i) = sum(G(13:14,i))/1000;
    %Solar PV and CSP (Note: CSP is less efficient and therefore consumes more space
    GR(12,i) = sum(G(19:20,i)./Efficiency(19:20))/1000;
    %Hydro
    GR(9,i) = G(16,i)/1000;% + 1562; %1562 starts the curve in a sensible position
    %Tidal, Onshore, Offshore, Geothermal, Wave
    GR([8 10 11 13 14],i) = G([15 17 18 21 22],i)/1000;
    %Total primary energy use per resource:
    TPED(:,i) = GR(:,i); 
    %--------Reevaluate cost components of the LCOE
end
for i = 1:NWR

    %------
    %k = 1: Fuel costs (fossil + nuclear) depends on cumulative generation
    k = (CSCType==1);
    %Increments in price add up to fuel costs of power stations ($/GJ -> $/MWh)
    CostsOut(k,5,i) = CostsOut(k,5,i) + (POut(j(k),i) - P(j(k),i))*3.6./Efficiency(k);

    %------
    %k = 0: Capacity factors (wind, wave, solar) depends on total generation
    %   Note: capacity factor changes prop to the inverse of the cost curve
    k = (CSCType==0);
    CFc = CSCinterp1N(CSC_Q(:,j(k),i),CSC_C(:,j(k),i),GR(j(k),i)');
    if CFc > 0
        CostsOut(k,11,i) = 1./CFc;
    else
        CostsOut(k,11,i) = 9999999;
    end
    %CostsOut(isnan(CostsOut(:,11,i)),11,i) = 1./max(CSC_C(:,j(isnan(CostsOut(:,11,i)))))';
    %Temp patch: CSP is more efficient by a factor 2 than PV
    CostsOut(20,11,i) = CostsOut(20,11,i)*2;
    %Calculate average capacity factor of operation
    %Remember that CSC_C is an inverse capacity factor!
    Gth = zeros(100,length(k));
    for ii = find(k)'
        if GR(j(ii),i) ~= 0
            Gth(:,ii) = [GR(j(ii),i)/100:GR(j(ii),i)/100:GR(j(ii),i)]';
        else
            Gth(:,ii) = zeros(100,1);
        end
    end
    CF(k,i) = 1./GR(j(k),i)'.*trapzN(Gth(:,k),1./CSCinterp1N(CSC_Q(:,j(k),i),CSC_C(:,j(k),i),Gth(:,k)));
    CF(isnan(CF)|isinf(CF))=0;
    %In cases of zero capacity (and generation), we avoid NaNs
    CF(isnan(CF(:,i))|isinf(CF(:,i)),i) = CostsOut(isnan(CF(:,i))|isinf(CF(:,i)),11,i);
    %CSP is more efficient:
    %CF(20,i) = CF(19,i)*2;
    
    %------
    %k = 2: Fuel costs (Biomass) depends on total generation
    k = (CSCType==2);
    %Interpolate through fuel cost-supply curve
    POut(j(k),i) = CSCinterp1N(CSC_Q(:,j(k),i),CSC_C(:,j(k),i),GR(j(k),i)');
    %POut(isnan(POut(:,i)),i) = max(max(CSC_C(:,j(isnan(POut(2:end,i))))))';
    if (P(j(k),i) > 0) %This is to exclude the first data point where P = 0
        CostsOut(k,5,i) = CostsOut(k,5,i) + (POut(j(k),i) - P(j(k),i))*3.6./Efficiency(k);
    end
    %CostsOut(k,5,i) = POut(j(k)+1,i)*3.6./Efficiency(k);

    %------
    %k = 3: Investment costs (hydro, geothermal, tidal, Biogas) depends on total capacity
    k = (CSCType==3);
    CostsOut(k,3,i) = CSCinterp1N(CSC_Q(:,j(k),i),CSC_C(:,j(k),i),GR(j(k),i)');
    %CostsOut(isnan(CostsOut(:,3,i)),3,i) = max(CSC_C(:,j(isnan(CostsOut(:,3,i)))))';

end




