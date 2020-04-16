function Y = CSCinterp1N(X0,Y0,X)
%---function Y = interp1N(X0,Y0,X)
%---Fonction qui calcule un ensemble d'interpolations
%---colonne par colonne de X0 et Y0 aux points des colonnes de X
%---X ne doit PAS contenir ni de NaN, ni de Inf !!!

if size(X,2) == 1
    X = X*ones(1,size(Y0,2));
end
if size(X0,2) == 1
    X0 = X0*ones(1,size(Y0,2));
end
Y = X*0;
%Note: this interp gives the last or first value if X falls outside range,
%as in E3ME
for i = 1:size(Y0,2)
    [X_NaN,Y_NaN] = MainNaN(X0(:,i),Y0(:,i));
    if length(Y_NaN) > 1
        Y(:,i) = interp1(X_NaN, Y_NaN, X(:,i));        
        if any(X(:,i) > max(X_NaN))
            Y(X(:,i) > max(X_NaN),i) = max(Y_NaN);
        end
        if any(X(:,i) < min(X_NaN))
            Y(X(:,i) < min(X_NaN),i) = min(Y_NaN);
        end
    else
        Y(:,i) = NaN;
    end
end