function [C,D] = MainNaN(A,B)
%---function [C,D] = MainNaN(A,B)
%---Fonction qui enlève les NaN et les Inf d'un vecteur
%---Retourne des vecteurs moins longs, retire simplement les NaN, Inf
%---S'il y a un NaN dans A ou B à la nième position, on enlève la nième 
%---composante des vecteurs A et B et ceux-ci seront moins longs d'une unité
%---Utile pour enlever les NaN et Inf avant de faire une régression polynômiale

if length(A) ~= length(B)
   C = -1;
   D = -1;
   return;
end

%-Matrice 1 partout et des 0 aux endroits où il y a des NaN, Inf dans A ou B
NaNInf = not(isnan(A) | isinf(A) | isnan(B) | isinf(B));

C = A(find(NaNInf));
D = B(find(NaNInf));

