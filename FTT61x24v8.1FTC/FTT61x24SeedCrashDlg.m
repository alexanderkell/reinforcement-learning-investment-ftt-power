
function FTT53x24SeedCrashDlg(Scenario)
[tt{1}, NN{1}, Pos{1}] = FTTSeedCrash(Scenario.S);
[tt{2}, NN{2}, Pos{2}] = FTTSeedCrash(Scenario.G(39:end,:,:));
[tt{3}, NN{3}, Pos{3}] = FTTSeedCrash(Scenario.U);
[tt{4}, NN{4}, Pos{4}] = FTTSeedCrash(Scenario.CF);
[tt{5}, NN{5}, Pos{5}] = FTTSeedCrash(Scenario.E(39:end,:,:));
[tt{6}, NN{6}, Pos{6}] = FTTSeedCrash(Scenario.LCOE);
[tt{7}, NN{7}, Pos{7}] = FTTSeedCrash(Scenario.I);
[tt{8}, NN{8}, Pos{8}] = FTTSeedCrash(Scenario.FCosts);
[tt{9}, NN{9}, Pos{9}] = FTTSeedCrash(Scenario.ICosts);
[tt{10}, NN{10}, Pos{10}] = FTTSeedCrash(Scenario.CFCosts);

k = find(cell2mat(tt)==min(cell2mat(tt)));

if (~isempty(k))% & length(k) == 1)
    RegList = {'1 Belgium','2 Denmark','3 Germany','4 Greece','5 Spain','6 France','7 Ireland','8 Italy','9 Luxembourg','10 Netherlands','11 Austria','12 Portugal','13 Finland','14 Sweden','15 UK','16 Czech Republic','17 Estonia','18 Cyprus','19 Latvia','20 Lithuania','21 Hungary','22 Malta','23 Poland','24 Slovenia','25 Slovakia','26 Bulgaria','27 Romania','28 Norway','29 Switzerland','30 Iceland','31 Croatia','32 Turkey','33 Macedonia','34 USA','35 Japan','36 Canada','37 Australia','38 New Zealand','39 Russian Federation','40 Rest of Annex I','41 China','42 India','43 Mexico','44 Brazil','45 Argentina','46 Colombia','47 Rest of Latin America','48 Korea','49 Taiwan','50 Indonesia','51 Rest of ASEAN','52 OPEC excl Venezuela','53 Rest of world'};
    TechList = {'1- Nuclear','2- Oil','3- Coal','4- Coal+CCS','5- IGCC','6- IGCC+CCS','7- CCGT','8- CCGT+CCS','9- Solid Biomass','10- S Biomass+CCS','11- BIGCC','12- BIGCC+CCS','13- Biogas','14- Biogas+CCS','15- Tidal','16- Hydro','17- Onshore','18- Offshore','19- Solar PV','20- CSP','21- Geothermal','22- Wave','23- Fuel Cells','24- CHP'};
    VarList = {'S, ','HG, ','U, ','CF, ','E, ','LCOE, ','I, ','FCosts, ','ICosts, ','CFCosts, ','CO2Costs'};
    %Matrix of strings of error positions
    Strs = [RegList(Pos{k(1)}(:,2))' TechList(Pos{k(1)}(:,1))'];

    MSG1 = sprintf('\n%s\n\n','FTT crashes at the following positions:');
    MSG2 = sprintf('t = \t%s\t\n\n',num2str(2008+tt{k(1)}/4));
    MSG3 = sprintf('Variable = \t%s\t\n\n',strcat(VarList{k}));
    MSG4 = '';
    for i = 1:NN{k(1)}
        MSG4 = [MSG4 sprintf('%s    %s\n',Strs{i,1},Strs{i,2})];
    end
    Button = questdlg([MSG1 MSG2 MSG3 MSG4],'Crash tracking','Ok','Details','Ok');
    if strcmp(Button,'Details')
        MSG5 = sprintf('\nNumber of NaNs in each variable at time t = %s:\n\nVariables  t     N\n',num2str(2008+tt{k}));
        MSG6 = '';
        VL = char(VarList);
        ttL = [char(num2str(cell2mat(tt')))];
        NNL = [char(num2str(cell2mat(NN')))];
        %NWRL = ['WR';char(num2str(cell2mat(Pos{:}(:,1))))];
        %NETL = ['ET';char(num2str(cell2mat(Pos{:}(:,2))))];
        for i = 1:10
            MSG6 = [MSG6 sprintf('%s   %s   %s\n',VL(i,:),ttL(i,:),NNL(i,:))];
        end
        %questdlg([MSG5 MSG6],'Crash tracking','Ok','Ok');
        set(findobj(msgbox([MSG1 MSG2 MSG3 MSG4 MSG5 MSG6]),'type','text'),'fontname','fixedwidth','fontsize',10)
    end

else
    warndlg('FTT did not crash in this run','Crash tracking');
end