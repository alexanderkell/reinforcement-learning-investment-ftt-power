function FTT53x24v7patch(X,Y,Q,L)
%---Function that patches data from ETM24 
%---Adds appropriate legend
%X = X(2:end,:);
%Y = Y(2:end,:);

cla;
NnonNaN = size(Y,1)-max(sum(isnan(Y)));
XX = X(1:NnonNaN,:);
YY = Y(1:NnonNaN,:);
Col = [[0 0 1]; [0 .5 0]; [0 0 0]; [.3 .3 .3]; [.6 .6 .6]; [.8 .8 .8]; [1 .3 1]; [.6 .3 1]; [1 0 0]; [.7 0 0]; [1 .5 .5]; [1 .8 .8]];
Col = [Col; [1 1 0]; [1 1 .4]; [.3 .3 1]; [.6 .6 1]; [0 1 0]; [.3 1 .3]; [1 .8 0]; [1 .6 0]; [.8 .5 .3]; [.3 .5 .8]; [1 0 1]; [1 .5 1];];
patch([[min(XX) max(XX)]' ; XX(end:-1:1)],[[0 0]' ; YY(end:-1:1,1)],Col(1,:));
hold on;
if size(YY,2) > 1
    for i = 2:size(YY,2)
        if sum(YY(:,1:i)) > 0
            patch([XX ; XX(end:-1:1)],[sum(YY(:,1:i-1),2) ; sum(YY(end:-1:1,1:i-1),2)+YY(end:-1:1,i)],Col(mod(i-1,24)+1,:),'edgecolor','none');
        else
            patch([XX ; XX(end:-1:1)],[sum(YY(:,1:i-1),2) ; sum(YY(end:-1:1,1:i-1),2)+YY(end:-1:1,i)+max(max(YY))/1e6],Col(mod(i-1,24)+1,:),'edgecolor','none');
        end
    end
end
hold off;
%set(gcf,'position',[584 192 925 624]);
set(gca,'xlim',[min(X) max(X)]);
zoom reset;
if max(sum(YY,2))-1 < .0001 & max(sum(YY,2))-1 > -.0001
    set(gca,'ylim',[0 1]);
end
LL = get(gca,'ylim');
hold on; 
plot([2013 2013],LL,'--','color',[.5 .5 .5]);
plot([2017 2017],LL,'--','color',[.5 .5 .5]);
zoom reset;
set(gca,'fontsize',16,'box','on');
h = legend(L);
set(h,'fontsize',8,'fontweigh','normal','location','NorthEastOutside');
title(Q)
hold off;
