%% GRAPHSIZE
% *Summary of this function goes here*
%
% Detailed explanation goes here
%
%% Copyright
% * *2015 - Anonymous*
% * *Author*: Anomymous
% * *Since*: July 10, 2015
% 
%% See also:
%

%% Function Definition
function [ size ] = graphSize( edges )

if iscell(edges)
    size = sum(cellfun(@(x) graphSize(x), edges));
else
    size = max(max(edges));
end