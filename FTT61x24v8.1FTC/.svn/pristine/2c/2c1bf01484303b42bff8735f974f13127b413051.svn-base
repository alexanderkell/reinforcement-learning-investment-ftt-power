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


%---function P = Inverse_Price(D,n0,C,P0,nu)
%---Function to calculate a price path from a demand and resource density
%---D: Demand (scalar) in EJ
%---n0: resource density function of C (vector) (in EJ)
%---C: cost axis (vector) (in $/GJ)
%---P0: starting price value (scalar)
function P = Inverse_Price(D,n0,C,P0,nu)


%     options = optimset('Display','off');
%     function Out = DiffD(Pfun)
%         Out = abs(trapz(C,nu*n0.*FlowFossilProb(C,Pfun))-D);
%         %Out = abs(sum(nu*n0.*FlowFossilProb(C,Pfun))-D);
%     end
%     P = fminsearch(@DiffD,P0,options);

    dFdt = 0;
    dC = C(2)-C(1);
    P = P0;
    while (abs((dFdt-D)/D) > 0.001 & P < 1000)
        dFdt = 0;
        %Supply from each cost range
        dQdt = nu*n0.*(.5-.5*tanh(1.25*2*(C-P)/P));
        %Total supply added from all cost ranges
        dFdt = sum(dQdt)*dC;
        %New price guess
        if (dFdt < D)
            %Increase the marginal cost
            P = P*(1 + abs((dFdt - D)/D)/5);
        else
            %Decrease the marginal cost
            P = P/(1 + abs((dFdt - D)/D)/5);
        end
    end

%     dFdt = 0
%     Out = D(I)
%     d1oP(I) = 1 / P(I)
%     
%     DO WHILE (ABS((dFdt-D(I))/D(I)) > .001)
%         !Sum total supply dFdt from all extraction cost ranges below marginal cost P
%         dFdt = 0       
%         !Uranium at global level
%             FORALL(K=1:L) tc(K) = 0.5-0.5*TANH(1.25*2*(HistC(I,K)-P(I))/P(I))
%             !$OMP PARALLEL DO PRIVATE(dQdt)
%             DO J =1, NR
%                !FORALL(K=1:L) dQdt(K) = MPTR(I,J)*BCSC(I,J,4+K)*tc(K) 
%                !UC/OJ test to improve speed by rewriting above 1/2/16
%                dQdt = MPTR(I,J) * BCSC(I,J,5:L+4) * tC
%                dFdthold(J) = sum(dQdt)*dC
%             ENDDO
%             !$OMP END PARALLEL DO
%            dFdt= sum(dFdthold(1:NR)) 
%         
%         !Work out price
%         !Difference between supply and demand
%         IF (dFdt < D(I)) THEN
%             !Increase the marginal cost
%             P(I) = P(I)*(1.0+ABS(dFdt-D(I))/D(I)/5)
%         ELSE
%             !Decrease the marginal cost
%             P(I) = P(I)/(1.0+ABS(dFdt-D(I))/D(I)/5)
%         ENDIF


end