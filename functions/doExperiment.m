function results = doExperiment(edges, options)
%#ok<*AGROW>

%% Parse the options
nColors = getSubOption(uint16(3), 'uint16', options, 'ncolors');
nStableIterations = getSubOption(uint16([]), 'uint16', options, 'nStableIterations');
nMaxIterations = getSubOption(uint16([]), 'uint16', options, 'nMaxIterations');
solverType = getSubOption('org.anon.cocoa.solvers.UniqueFirstCooperativeSolver', ...
    'char', options, 'solverType');
constraintType = getSubOption('org.anon.cocoa.constraints.InequalityConstraint', ...
    'char', options, 'constraint', 'type');
constraintArgs = getSubOption({}, 'cell', options, 'constraint', 'arguments');
maxtime = getSubOption(180, 'double', options, 'maxTime'); %maximum delay in seconds
waittime = getSubOption(1/2, 'double', options, 'waitTime'); %delay between checks
agentProps = getSubOption(struct, 'struct', options, 'agentProperties');
keepCostGraph = getSubOption(false, 'logical', options, 'keepCostGraph');

nagents = graphSize(edges);

if strfind(solverType, 'MaxSum')
    nStableIterations = nStableIterations .* 2.5;
end

%% Setup the agents and variables
org.anon.cocoa.ExperimentControl.ResetExperiment();

fields = fieldnames(agentProps);
for i = 1:nagents
    varName = sprintf('variable%05d', i);
    agentName = sprintf('agent%05d', i);
    
    variable(i) = org.anon.cocoa.variables.IntegerVariable(int32(1), int32(nColors), varName);
    if strfind(solverType, 'FBSolver')
        agent(i) = org.anon.cocoa.agents.LinkedAgent(variable(i), agentName);
    elseif strfind(solverType, 'MaxSum')
        agent(i) = org.anon.cocoa.agents.VariableAgent(variable(i), agentName);
    else
        agent(i) = org.anon.cocoa.agents.SolverAgent(variable(i), agentName);
    end
    solver(i) = feval(solverType, agent(i));
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

%% Add the constraints

% if ~isempty(strfind(solverType, 'MaxSum'))
%     for i = 1:size(edges,1)
%         % Create constraint agent
%         agentName = sprintf('constraint%05d', i);
%         functionAgent(i) = org.anon.cocoa.agents.LocalSolverAgent(agentName, null(1));
%         costfun(i) = feval(constraintType, functionAgent(i));
%         functionSolverType = char(solver(edges(i,1)).getCounterPart().getCanonicalName());
%         functionsolver(i) = feval(functionSolverType, functionAgent(i), costfun(i));
%         functionAgent(i).setSolver(functionsolver(i));
%         functionAgent(i).reset();
%
%         % Connect constraints to variables
%         functionAgent(i).addToNeighborhood(agent(edges(i,1)));
%         functionAgent(i).addToNeighborhood(agent(edges(i,2)));
%
%         % And vice versa
%         agent(edges(i,1)).addToNeighborhood(functionAgent(i));
%         agent(edges(i,2)).addToNeighborhood(functionAgent(i));
%
%         functionAgent(i).init();
%     end
% else
for i = 1:size(edges,1)
    a = edges(i,1);
    b = edges(i,2);
    
    if numel(constraintArgs) <= 1
        constraint(i) = feval(constraintType, variable(a), variable(b), constraintArgs{:});
    elseif numel(constraintArgs) == size(edges,1)
        constraint(i) = feval(constraintType, variable(a), variable(b), constraintArgs{i});
    elseif mod(numel(constraintArgs), size(edges,1)) == 0
        n = numel(constraintArgs) / size(edges,1);
        k = (1+(i-1)*n):(i*n);
        constraint(i) = feval(constraintType, variable(a), variable(b), constraintArgs{k});
    else
        error('DOEXPERIMENT:INCORRECTARGUMENTCOUNT', ...
            'Incorrect number of constraint arguments, must be 0, 1 or number of edges (%d)', ...
            size(edges,1));
    end
    
    if ~isempty(strfind(solverType, 'MaxSum'))
        % Create constraint agent
        agentName = sprintf('constraint%05d', i);
        bipartiteConstraint = org.anon.cocoa.constraints.BiPartiteConstraint(variable(a),variable(b),constraint(i));
        constraintAgent(i) = org.anon.cocoa.agents.ConstraintAgent(agentName, bipartiteConstraint);
        functionSolverType = char(solver(a).getCounterPart().getCanonicalName());
        constraintsolver(i) = feval(functionSolverType, constraintAgent(i));
        constraintAgent(i).setSolver(constraintsolver(i));
        
        % Connect constraint to variables
        agent(a).addFunctionAddress(constraintAgent(i).getID());
        agent(b).addFunctionAddress(constraintAgent(i).getID());
        
        constraintAgent(i).reset();
        constraintAgent(i).init();
    else
        agent(a).addConstraint(constraint(i));
        agent(b).addConstraint(constraint(i));
    end
end
% end

%% Set agent's parents if need be
if strfind(solverType, 'FBSolver')
    for i = 2:nagents
        agent(i-1).setNext(agent(i));
    end
end

%% Init all agents
for i = nagents:-1:1
    agent(i).init();
    pause(.01);
end

%% Start the experiment

t_experiment_start = tic; % start the clock
startidx = randi(nagents);
a = solver(startidx);
if isa(a, 'org.anon.cocoa.solvers.GreedySolver')
    msg = org.anon.cocoa.messages.HashMessage('GreedySolver:AssignVariable');
    a.push(msg);
elseif isa(a, 'org.anon.cocoa.solvers.GreedyCooperativeSolver')
    msg = org.anon.cocoa.messages.HashMessage('GreedyCooperativeSolver:PickAVar');
    a.push(msg);
elseif isa(a, 'org.anon.cocoa.solvers.CoCoSolver')
    msg = org.anon.cocoa.messages.HashMessage('CoCoSolver:PickAVar');
    a.push(msg);
elseif isa(a, 'org.anon.cocoa.solvers.UniqueFirstCooperativeSolver')
    msg = org.anon.cocoa.messages.HashMessage('UniqueFirstCooperativeSolver:PickAVar');
    a.push(msg);
end

%% Do the iterations
numIters = 0;
if isa(solver(1), 'org.anon.cocoa.solvers.IterativeSolver')
    %bestSolution = getCost(costfun, variable, agent);
    bestSolution = inf;
    
    if keepCostGraph;
        costList = []; %bestSolution;
        evalList = org.anon.cocoa.ExperimentControl.getNumberEvals();
        msgList = org.anon.cocoa.MailMan.getTotalSentMessages();
        timeList = toc(t_experiment_start);
    end
    
    % Iterate for AT LEAST nStableIterations
    countDown = nStableIterations;
    fprintf('Iteration: ');
    while ~doStop(numIters, nMaxIterations, countDown, nStableIterations)
        countDown = countDown - 1;
        numIters = numIters + 1;
        if mod(numIters, 25) == 0
             fprintf(' %d', numIters);
        end
        
        arrayfun(@(x) x.tick, solver);
        
        if exist('constraintsolver', 'var')
            arrayfun(@(x) x.tick, constraintsolver);
        end
        
        cost = getCost(constraint);
        if keepCostGraph;
            costList(numIters) = cost;
            evalList(numIters) = org.anon.cocoa.ExperimentControl.getNumberEvals();
            msgList(numIters) = org.anon.cocoa.MailMan.getTotalSentMessages();
            timeList(numIters) = toc(t_experiment_start);
        end
        
        % If a better solution is found, reset countDown
        if cost < bestSolution
            countDown = nStableIterations;
            bestSolution = cost;
        end
    end
    fprintf(' done\n')
end

%% Wat for the algorithms to converge

% This loop does not really work for algorithms that run iteratively
for t = 1:(maxtime / waittime)
    pause(waittime);
    isset = arrayfun(@(x) x.isSet(), variable);
    
    if all(isset), break; end
end

%% Gather results to return
results.time = toc(t_experiment_start);
results.vars.agent = agent;
results.vars.variable = variable;
results.vars.solver = solver;
results.vars.constraint = constraint;
if exist('constraintsolver', 'var')
    results.vars.constraintsolver = constraintsolver;
end

if exist('bestSolution', 'var')
    results.cost = bestSolution;
else
    results.cost = getCost(constraint);
end

if keepCostGraph && exist('costList', 'var')
    results.allcost = costList;
else
    results.allcost = results.cost;
end

if keepCostGraph && exist('msgList', 'var')
    results.allmsgs = msgList;
else
    results.allmsgs = org.anon.cocoa.MailMan.getTotalSentMessages();
end

if keepCostGraph && exist('evalList', 'var')
    results.allevals = evalList;
else
    results.allevals = org.anon.cocoa.ExperimentControl.getNumberEvals();
end

if keepCostGraph && exist('timeList', 'var')
    results.alltimes = timeList;
else
    results.alltimes = results.time;
end

results.iterations = max(1,numIters);
results.evals = org.anon.cocoa.ExperimentControl.getNumberEvals();
results.msgs = org.anon.cocoa.MailMan.getTotalSentMessages();

results.graph.density = graphDensity(edges);
results.graph.edges = edges;
results.graph.nAgents = nagents;

% clean up java objects
arrayfun(@(x) x.reset, agent);
org.anon.cocoa.ExperimentControl.ResetExperiment();

end

function cost = getCost(constraint)
%% Get solution costs

cost = sum(arrayfun(@(x) x.getExternalCost(), constraint));

end

% Stop as soon as one of the stopping criteria was met
function bool = doStop(numIters, nMaxIterations, countDown, nStableIterations)

bool = false;
if ~isempty(nMaxIterations) && (numIters >= nMaxIterations)
    bool = true;
end

if ~isempty(nStableIterations) && (countDown <= 0)
    bool = true;
end

end

