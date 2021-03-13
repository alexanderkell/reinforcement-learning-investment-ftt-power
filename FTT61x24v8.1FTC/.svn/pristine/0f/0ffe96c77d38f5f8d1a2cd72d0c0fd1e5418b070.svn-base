function Yint = trapzN(X,Y)
%---function Yint = trapzN(X,Y)
%---Calculates trapz integration on matrix Y with matrix X
%---Note: normal trapz function does not take X as matrix
%---Calculates along vertical direction



for i = 1:size(X,2)
    if size(X,1) == 1
        Yint(:,i) = Y(:,i);
    else
        Yint(:,i) = trapz(X(:,i),Y(:,i));
    end
end
