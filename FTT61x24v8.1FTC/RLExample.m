


k = 1;
u = 1;


handles.PathField = 'Scenarios/';
% handles.MaxScenarioEdit = '0'
handles.CostsEdit = 'Assump_FTTpower_61.xlsx';
handles.HistoricalEdit = 'FTT61x24v8.1_HistoricalData2017.xls';
handles.CSCDataEdit = 'FTT61x24v8_CSCurvesHybrid.xlsx';

handles.NWR = 61;
handles.NET = 24;
handles.dtEdit = '0.25';
handles.EndEdit = '2050';

AssumptionsFileName = strcat(handles.PathField,handles.CostsEdit);
HistoricalFileName = strcat(handles.PathField,handles.HistoricalEdit);
CSCDataFileName = strcat(handles.PathField,handles.CSCDataEdit);
if exist(HistoricalFileName)
    hw = waitbar(0,'Reading input data from Excel');
    waitbar(1/6);
    % read cost data 
    CostSheet = xlsread(AssumptionsFileName,strcat('Costs'));
    % read historical and resource data 
    waitbar(2/6);
    HistoricalG = xlsread(HistoricalFileName,'HistoricalG');
    waitbar(3/6);
    HistoricalE = xlsread(HistoricalFileName,'HistoricalE');
    waitbar(4/6);
    CapacityFactors = xlsread(HistoricalFileName,'CapacityFactors');
    waitbar(5/6);
    CSCData = xlsread(CSCDataFileName);
    close(hw);
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

output = CalcAll_Callback(handles)

% handles

% FTT61x24v8f


function [Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet] = ReadData(AssumptionsFileName,HistoricalFileName,CSCDataFileName,k,u)
%Filenames is a cell of strings

if (exist(AssumptionsFileName)&exist(HistoricalFileName)&exist(CSCDataFileName))
    hw = waitbar(0,'Reading input data from Excel');
    % select uncertainty assumptions
    UncSheet = xlsread(AssumptionsFileName,'Costs','AH5:BQ63');
    Unc = UncSheet(:,u);
    %read policy data 
    waitbar(1/6);
    SubSheet = xlsread(AssumptionsFileName,strcat('Sub',num2str(k-1)));
    waitbar(2/6);
    FiTSheet = xlsread(AssumptionsFileName,strcat('FiT',num2str(k-1)));
    waitbar(3/6);
    RegSheet = xlsread(AssumptionsFileName,strcat('Reg',num2str(k-1)));
    waitbar(4/6);
    DPSheet = xlsread(AssumptionsFileName,strcat('DP',num2str(k-1)));
    waitbar(5/6);
    CO2PSheet = xlsread(AssumptionsFileName,strcat('CO2P',num2str(k-1)));
    waitbar(6/6);
    MWKASheet = xlsread(AssumptionsFileName,strcat('MWKA',num2str(k-1)));
    close(hw);
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

function output_simulation = CalcAll_Callback(handles)
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
if ~isempty(CostSheet)
    %Simulation here!
    clear handles.Scenario(k);
%     handles.Scenario(k) = FTT61x24v8f(CostSheet,HistoricalG,HistoricalE,CapacityFactors,CSCData,Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet,dt,NET,NWR,EndYear);
    output_simulation = FTT61x24v8f(CostSheet,HistoricalG,HistoricalE,CapacityFactors,CSCData,Unc,SubSheet,FiTSheet,RegSheet,DPSheet,CO2PSheet,MWKASheet,dt,NET,NWR,EndYear);
end
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
    hw = waitbar(0,'Reading input data from Excel');
    waitbar(1/6);
    % read cost data 
    CostSheet = xlsread(AssumptionsFileName,strcat('Costs'));
    % read historical and resource data 
    waitbar(2/6);
    HistoricalG = xlsread(HistoricalFileName,'HistoricalG');
    waitbar(3/6);
    HistoricalE = xlsread(HistoricalFileName,'HistoricalE');
    waitbar(4/6);
    CapacityFactors = xlsread(HistoricalFileName,'CapacityFactors');
    waitbar(5/6);
    CSCData = xlsread(CSCDataFileName);
    close(hw);
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