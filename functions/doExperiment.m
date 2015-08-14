function results = doExperiment(edges, options)
%#ok<*AGROW>

%% Parse the options
nColors = getSubOption(uint16(3), 'uint16', options, 'ncolors');
nIterations = getSubOption(uint16(10), 'uint16', options, 'nIterations');
solverType = getSubOption('org.anon.cocoa.solvers.UniqueFirstCooperativeSolver', ...
    'char', options, 'solverType');
costFunctionType = getSubOption('org.anon.cocoa.costfunctions.LocalInequalityConstraintCostFunction', ...
    'char', options, 'costFunction');
maxtime = getSubOption(180, 'double', options, 'maxTime'); %maximum delay in seconds
waittime = getSubOption(1/2, 'double', options, 'waitTime'); %delay between checks
agentProps = getSubOption(struct, 'struct', options, 'agentProperties');
keepCostGraph = getSubOption(false, 'logical', options, 'keepCostGraph');

nagents = graphSize(edges);

%% Setup the agents and variables
org.anon.cocoa.ExperimentControl.ResetExperiment();

fields = fieldnames(agentProps);
for i = 1:nagents
    varName = sprintf('variable%05d', i);
    agentName = sprintf('agent%05d', i);
    
    variable(i) = org.anon.cocoa.variables.IntegerVariable(int32(1), int32(nColors), varName);
    if strcmp(solverType, 'org.anon.cocoa.solvers.FBSolver')
        agent(i) = org.anon.cocoa.agents.OrderedSolverAgent(agentName, variable(i));
        costfun(i) = org.anon.cocoa.costfunctions.InequalityConstraintCostFunction(agent(i).getSequenceID());
    else
        agent(i) = org.anon.cocoa.agents.LocalSolverAgent(agentName, variable(i));
        costfun(i) = feval(costFunctionType, agent(i));
    end

    solver(i) = feval(solverType, agent(i), costfun(i));
    
    agent(i).setSolver(solver(i));

    for f = fields'
        prop = f{:};
        if numel(agentProps.(prop)) == 1
            agent(i).set(prop, agentProps.(prop));
        elseif numel(agentProps.(prop)) >= nagents
            agent(i).set(prop, agentProps.(prop)(i));
        else
            error('DOEXPERIMENT:INCORRECTPROPERTYCOUNT', ...
                'Incorrect number of properties, must be either 1 or number of agents (%d)', ...
                nagents);
        end
    end
    
    variable(i).clear();
    agent(i).reset();
end

%% Add children and parent if required
if isa(agent(1), 'org.anon.cocoa.agents.OrderedAgent')
    % We assume a static final ordering where each agent has just one child
    % Therefore the algorithm is never really asynchronous
    for i = 1:(nagents-1)
        agent(i).addChild(agent(i+1));
    end
    
    for i = 2:nagents
        agent(i).setParent(agent(i-1));
    end
end

%% Add the constraints
for i = 1:nagents
    k = find(edges(:,1) == i);
    if isempty(k)
        continue;
    end
    
    a = agent(i);
    %s = solver(i);
    for v = edges(k,2)'
        if strcmp(solverType, 'org.anon.cocoa.solvers.FBSolver')
            costfun(i).addConstraintIndex(agent(v).getSequenceID());
            costfun(v).addConstraintIndex(agent(i).getSequenceID());
            %s.addConstraint(agent(v));
            %solver(v).addConstraint(a);
        else
            a.addToNeighborhood(agent(v));
            agent(v).addToNeighborhood(a);
        end
    end
end

%% Init all agents
for i = nagents:-1:1
    agent(i).init();
    pause(.01);
end

%% Start the experiment

startidx = randi(nagents);
a = solver(startidx);
if isa(a, 'org.anon.cocoa.solvers.GreedyCooperativeSolver')
    msg = org.anon.cocoa.messages.HashMessage('GreedyCooperativeSolver:PickAVar');
    a.push(msg);
elseif isa(a, 'org.anon.cocoa.solvers.UniqueFirstCooperativeSolver')
    msg = org.anon.cocoa.messages.HashMessage('UniqueFirstCooperativeSolver:PickAVar');
    a.push(msg);
elseif isa(a, 'org.anon.cocoa.solvers.GreedyLocalSolver')
    msg = org.anon.cocoa.messages.HashMessage('GreedyLocalSolver:AssignVariable');
    a.push(msg);
end

%% Do the iterations

if isa(solver(1), 'org.anon.cocoa.solvers.IterativeSolver')
    bestSolution = getCost(costfun, variable, agent);

    if keepCostGraph; costList = bestSolution; end
    
    % Iteratre for AT LEAST nIterations
    countDown = nIterations;
    while countDown > 0
        countDown = countDown - 1;
        for j = 1:nagents
            solver(j).tick();
        end
        
        cost = getCost(costfun, variable, agent);
        if keepCostGraph; costList = [costList cost]; end
        
        % If a better solution is found, reset countDown
        if cost < bestSolution
            countDown = nIterations;
            bestSolution = cost;
        end
    end
end
%% Wat for the algorithms to converge

% keyboard
for t = 1:(maxtime / waittime)
% while true
    pause(waittime);
    % This loop does not really work for algorithms that run iteratively
    if variable(randi(nagents)).isSet
%         fprintf('Experiment done...\n');
        break
    end
end

%% Gather results to return
results.vars.agent = agent;
results.vars.variable = variable;
results.vars.solver = solver;
results.vars.costfun = costfun;

if keepCostGraph; results.allcost = costList; end
if exist('bestsolution', 'var')
    results.cost = bestSolution;
else
    results.cost = getCost(costfun, variable, agent);
end
results.evals = org.anon.cocoa.ExperimentControl.getNumberEvals();
results.msgs = org.anon.cocoa.agents.AbstractSolverAgent.getTotalSentMessages;

results.graph.density = graphDensity(edges);
results.graph.edges = edges;
results.graph.nAgents = nagents;

end

function cost = getCost(costfun, variable, agent)

%% Get the results
if isa(costfun(1), 'org.anon.cocoa.costfunctions.InequalityConstraintCostFunction')
    pc = org.anon.cocoa.problemcontexts.IndexedProblemContext(-1);
    for i = 1:numel(variable)
        if (variable(i).isSet())
            v = variable(i).getValue();
            if isa(v, 'double')
                pc.setValue(i-1, java.lang.Integer(v));
            else
                pc.setValue(i-1, v);
            end
        end
    end
else
    pc = org.anon.cocoa.problemcontexts.LocalProblemContext(agent(1));
    for i = 1:numel(variable)
        if (variable(i).isSet())
            v = variable(i).getValue();
            if isa(v, 'double')
                pc.setValue(agent(i), java.lang.Integer(v));
            else
                pc.setValue(agent(i), v);
            end
        end
    end
end

cost = 0;
for i = 1:numel(costfun)
%     cost = cost + costfun(i).currentValue();
    cost = cost + costfun(i).evaluate(pc);
end

%cost = cost / 2; % Since symmetric cost functions

end

