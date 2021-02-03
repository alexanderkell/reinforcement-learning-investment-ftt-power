

% action = "Hello";

function observations = Run_FTT_Power(port, actor_hidden, critic_hidden)
    

% while true
% for runner = 1:500
% %     Initialise reinforcment learning client
%     pyenv("ExecutionMode","OutOfProcess")
%     pyenv
%     pyenv('Version', 'usr/bin/python3.6')
%     pyenv('Version',3.6)
%     disp(pyenv);
    
    import ray.rllib.env.policy_client.*
    import gym.*
    import numpy.*
    
    import reinforcement_learning_client_server.*

%     py.importlib.import_module('reinforcement_learning_client_server');

%     py.numpy.array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]).reshape(11,-1)
%     np

%     disp(py.reinforcement_learning_client_server.FTTPowerEnvironment(1, 2));
%     env = py.reinforcement_learning_client_server.FTTPowerEnvironment(1, 2);

    address = strcat('http://127.0.0.1:', num2str(port));
    client = py.ray.rllib.env.policy_client.PolicyClient(address);

    

%     eid = client.start_episode();
%     obs = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
%     obs = py.numpy.array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]).reshape(11,-1)

%     client = "holder";
%     eid = "holder";
%     obs = "holder";

% Holder for action
%     action=1;

    k = 1;
    u = 1;

    handles.PathField = 'Scenarios/';
    % handles.MaxScenarioEdit = '0'
    handles.CostsEdit = 'Assump_FTTpower_61.xlsx';
    handles.HistoricalEdit = 'FTT61x24v8.1_HistoricalData2017.xls';
    handles.CSCDataEdit = 'FTT61x24v8_CSCurvesHybrid.xlsx';


%     handles.NWR = 61;
    handles.NWR = 2;
    handles.NET = 24;
%     handles.NWR = input_NWR;
%     handles.NWR = 12;
%     handles.NET = input_NET;
%     handles.dtEdit = '0.25';
    handles.dtEdit = '0.25';
    handles.EndEdit = '2050';
%     handles.EndEdit = '2020';

    AssumptionsFileName = strcat(handles.PathField,handles.CostsEdit);
    HistoricalFileName = strcat(handles.PathField,handles.HistoricalEdit);
    CSCDataFileName = strcat(handles.PathField,handles.CSCDataEdit);
    if exist(HistoricalFileName)
%         hw = waitbar(0,'Reading input data from Excel');
%         waitbar(1/6);
        % read cost data 
        CostSheet = xlsread(AssumptionsFileName,strcat('Costs'));
        % read historical and resource data 
%         waitbar(2/6);
        HistoricalG = xlsread(HistoricalFileName,'HistoricalG');
%         waitbar(3/6);
        HistoricalE = xlsread(HistoricalFileName,'HistoricalE');
%         waitbar(4/6);
        CapacityFactors = xlsread(HistoricalFileName,'CapacityFactors');
%         waitbar(5/6);
        CSCData = xlsread(CSCDataFileName);
%         close(hw);
        handles.CostSheet = CostSheet;
        handles.HistoricalG = HistoricalG;
        handles.HistoricalE = HistoricalE;
        handles.CapacityFactors = CapacityFactors;
        handles.CSCData = CSCData;    
    else
        errordlg('Assumption file not found');
        % read cost data 
        CostSheet = '';
        % read historical and resource data 
        HistoricalG = '';
        HistoricalE = '';
        CapacityFactors = '';
        CSCData = '';
    end
%     PatchAllData_Callback(handles)

   
   [CostSheet, Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet, NET, HistoricalG, HistoricalE, CapacityFactors, CSCData, dt, NWR, EndYear] = CalcAll_Callback(handles);
%     for runner = 1:50
    num_of_runs_so_far = 0;
    while true
        
        eid = client.start_episode();

%         obs = env.reset()
        obs = py.numpy.array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        if ~isempty(CostSheet)
       %Simulation here!
            clear handles.Scenario(k);
%     handles.Scenario(k) = FTT61x24v8f(CostSheet,HistoricalG,HistoricalE,CapacityFactors,CSCData,Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet,dt,NET,NWR,EndYear);
            output = FTT61x24v8_stepped_for_rl2(CostSheet,HistoricalG,HistoricalE,CapacityFactors,CSCData,Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet,dt,NET,NWR,EndYear, client, eid, obs);
        end
        
        G_cum = sum(sum(sum(output.G)));
        U_cum = sum(sum(sum(output.U)));
        E_cum = mean(output.E,'all');
        CF_cum = sum(sum(sum(output.CF)));
    %     LCOE_cum = sum(sum(sum(sum(output.LCOE))));
        LCOE_cum = nanmean(output.LCOE,'all');
%         writematrix(output.LCOE,'LCOE.csv')
        TLCOE_cum = nanmean(output.TLCOE,'all');
        W_cum = sum(sum(sum(output.W)));
        I_cum = sum(sum(sum(output.I)));
        P_cum = nanmean(output.P,'all');
        Fcosts_cum = sum(sum(sum(output.FCosts)));
        CO2_costs_cum = sum(sum(sum(output.CO2Costs)));
        % S_lim_cum = 
        % S_lim2_cum = 

        % handles
        
        if mod(num_of_runs_so_far, 1) == 10
%             save(sprintf('data/outputs/sensitivity_analysis/output_sensitivity_analysis-actor_hidden_%s-critic_hidden_%s-%f.mat', actor_hidden, critic_hidden, floor(num_of_runs_so_far)), output)
            output_title = sprintf('data/outputs/sensitivity_analysis/output_sensitivity_analysis-actor_hidden_%s-critic_hidden_%s-%f.mat', actor_hidden, critic_hidden, floor(num_of_runs_so_far));
            save(output_title, 'output')
            
        end
        observations = [G_cum, U_cum, E_cum, CF_cum, LCOE_cum, TLCOE_cum, W_cum, I_cum, P_cum, Fcosts_cum, CO2_costs_cum];
%         LCOE_cum
        reward = -(E_cum*1000 + LCOE_cum/1000);
        client.log_returns(eid, reward)
        client.end_episode(eid, observations)
        
        num_of_runs_so_far = num_of_runs_so_far + 1;
    end
end

function [Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet] = ReadData(AssumptionsFileName,HistoricalFileName,CSCDataFileName,k,u)
%Filenames is a cell of strings

if (exist(AssumptionsFileName)&exist(HistoricalFileName)&exist(CSCDataFileName))
%     hw = waitbar(0,'Reading input data from Excel');
    % select uncertainty assumptions
    UncSheet = xlsread(AssumptionsFileName,'Costs','AH5:BQ63');
    Unc = UncSheet(:,u);
    %read policy data 
%     waitbar(1/6);
    SubSheet = xlsread(AssumptionsFileName,strcat('Sub',num2str(k-1)));
%     waitbar(2/6);
    FiTSheet = xlsread(AssumptionsFileName,strcat('FiT',num2str(k-1)));
%     waitbar(3/6);
    RegSheet = xlsread(AssumptionsFileName,strcat('Reg',num2str(k-1)));
%     waitbar(4/6);
    DPSheet = xlsread(AssumptionsFileName,strcat('DP',num2str(k-1)));
%     waitbar(5/6);
    CO2PSheet = xlsread(AssumptionsFileName,strcat('CO2P',num2str(k-1)));
%     waitbar(6/6);
    MWKASheet = xlsread(AssumptionsFileName,strcat('MWKA',num2str(k-1)));
%     close(hw);
else
    errordlg('Assumptions files not found');
    %read policy data 
    Unc = '';
    SubSheet = '';
    FiTSheet = '';
    RegSheet = '';
    DPSheet = '';
    CO2PSheet = '';
    MWKASheet = '';
end

end




%---

function [CostSheet, Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet, NET, HistoricalG, HistoricalE, CapacityFactors, CSCData, dt, NWR, EndYear] = CalcAll_Callback(handles)
%---Function that calculates all baseline+scenarios
% kk = str2num(get(handles.MaxScenarioEdit,'string'))+1;
% if ~isempty(handles.HistoricalG)
%     for k = kk
% set(handles.Slots(k),'BackgroundColor',[0 1 0]);
%Filenames
% Filename = strcat(get(handles.PathField,'string'),get(handles.CostsEdit,'string'));
% handlesOut = handles;
k=1;
u=1;
AssumptionsFileName = strcat(handles.PathField,handles.CostsEdit);
HistoricalFileName = strcat(handles.PathField,handles.HistoricalEdit);
CSCDataFileName = strcat(handles.PathField,handles.CSCDataEdit);
    %Data
    [Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet] = ReadData(AssumptionsFileName,HistoricalFileName,CSCDataFileName,k,u);
    handles.DataScenario(u).Unc = Unc;
    handles.DataScenario(k).SubSheet = SubSheet;
    handles.DataScenario(k).FiTSheet = FiTSheet;
    handles.DataScenario(k).RegSheet = RegSheet;
    handles.DataScenario(k).DPSheet = DPSheet;
    handles.DataScenario(k).CO2PSheet = CO2PSheet;
    handles.DataScenario(k).MWKASheet = MWKASheet;
    EndYear = str2num(handles.EndEdit);
    dt = str2num(handles.dtEdit);
    NET = handles.NET; NWR = handles.NWR;
    handles.EndYear = EndYear;
    handles.dt = dt;
    CostSheet = handles.CostSheet;
    HistoricalG = handles.HistoricalG;
    HistoricalE = handles.HistoricalE;
    CapacityFactors = handles.CapacityFactors;
    CSCData = handles.CSCData;    
    

end
%     set(handles.Slots(k),'BackgroundColor',[1 1 0]);
%     end
% else
%     errordlg('Press "Load History" once first');
% end

    
    
    
%     %Data
%     [CostSheet,HistoricalG,HistoricalE,CapacityFactors,CSCData,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet] = ReadData(AssumptionsFileName,HistoricalFileName,CSCDataFileName,k);
% 
%     handles.DataScenario(k).CostSheet = CostSheet;
%     handles.DataScenario(k).HistoricalG = HistoricalG;
%     handles.DataScenario(k).HistoricalE = HistoricalE;
%     handles.DataScenario(k).CapacityFactors = CapacityFactors;
%     handles.DataScenario(k).CSCData = CSCData;
%     handles.DataScenario(k).SubSheet = SubSheet;
%     handles.DataScenario(k).FiTSheet = FiTSheet;
%     handles.DataScenario(k).RegSheet = RegSheet;
%     handles.DataScenario(k).DPSheet = DPSheet;
%     handles.DataScenario(k).CO2PSheet = CO2PSheet;
%     handles.DataScenario(k).MWKASheet = MWKASheet;
%     EndYear = str2num(get(handles.EndEdit,'string'));
%     dt = str2num(get(handles.dtEdit,'string'));
%     NET = handles.NET; NWR = handles.NWR;
%     handles.EndYear = EndYear;
%     handles.dt = dt;
% 
%     if ~isempty(CostSheet)
%         %Simulation here!
%         clear handles.Scenario(k);
%         handles.Scenario(k) = FTT61x24v8f(CostSheet,HistoricalG,HistoricalE,CapacityFactors,CSCData,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet,dt,NET,NWR,EndYear);
%     end
%     
% end
% set(hObject,'value',0);
% set(handles.SavedText,'string','Not Saved','foregroundcolor','g');
% handles.ScenariosEmpty = 0;
% %Get list of variables as defined in the output structure of the calculation
% VarList = fieldnames(handles.Scenario(k));
% %Discard first few ones (t, th)
% set(handles.VarListBox,'string',VarList(3:end));
% guidata(hObject, handles);

% --- Executes on button press in LoadHistBut.
function LoadHistBut_Callback(handles)
AssumptionsFileName = strcat(handles.PathField,handles.CostsEdit);
HistoricalFileName = strcat(handles.PathField,'string',handles.HistoricalEdit);
CSCDataFileName = strcat(handles.PathField,handles.CSCDataEdit);
if exist(HistoricalFileName)
%     hw = waitbar(0,'Reading input data from Excel');
%     waitbar(1/6);
    % read cost data 
    CostSheet = xlsread(AssumptionsFileName,strcat('Costs'));
    % read historical and resource data 
%     waitbar(2/6);
    HistoricalG = xlsread(HistoricalFileName,'HistoricalG');
%     waitbar(3/6);
    HistoricalE = xlsread(HistoricalFileName,'HistoricalE');
%     waitbar(4/6);
    CapacityFactors = xlsread(HistoricalFileName,'CapacityFactors');
%     waitbar(5/6);
    CSCData = xlsread(CSCDataFileName);
%     close(hw);
    handles.CostSheet = CostSheet;
    handles.HistoricalG = HistoricalG;
    handles.HistoricalE = HistoricalE;
    handles.CapacityFactors = CapacityFactors;
    handles.CSCData = CSCData;    
else
    errordlg('Assumption file not found');
    % read cost data 
    CostSheet = '';
    % read historical and resource data 
    HistoricalG = '';
    HistoricalE = '';
    CapacityFactors = '';
    CSCData = '';
end
end



% % function PatchAllData_Callback(hObject, eventdata, handles)
% function PatchAllData_Callback(handles)
% 
% handles.RegStr = {'1 Belgium','2 Denmark','3 Germany','4 Greece','5 Spain','6 France','7 Ireland','8 Italy','9 Luxembourg','10 Netherlands','11 Austria','12 Portugal','13 Finland','14 Sweden','15 UK','16 Czech Republic','17 Estonia','18 Cyprus','19 Latvia','20 Lithuania','21 Hungary','22 Malta','23 Poland','24 Slovenia','25 Slovakia','26 Bulgaria','27 Romania','28 Norway','29 Switzerland','30 Iceland','31 Croatia','32 Turkey','33 Macedonia','34 USA','35 Japan','36 Canada','37 Australia','38 New Zealand','39 Russian Federation','40 Rest of Annex I','41 China','42 India','43 Mexico','44 Brazil','45 Argentina','46 Colombia','47 Rest of Latin America','48 Korea','49 Taiwan','50 Indonesia','51 Rest of ASEAN','52 OPEC excl Venezuela','53 Rest of world','54 Ukraine','55 Saudi Arabia','56 Nigeria','57 South Africa','58 Rest of Africa','59 Africa OPEC','60 Malaysia','61 Kazakhstan'};
% set(handles.RegListBox,'string',handles.RegStr);
% handles.TechStr = {'1- Nuclear','2- Oil','3- Coal','4- Coal + CCS','5- IGCC','6- IGCC + CCS','7- CCGT','8- CCGT + CCS','9- Solid Biomass','10- S Biomass CCS','11- BIGCC','12- BIGCC + CCS','13- Biogas','14- Biogas + CCS','15- Tidal','16- Large Hydro','17- Onshore','18- Offshore','19- Solar PV','20- CSP','21- Geothermal','22- Wave','23- Fuel Cells','24- CHP'};
% set(handles.TechListBox,'string',handles.TechStr);
% 
% %FTTTrpatchARB(XX,YY,Q,L)
% %---Function that patches areas for each technology
% %---Function that plots the data with one line per technology
% %i = get(get(handles.VariablSelector,'SelectedObject'),'string');
% % i = get(handles.VarListBox,'Value');
% % VarList = get(handles.VarListBox,'String');
% % VarName = VarList{i};
% % R = get(handles.RegListBox,'Value');
% % RegList = get(handles.RegListBox,'string');
% % T = get(handles.TechListBox,'Value');
% % TechList = get(handles.TechListBox,'string');
% k = ScenarioNumber(handles);
% RT = get(get(handles.RegTechSelector,'SelectedObject'),'string');
% 
% switch RT
%     case 'Tech'
%         TechStr = TechList(T,:);
%         if (length(R) < 4)
%             RegStr = RegList(R,:);
%         elseif length(R) == handles.NWR
%             RegStr = 'World';
%         else
%             RegStr = '';
%         end
%     case 'Regions'
%         RegStr = RegList(R,:);
%         if length(T) < 4
%             TechStr = TechList(T,:);
%         elseif length(T) == handles.NET
%             TechStr = 'All Tech';
%         else
%             TechStr = '';
%         end
% end
% 
% %Dims: (t, NET, NWR)
% if sum(((get(handles.Slots(k),'BackgroundColor')==[1 0 0]) | (get(handles.Slots(k),'BackgroundColor')==[1 1 0])))==3
%     [handles.N,handles.AH] = FigureAxes(handles);
%     switch VarName
%         case 'W'
%             switch RT
%                 case 'Regions'
%                     FTT61x24v8patch(handles.Scenario(k).Ht,sum(handles.Scenario(k).W(:,T),2),TechStr,RegStr);
%                     ylabel(handles.Scenario(k).Names.(VarName));
%                 case 'Tech'
%                     FTT61x24v8patch(handles.Scenario(k).Ht,handles.Scenario(k).W(:,T),RegStr,TechStr);
%                     ylabel(handles.Scenario(k).Names.(VarName));
%             end
%         otherwise
%             if size(handles.Scenario(k).(VarName),1) == size(handles.Scenario(k).t,1)
%                 tname = 't';
%             else
%                 tname = 'Ht';
%             end
%             if ndims(handles.Scenario(k).(VarName))==2  %Means it's missing the NET dimension
%                 FTT61x24v8patch(handles.Scenario(k).Ht,handles.Scenario(k).(VarName)(:,R),RegStr,RegStr);
%                 ylabel(handles.Scenario(k).Names.(VarName));
%             else
%                 switch RT
%                     case 'Regions'
%                         FTT61x24v8patch(handles.Scenario(k).(tname),permute(sum(handles.Scenario(k).(VarName)(:,T,R),2),[1 3 2]),TechStr,RegStr);
%                         ylabel(handles.Scenario(k).Names.(VarName));
%                     case 'Tech'
%                         FTT61x24v8patch(handles.Scenario(k).(tname),permute(sum(handles.Scenario(k).(VarName)(:,T,R),3),[1 2 3]),RegStr,TechStr);
%                         ylabel(handles.Scenario(k).Names.(VarName));
%                 end
%             end
%     end
% end
% end
% 
