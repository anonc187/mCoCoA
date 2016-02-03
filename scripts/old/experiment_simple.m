%#ok<*SAGROW>
superclear

settings.nagents = 50;
settings.numExps = 5;

options.ncolors = uint16(3);
% options.costFunction = 'org.anon.cocoa.costfunctions.LocalInequalityConstraintCostFunction';
options.costFunction = 'org.anon.cocoa.costfunctions.LocalGameTheoreticCostFunction';
% options.costFunction = 'org.anon.cocoa.costfunctions.RandomCostFunction';

% options.graphType = @scalefreeGraph;
% options.graphType = @randomGraph;
options.graphType = @delaunayGraph;
options.graph.sampleMethod = 'poisson';
% options.graph.sampleMethod = 'random';
options.keepCostGraph = true;

options.nStableIterations = uint16(25);
options.maxTime = 120;
options.waitTime = 15;

solvers.ACLS = 'org.anon.cocoa.solvers.ACLSSolver';
solvers.DSA = 'org.anon.cocoa.solvers.DSASolver';
solvers.CoCoA = 'org.anon.cocoa.solvers.UniqueFirstCooperativeSolver';
solvers.Greedy = 'org.anon.cocoa.solvers.GreedyLocalSolver';
% solvers.MGM = 'org.anon.cocoa.solvers.MGMSolver';
solvers.MGM2 = 'org.anon.cocoa.solvers.MGM2Solver';
% solvers.SCA2 = 'org.anon.cocoa.solvers.SCA2Solver';
% solvers.AFB = 'org.anon.cocoa.solvers.FBSolver';
% solvers.CFL = 'org.anon.cocoa.solvers.TickCFLSolver';


solvertypes = fieldnames(solvers);

C = strsplit(options.costFunction, '.');
expname = sprintf('exp_%s_%s_i%d_c%d_t%s', C{end}, func2str(options.graphType), settings.numExps, options.ncolors, datestr(now,30));

options.graph.nAgents = uint16(settings.nagents);
for e = 1:settings.numExps
    edges = feval(options.graphType, options.graph);

    for a = 1:numel(solvertypes)
        solvername = solvertypes{a};
        options.solverType = solvers.(solvername);

%             try
            fprintf('Performing experiment with %s(%d)\n', solvername, settings.nagents);
            exp = doExperiment(edges, options);
%             catch err
%                 warning('Timeout or error occured:');
%                 disp(err);
%                 cost = nan; evals = nan; msgs = nan;
%             end
        results.(solvername).costList{e} = exp.allcost;
        results.(solvername).costs(e) = exp.cost; 
        results.(solvername).evals(e) = exp.evals;
        results.(solvername).msgs(e) = exp.msgs;
    end
end

%% Save results

save(fullfile('data', sprintf('%s_results.mat', expname)), 'settings', 'solvers', 'results');

% create_graphs;
