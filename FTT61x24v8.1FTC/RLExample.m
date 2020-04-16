% function [Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet] = ReadData(AssumptionsFileName,HistoricalFileName,CSCDataFileName,k,u)
% %Filenames is a cell of strings
% 
% if (exist(AssumptionsFileName)&exist(HistoricalFileName)&exist(CSCDataFileName))
%     hw = waitbar(0,'Reading input data from Excel');
%     % select uncertainty assumptions
%     UncSheet = xlsread(AssumptionsFileName,'Costs','AH5:BQ63');
%     Unc = UncSheet(:,u);
%     %read policy data 
%     waitbar(1/6);
%     SubSheet = xlsread(AssumptionsFileName,strcat('Sub',num2str(k-1)));
%     waitbar(2/6);
%     FiTSheet = xlsread(AssumptionsFileName,strcat('FiT',num2str(k-1)));
%     waitbar(3/6);
%     RegSheet = xlsread(AssumptionsFileName,strcat('Reg',num2str(k-1)));
%     waitbar(4/6);
%     DPSheet = xlsread(AssumptionsFileName,strcat('DP',num2str(k-1)));
%     waitbar(5/6);
%     CO2PSheet = xlsread(AssumptionsFileName,strcat('CO2P',num2str(k-1)));
%     waitbar(6/6);
%     MWKASheet = xlsread(AssumptionsFileName,strcat('MWKA',num2str(k-1)));
%     close(hw);
% else
%     errordlg('Assumptions files not found');
%     %read policy data 
%     Unc = '';
%     SubSheet = '';
%     FiTSheet = '';
%     RegSheet = '';
%     DPSheet = '';
%     CO2PSheet = '';
%     MWKASheet = '';
% end
% 
% 
% function CalcScenario_Callback(hObject, eventdata, handles)
% %---Function that calculates the scenario
% [k,u] = ScenarioNumber(handles);
% 
% set(handles.Slots(k),'BackgroundColor',[0 1 0]);
% %Filenames
% Filename = strcat(get(handles.PathField,'string'),get(handles.CostsEdit,'string'));
% handlesOut = handles;
% AssumptionsFileName = strcat(get(handles.PathField,'string'),get(handles.CostsEdit,'string'));
% HistoricalFileName = strcat(get(handles.PathField,'string'),get(handles.HistoricalEdit,'string'));
% CSCDataFileName = strcat(get(handles.PathField,'string'),get(handles.CSCDataEdit,'string'));
% 
% if ~isempty(handles.HistoricalG)
%     %Data
%     SW = 0; %for debugging 
%     if SW == 0 %Normal operation
%         [Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet] = ReadData(AssumptionsFileName,HistoricalFileName,CSCDataFileName,k,u);
%         handles.DataScenario(u).Unc = Unc;
%         handles.DataScenario(k).SubSheet = SubSheet;
%         handles.DataScenario(k).FiTSheet = FiTSheet;
%         handles.DataScenario(k).RegSheet = RegSheet;
%         handles.DataScenario(k).DPSheet = DPSheet;
%         handles.DataScenario(k).CO2PSheet = CO2PSheet;
%         handles.DataScenario(k).MWKASheet = MWKASheet;
%     else %For debugging
%         Unc = handles.DataScenario(u).Unc;
%         SubSheet = handles.DataScenario(k).SubSheet;
%         FiTSheet = handles.DataScenario(k).FiTSheet;
%         RegSheet = handles.DataScenario(k).RegSheet;
%         DPSheet = handles.DataScenario(k).DPSheet;
%         CO2PSheet = handles.DataScenario(k).CO2PSheet;
%         MWKASheet = handles.DataScenario(k).MWKASheet;
%     end
%     EndYear = str2num(get(handles.EndEdit,'string'));
%     dt = str2num(get(handles.dtEdit,'string'));
%     NET = handles.NET; NWR = handles.NWR;
%     handles.EndYear = EndYear;
%     handles.dt = dt;
%     CostSheet = handles.CostSheet;
%     HistoricalG = handles.HistoricalG;
%     HistoricalE = handles.HistoricalE;
%     CapacityFactors = handles.CapacityFactors;
%     CSCData = handles.CSCData;    
% else
%     errordlg('Press "Load History" once first');
% end



k = 1;
u = 1;
AssumptionsFileName = 'Assump_FTTpower_61.xlsx';
HistoricalFileName = 'FTT53x24v7_Base.cdf';
CSCDataFileName = 'FTT61x24v8_CSCurvesHybrid.xlsx';
ReadData(AssumptionsFileName, HistoricalFileName, CSCDataFileName, k, u)



% handles

% FTT61x24v8f