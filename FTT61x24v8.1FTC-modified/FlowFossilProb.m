
function Prob = FlowFossilProb(C,P)
%---function Prob = FlowFossilProb(C,P)
%---Probability function for the rate of extraction at price values
%---C is a vector cost value in the resource distribution, as in n(C,t)
%---P is a scalar, current unit price, as in the price of oil
%---Prob is between 0 and 1

%Prob = (C<P);
%P0 = 4.5;
Prob = .5-.5*erft(2*(C-P)/P);
%Prob = (P-C).^(.1).*(C<P)/P^.1;

%Prob = exp(-2*C/P)/trapz(C,exp(-2*C/P))*P;