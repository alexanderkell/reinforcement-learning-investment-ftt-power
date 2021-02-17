

function yRescale(N)
%function that rescales the y values of all curves in a graph
%Rescales by N, i.e. divides by N

h = [findobj(gca,'Type','line') ; findobj(gca,'type','image') ; findobj(gca,'type','patch') ; findobj(gca,'type','hggroup')];
AX = get(gca,'XLim');
for i = 1:length(h)
    set(h(i),'Xdata',get(h(i),'Xdata')/N);
end
set(gca,'XLim',AX/N);
