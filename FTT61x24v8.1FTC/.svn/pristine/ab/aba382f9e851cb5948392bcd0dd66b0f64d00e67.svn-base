

function xOffset(N)
%function that reoffsets the y values of all curves in a graph
%Rescales by N, i.e. adds N to all ydata 

h = [findobj(gca,'Type','line') ; findobj(gca,'type','image') ; findobj(gca,'type','patch')];
AX = get(gca,'XLim');
for i = 1:length(h)
    set(h(i),'Xdata',get(h(i),'Xdata')+N);
end
set(gca,'XLim',AX +N);
