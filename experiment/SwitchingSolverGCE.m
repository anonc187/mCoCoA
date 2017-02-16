%% SwitchingSolverGCE
% *Summary of this class goes here*
%
% Detailed explanation goes here
%
%% Copyright
% * *2016 - Anonymous*
% * *Author*: Anomymous
% * *Since*: October 7, 2016 (*30*)
%
%% See also:
%

%% Class definition:
classdef SwitchingSolverGCE < GraphColoringExperiment
    
    %% Public methods
    methods
        
        %% SWITCHINGSOLVERGCE - Object constructor
        function obj = SwitchingSolverGCE(edges, options)
            % Parse all options
            obj = obj@GraphColoringExperiment(edges, options);
            
            ExceptOn(~isempty(strfind(obj.iterSolverType, 'MaxSum')), ...
                'SWITCHINGSOLVERGCE:UNDEFINED', ...
                'This experiment is not suited for constraint agents');
        end % SWITCHINGSOLVERGCE
        
        %% INIT - build the variables and agents
        function init(obj)
            obj.initVariables();
            obj.initConstraints();
            
            ExceptOn(~isempty(strfind(obj.iterSolverType, 'MaxSum')), ...
                'SWITCHINGSOLVERGCE:INIT:UNDEFINED', ...
                'This experiment is not suited for constraint agents');
            
            obj.assignAgentProperties();
        end % INIT
        
        %% SWITCHSOLVER - Switch solver
        function switchSolver(obj)
            if ~isempty(obj.initSolverType)
                for i = 1:numel(obj.agent)
                    obj.agent{i}.setSolver(feval(obj.iterSolverType, obj.agent{i}));
                end
            end
        end % SWITCHSOLVER
    end
    
    %% Protected methods
    methods (Access = protected)

        %% INITVARIABLES - Initialize variables and agents
        function initVariables(obj)
            nagents = obj.graph.size;
            for i = 1:nagents
                varName = sprintf('variable%05d', i);
                agentName = sprintf('agent%05d', i);
                
                obj.variable{i} = org.anon.cocoa.variables.IntegerVariable(int32(1), int32(obj.nColors), varName);
                obj.agent{i} = org.anon.cocoa.agents.SolverAgent(obj.variable{i}, agentName);
                
                if ~isempty(obj.initSolverType)
                    obj.agent{i}.setSolver(feval(obj.initSolverType, obj.agent{i}));
                else
                    obj.agent{i}.setSolver(feval(obj.iterSolverType, obj.agent{i}));
                end
                
%                 obj.agent{i}.setSolver(feval(obj.initSolverType, obj.agent{i}));
            end
        end % INITVARIABLES
        
        %% INITCONSTRAINTAGENTS - Add constraint agents (MAXSUM only)
        function initConstraintAgents(~)
            error('SWITCHINGSOLVERGCE:INITCONSTRAINTAGENTS:UNDEFINED', ...
                'This experiment is not suited for constraint agents');
        end % INITCONSTRAINTAGENT
    end % Private methods
end
