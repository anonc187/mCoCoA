%#ok<*SAGROW>
superclear
warning('off', 'MATLAB:legend:PlotEmpty');
warning('off', 'MATLAB:legend:IgnoringExtraEntries');

%% Overall experiment settings
settings.numExps = 1; % i.e. number of problems generated
settings.nMaxIterations = 0;
settings.nStableIterations = 100;
settings.nagents = 100;
settings.ncolors = 3;
settings.visualizeProgress = true;
settings.graphType = @delaunayGraph;
settings.series = 'hybrid';

%% Create the experiment options
options.ncolors = uint16(settings.ncolors);
options.constraint.type = 'org.anon.cocoa.constraints.InequalityConstraint';
% options.constraint.type = 'org.anon.cocoa.constraints.SemiRandomConstraint';
% options.debug = true;
% options.ssetrack = true;

if isequal(settings.graphType, @scalefreeGraph)
    options.graphType = @scalefreeGraph;
    options.graph.maxLinks = uint16(4);
    options.graph.initialsize = uint16(10);
elseif isequal(settings.graphType, @randomGraph)
    options.graphType = @randomGraph;
    options.graph.density = 0.05;
elseif isequal(settings.graphType, @delaunayGraph)
    options.graphType = @delaunayGraph;
    options.graph.sampleMethod = 'poisson';
elseif isequal(settings.graphType, @nGridGraph)
    options.graphType = @nGridGraph;
    options.graph.nDims = uint16(3);
    options.graph.doWrap = '';
end

options.graph.nAgents = uint16(settings.nagents);
options.nStableIterations = uint16(settings.nStableIterations);
options.nMaxIterations = uint16(settings.nMaxIterations);

%% Solvers
initSolver.Random = 'org.anon.cocoa.solvers.RandomSolver';
initSolver.Greedy = 'org.anon.cocoa.solvers.GreedySolver';
% initSolver.CoCoA = 'org.anon.cocoa.solvers.CoCoSolver';
initSolver.CoCoA_UF = 'org.anon.cocoa.solvers.CoCoASolver';
% initSolver.CoCoA_WPT = 'org.anon.cocoa.solvers.CoCoAWPTSolver';

clear iterSolver;
% iterSolver.NULL = '';
iterSolver.DSA = 'org.anon.cocoa.solvers.DSASolver';
% iterSolver.MGM2 = 'org.anon.cocoa.solvers.MGM2Solver';
% iterSolver.ACLS = 'org.anon.cocoa.solvers.ACLSSolver';
% iterSolver.ACLSUB = 'org.anon.cocoa.solvers.ACLSUBSolver';
% iterSolver.MCSMGM = 'org.anon.cocoa.solvers.MCSMGMSolver';

solvers = struct([]);
for init = fieldnames(initSolver)'
    for iter = fieldnames(iterSolver)'
        for rooted = [true false]
            if rooted; rootname = ' (rooted)'; else; rootname = ''; end
            solvers(end + 1).name = sprintf('%s - %s%s', init{:}, iter{:}, rootname);
            solvers(end).initSolverType = initSolver.(init{:});
            solvers(end).iterSolverType = iterSolver.(iter{:});
            solvers(end).rooted = rooted;
        end
    end
end

%% Do the experiment

for e = 1:settings.numExps
    
    edges = feval(options.graphType, options.graph);
    exp = GraphColoringExperiment(edges, options);
    
    for a = 1:numel(solvers)
        solvername = solvers(a).name;
        solverfield = matlab.lang.makeValidName(solvername);
        exp.useRootedSolvers = solvers(a).rooted;
        exp.initSolverType = solvers(a).initSolverType;
        exp.iterSolverType = solvers(a).iterSolverType;
        
        % try
        fprintf('Performing experiment with %s (%d/%d)\n', solvername, e, settings.numExps);
        exp.run();
        fprintf('\nFinished in t = %0.1f seconds\n', exp.results.time(end));
        
        results.(solverfield).costs{e} = exp.results.cost;
        results.(solverfield).evals{e} = exp.results.evals;
        results.(solverfield).msgs{e} = exp.results.msgs;
        results.(solverfield).times{e} = exp.results.time;
        results.(solverfield).iterations(e) = exp.results.numIters;
        results.(solverfield).density(e) = exp.graph.density;
        % results.(solverfield).explored{e} = exp.results.sse_explored;
        %
        % results.(solverfield).uniquevalexplored{e} = org.anon.cocoa.constraints.CompareCounter.loggedComparisons.size();
        % results.(solverfield).allvalexplored{e} = org.anon.cocoa.constraints.CompareCounter.numComparisons;
        
        if settings.visualizeProgress
            visualizeProgress(exp, solverfield);
        end
        drawnow;
        pause(0.1);
        %  return
        % catch err
        % warning('Timeout or error occured:');
        % disp(err);
        % end
        exp.reset();
    end
end

%% Save results
% saveResults

%% Create graph
resultsMat = prepareResults(results); %, graphoptions.plot.range);
close all;
incoroporateUnsetComparison = true;
for iter = fieldnames(iterSolver)'
    figure();
    cla;
    hold on;
    title(iter);
    
    k = cellfun(@(x) contains(x, sprintf(' - %s', iter{:})), {solvers.name});    
    for i = find(k)
        solvername = solvers(i).name;
        solverfield = matlab.lang.makeValidName(solvername);
        
        plot(mean(resultsMat.(solverfield).costs, 2), 'LineWidth', 3);
    end
    fprintf('\n');
    h = legend({solvers(k).name});
    set(h,'interpreter', 'none');

end

% fprintf(


