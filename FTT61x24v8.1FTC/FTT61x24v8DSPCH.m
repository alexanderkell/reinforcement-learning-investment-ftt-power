
function [SGLB,CFLB,Shat,Shat2] = FTT61x24v8DSPCH(MC,dMC,GLB,ULB,S,CF,Curt,DD,DT)
%Function that estimates an allocation of power production between
%technologies and load bands in FTT
%The function takes marginal costs, shares of technologies and of load bands, 
%and outputs a 2D matrix of shares of technologies for each load band
%Calculates for only one regions
%MC, dMC: Matrices of marginal costs for NET technologies in NLB load bands
%RLDC: Vector of shares of load bands for NLB load bands
%S: Shares for NET technologies
%DD: Matrix of tech x load band suitability (=1 -> suitable)
%SGLB: Matrix of NET technological generation shares in NLB load bands
%   Complete breakdown of generation between tech & LBs
%NLB,NET: scalar, number of load bands, Number of tech
%NOTE: sum(sum(SGLB)) = sum(GLB(1:5)
%NOTE: SLB are shares of capacity running at full load, i.e. shares of sgeneration

NET = length(S);
NLB = length(GLB);
Ptech = zeros(NET,NLB);
Pgrid = zeros(NET,NLB);
%Complete breakdown of generation between tech & LBs, sum(sum(SLB)) = sum(GLB) for first 5 load bands
SGLB = zeros(NET,NLB);
dSGLB = ones(NET,NLB);
%Shares of dispatchable capacity (we assume that we have just the right amount)
SG = S.*~DD(:,6)/sum(S.*~DD(:,6))*sum(GLB(1:5));
%Shares of technology capacity per load band
SLB = zeros(NET,NLB);
CFLB = zeros(NET,NLB);

%Allocation mechanism: allocate the best to each band, remove this
%contribution from S, re-estimate the preferences, and repeat until S is
%depleted. The sum of SLB should approximate S and GLB depending on
%dimension

SGi = SG;
GLBi = GLB;
q = 0;
Crit = 0.001; %Convergence criterium
dMC(dMC > 5000) = 0;
%NOTE: We cannot allocate VRE generation, as they cannot change their
%capacity factor. We assume that curtailment is applied equally between VRE
%VRE (band 6) are excluded from this algorithm
%while (sum(SGi(DD(:,6) == 0)) > Crit) & (sum(GLB(1:5)) > Crit & q < 200)
while (sum(sum(dSGLB)) > Crit & q < 200)
    M0 = sum(S.*MC);
    for i = 1:NLB-1 %:-1:1 %fill bands starting from top (not VRE)
        %Technologies bid for generation time: weighted MNL.
        %Ptech is the likelihood that tech i bids for load band i
        Sig1(i)  = sqrt(sum(DD(:,i).*dMC.*dMC));
        %Fn = (1-(MC-M0)/Sig1(i)).*((1-(MC-M0)/Sig1(i)) > 0);
        Fn = (1-(MC-M0)/Sig1(i)+((MC-M0)/Sig1(i)).^2/2).*((1-(MC-M0)/Sig1(i)+((MC-M0)/Sig1(i)).^2/2) > 0);
        %Fn = exp(-(MC-M0)/Sig1(i));
        if (sum(DD(:,i).*SGi) > 0 & Sig1(i) > 0.001 & sum(DD(:,i).*SGi.*Fn) > 0)
            Ptech(:,i) = DD(:,i).*SGi.*Fn/sum(DD(:,i).*SGi.*Fn);
            %Ptech(:,i) = DD(:,i).*SGi.*exp(-(MC-M0)/Sig1(i))/sum(DD(:,i).*SGi.*exp(-(MC-M0)/Sig1(i)));
        else
            Ptech(:,i) = 0;
        end
    end
    for j = 1:NET
        %Grid operator has preferences amongst what is bid for
        %Pgrid is the likelihood that the grid accepts bids from tech j
        Sig2(j)  = sqrt(sum(DD(j,:).*dMC(j).*dMC(j)));
        if (DD(j,6) == 0 & sum(DD(j,:).*GLBi') > 0 & Sig2(j) > 0.001 & abs((MC(j)-M0)/Sig2(j)) < 50) %i.e. not VRE
            %Pgrid(j,:) = DD(j,:).*GLBi'/sum(DD(j,:).*GLBi');
            Pgrid(j,:) = DD(j,:).*GLBi'.*exp(-(MC(j)-M0)/Sig2(j))/sum(DD(j,:).*GLBi'.*exp(-(MC(j)-M0)/Sig2(j)));
        else
            Pgrid(j,:) = 0;
        end
    end
    q = q + 1;
    dSGLB = abs(min(abs((SGi*ones(1,NLB))),abs((ones(NET,1)*GLBi'))).*Pgrid.*Ptech);
    SGLB = SGLB + dSGLB;
    SGi = SGi - sum(dSGLB,2);
    GLBi = GLBi - sum(dSGLB,1)';
    if isnan(sum(SGi)) | isnan(sum(GLBi(1:5)))
        q = q;
    end

end    

%Generation in the VRE load band:
if sum(S(DD(:,6)==1).*CF(DD(:,6)==1)) > 0
    SGLB(DD(:,6)==1,6) = S(DD(:,6)==1).*CF(DD(:,6)==1)/sum(S(DD(:,6)==1).*CF(DD(:,6)==1))*GLB(6);
end

%Build capacity factor matrix
CFLB = ones(NET,1)*GLB'./ULB';
CFLB(DD(:,6)==1,6) = CF(DD(:,6)==1)*(1-Curt); %For VRE
CFLB(SGLB==0) = 1;

%Now check whether we are near to grid stability limit and establish share
%limits for each technology. Lower limits are what matters most

%Maximum limit is the sum of suitable load bands for each tech
Shat = max(DD*GLB,S); %in case a tech does not meet this, it will be forced to go that way
Shat(DD(:,6)==1) = 1; %No upper limit for variable renewables, since they constrain other tech, not the other way around.
Shat = Shat*0 + 1;

% %Lower limits:
% %Difference between availability and requirement per load band
% %Backup load band:
% GridLimit(5) = sum(S(DT(:,5)==1))*CFLB(5) - GLB(5) ;
% %Peak load band:
% GridLimit(4) = sum(S(DT(:,5)==1))*CFLB(5) + sum(S(DT(:,4)==1))*CFLB(4) - sum(GLB(4:5));
% %Upper mid band:
% GridLimit(3) =  sum(S(DT(:,5)==1))*CFLB(5) + sum(S(DT(:,4)==1))*CFLB(4) + sum(S(DT(:,3)==1))*CFLB(3) + sum(GLB(3:5));
% %Lower mid band:
% GridLimit(2) = sum(S(DT(:,5)==1))*CFLB(5) + sum(S(DT(:,4)==1))*CFLB(4) + sum(S(DT(:,3)==1))*CFLB(3) + sum(S(DT(:,2)==1))*CFLB(2) + sum(GLB(2:5));
% %Baseload band: no lower limit
% GridLimit(1) = 0;

%Lower limits:
%Difference between availability (minus already taken by other bands) and requirement per load band
%Backup load band:
CFLB2 = GLB./ULB;
GridLimit(5) = sum(S(DD(:,5)==1))*CFLB2(5) - GLB(5) ;
%Peak load band:
GridLimit(4) = sum(S(DD(:,4)==1))*CFLB2(4) - GLB(5) - GLB(4);
%Upper mid band:
GridLimit(3) = sum(S(DD(:,3)==1))*CFLB2(3) - GLB(4) - GLB(5) - GLB(3);
%Lower mid band:
GridLimit(2) = sum(S(DD(:,2)==1))*CFLB2(2) - GLB(3) - GLB(4) - GLB(5) - GLB(2);
%Baseload band: no lower limit
GridLimit(1) = 1;

Shat2 = Shat*0;
for i = 2:NLB-1
    Temp(:,i) = (DD(:,i)==1).*(S - GridLimit(i)/CFLB2(i));% - (DD(:,i)~=1);
    Temp2(:,i) = (DD(:,i)==1).*(GridLimit(i)/CFLB2(i));
end
Temp(:,1) = -1;

Shat2 = min(max(Temp')',S);
Shat2(DT(:,6)==1) = 0;
%Shat2 = Shat2*0+1;
Shat2;
Shat;



