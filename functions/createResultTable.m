%% CREATERESULTTABLE
% *Summary of this function goes here*
%
% Detailed explanation goes here
%
%% Copyright
% * *2016 - Anonymous*
% * *Author*: Anomymous
% * *Since*: January 30, 2016
% 
%% See also:
%

%% Function Definition
function varargout = createResultTable(exp, options)

if numel(exp) == 1
    exp = struct('results', exp);
end

for i = 1:numel(exp)
    A(i) = analyzeResults(exp(i).results);
end

header = sprintf('\\begin{tabular}{lccccc}\n\t\\toprule\n\t% -32s & % -7s & % -7s & % -7s & % -7s & % -7s\\\\ \\midrule', 'Algorithm', 'I', 'S', 'M', 'E', 'T');

algos = fieldnames(A)';
algoStr = cell(size(algos));
for i = 1:numel(algos)
    algoResults = [A.(algos{i})];
    
    if all([algoResults.iterations] == 1)
        iterStr = '& N/A    ';
    else
        iterStr = sprintf(repmat('&% -7d ', 1, numel(algoResults)), round([algoResults.iterations]));
    end
    
    costStr = sprintf(repmat('&% -7d ', 1, numel(algoResults)), round([algoResults.costs]));
    msgsStr = sprintf(repmat('&% -7d ', 1, numel(algoResults)), round([algoResults.msgs]));
    evalStr = sprintf(repmat('&% -7d ', 1, numel(algoResults)), round([algoResults.evals]));
    timeStr = sprintf(repmat('&% -6.1f ', 1, numel(algoResults)), [algoResults.times]);
    algoStr{i} = sprintf('% -32s %s %s %s %s %s', strrep(algos{i}, '_', '\_'), iterStr, costStr, msgsStr, evalStr, timeStr);
end

str = [header sprintf('\n\t%s \\\\', algoStr{:}) sprintf(' \\bottomrule\n\\end{tabular}')];

if (nargin > 1 && isstruct(options))
    doExport = getSubOption(false, 'logical', options, 'export', 'dotables');
    outputfolder = getSubOption(pwd, 'char', options, 'export', 'tables');
    expname = getSubOption('experiment', 'char', options, 'export', 'name');
    
    if doExport
        fid = fopen(fullfile(outputfolder, sprintf('%s.tex', expname)), 'w');
        fprintf(fid, '%s\n', str);
        fclose(fid);
    end
end

if nargout > 0
    varargout{1} = str;
elseif ~exist('doExport', 'var') || ~doExport
    fprintf('%s\n', str);
end