function fiSYS = import_fiSYS(filename, dataLines)
%IMPORTFILE Import data from a text file
%  UNTITLED = IMPORTFILE(FILENAME) reads data from text file FILENAME
%  for the default selection.  Returns the numeric data.
%
%  UNTITLED = IMPORTFILE(FILE, DATALINES) reads data for the specified
%  row interval(s) of text file FILENAME. Specify DATALINES as a
%  positive scalar integer or a N-by-2 array of positive scalar integers
%  for dis-contiguous row intervals.
%
%  Example:
%  Untitled = importfile("G:\Shared drives\OBSL\Research Projects\Wearables\Cuffless Blood Pressure Patch\Data\Subject 4\Dynamic Data\2024-02-09_13.53.23 (csv) Raw\2024-02-09_13.53.23 fiSYS.csv", [9, Inf]);
%
%  See also READTABLE.
%
% Auto-generated by MATLAB on 15-Feb-2024 11:10:18

%% Input handling

% If dataLines is not specified, define defaults
if nargin < 2
    dataLines = [9, Inf];
end

%% Set up the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 4, "Encoding", "UTF-8");

% Specify range and delimiter
opts.DataLines = dataLines;
opts.Delimiter = ";";

% Specify column names and types
opts.VariableNames = ["Timesec", "fiSYSmmHg", "Var3", "Var4"];
opts.SelectedVariableNames = ["Timesec", "fiSYSmmHg"];
opts.VariableTypes = ["double", "double", "string", "string"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Var3", "Var4"], "WhitespaceRule", "preserve");
opts = setvaropts(opts, ["Var3", "Var4"], "EmptyFieldRule", "auto");

% Import the data
fiSYS = readtable(filename, opts);

%% Convert to output type
fiSYS = table2array(fiSYS);
end