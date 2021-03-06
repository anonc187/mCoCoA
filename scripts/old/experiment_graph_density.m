%#ok<*SAGROW>
superclear

settings.nagents = 100;
settings.density = [.05 .1 .2 .4 .8];
settings.numExps = 1;

solvers.DSA = 'org.anon.cocoa.solvers.DSASolver';
solvers.CoCoA = 'org.anon.cocoa.solvers.UniqueFirstCooperativeSolver';
% solvers.Greedy = 'org.anon.cocoa.solvers.GreedyLocalSolver';
solvers.MGM2 = 'org.anon.cocoa.solvers.MGM2Solver';
% solvers.AFB = 'org.anon.cocoa.solvers.FBSolver';
% solvers.CFL = 'org.anon.cocoa.solvers.TickCFLSolver';
solvers.ACLS = 'org.anon.cocoa.solvers.ACLSSolver';
solvers.MCSMGM = 'org.anon.cocoa.solvers.MCSMGMSolver';

options.ncolors = uint16(10);
% options.costFunction = 'org.anon.cocoa.costfunctions.RandomCostFunction';
options.costFunction = 'org.anon.cocoa.costfunctions.SemiRandomCostFunction';
options.graphType = @randomGraph;

options.nStableIterations = uint16(0);
options.nMaxIterations = uint16(100);
options.maxTime = 120;
options.waitTime = 1;
options.keepCostGraph = false;

solvertypes = fieldnames(solvers);

C = strsplit(options.costFunction, '.');
expname = sprintf('exp_density_%s_%s_i%d_d%d_n%d_t%s', C{end}, func2str(options.graphType), settings.numExps, options.ncolors, settings.nagents, datestr(now,30));

for n = 1:numel(settings.density)
    options.graph.density = settings.density(n);
    options.graph.nAgents = uint16(settings.nagents);
    
    for e = 1:settings.numExps
        
        edges = feval(options.graphType, options.graph);
        fprintf('Graph generated with density %f (%s)\n', graphDensity(edges), func2str(options.graphType));
    
        for a = 1:numel(solvertypes)
            solvername = solvertypes{a};
            options.solverType = solvers.(solvername);
  
%             try
                fprintf('Performing experiment with %s (%d/%d)\n', solvername, e, settings.numExps);
                exp = doExperiment(edges, options);
%             catch err
%                 warning('Timeout or error occured:');
%                 disp(err);
%                 cost = nan; evals = nan; msgs = nan;
%             end
            results.(solvername).costs(n,e) = exp.cost; 
            results.(solvername).evals(n,e) = exp.evals;
            results.(solvername).msgs(n,e) = exp.msgs;
        end
    end
end

%% Save results

save(fullfile('data', sprintf('%s_results.mat', expname)), 'settings', 'solvers', 'results');

% create_density_graphs;
