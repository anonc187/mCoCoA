%% ISGRAPH
% *Summary of this function goes here*
%
% Detailed explanation goes here
%
%% Copyright
% * *2016 - Anonymous*
% * *Author*: Anomymous
% * *Since*: August 12, 2016
% 
%% See also:
%

%% Function Definition
function valid = isGraph(edges)

if iscell(edges)
    edges = vertcat(edges{:});
end

valid = size(edges, 2) == 2;

