
function Scenario = FTTLoadCDF(Filename)
%Function that loads data from a CDF file written by FTTSaveCDF

%Load data from CDF file: 
%  data is a cell array of data variables
%  info is a cell array of variable information such as the name
[data,info] = cdfread(Filename);

%Cell array of variable names (first column)
Vars = info.Variables(:,1);

%Reconstruct the FTT data structure with names
for i = 1:length(Vars)
    Scenario.(Vars{i}) = data{i};
end