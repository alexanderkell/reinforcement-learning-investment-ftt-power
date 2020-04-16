
function FTTSaveCDF(Filename,Scenario)
%---Function that saves a scenario structure in a Common Data Format file
%---The structure Scenario can have any number of fields, this will save
%---all fields

%Get structure field names
Vars = fieldnames(Scenario);

%Create new or overwrite old CDF file
cdfwrite(Filename,{Vars{1},Scenario.(Vars{1})},'WriteMode','overwrite');
for i = 2:length(Vars)
    %Append remaining parts to the file
    cdfwrite(Filename,{Vars{i},Scenario.(Vars{i})},'WriteMode','append');
end