

function yOffset(N)
%function that reoffsets the y values of all curves in a graph
%Rescales by N, i.e. adds N to all ydata 

h = [findobj(gca,'Type','line') ; findobj(gca,'type','image') ; findobj(gca,'type','patch')];
AX = get(gca,'YLim');
for i = 1:length(h)
    set(h(i),'Ydata',get(h(i),'Ydata')+N);
end
set(gca,'YLim',AX +N);
