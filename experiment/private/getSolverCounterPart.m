%% GETSOLVERCOUNTERPART
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
function type = getSolverCounterPart(solverType)

dummyVariable = org.anon.cocoa.variables.IntegerVariable(int32(1), int32(1));
dummyAgent = org.anon.cocoa.agents.VariableAgent(dummyVariable, 'dummy');
dummySolver = feval(solverType, dummyAgent);

assert(isa(dummySolver, 'org.anon.cocoa.solvers.MaxSumVariableSolver'), ...
    'EXPERIMENT:initConstraintAgents:INVALIDSOLVERTYPE', ...
    'Unexpected solver type, constraint agents only apply to MaxSum');

type = char(dummySolver.getCounterPart().getCanonicalName());

end