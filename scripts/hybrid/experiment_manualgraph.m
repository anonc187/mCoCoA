%#ok<*SAGROW>
superclear
warning('off', 'MATLAB:legend:PlotEmpty');
warning('off', 'MATLAB:legend:IgnoringExtraEntries');

%% Overall experiment settings
settings.numExps = 100; % i.e. number of problems generated
settings.nMaxIterations = 0;
settings.nStableIterations = 100;
settings.nagents = 12;
settings.ncolors = 3;
settings.visualizeProgress = true;
settings.graphType = @manualGraph;
settings.series = 'hybrid';

%% Create the experiment options
options.ncolors = uint16(settings.ncolors);
options.constraint.type = 'org.anon.cocoa.constraints.InequalityConstraint';
% options.constraint.type = 'org.anon.cocoa.constraints.SemiRandomConstraint';
% options.debug = true;
% options.ssetrack = true;

options.graph.nAgents = uint16(settings.nagents);
options.nStableIterations = uint16(settings.nStableIterations);
options.nMaxIterations = uint16(settings.nMaxIterations);

%% Solvers
initSolver.Unfortunate = 'Unfortunate';
initSolver.Random = 'org.anon.cocoa.solvers.RandomSolver';
initSolver.Greedy = 'org.anon.cocoa.solvers.GreedySolver';
% initSolver.CoCoA = 'org.anon.cocoa.solvers.CoCoSolver';
initSolver.CoCoA_UF = 'org.anon.cocoa.solvers.CoCoASolver';
% initSolver.CoCoA_WPT = 'org.anon.cocoa.solvers.CoCoAWPTSolver';

clear iterSolver;
% iterSolver.NULL = '';
iterSolver.DSA = 'org.anon.cocoa.solvers.DSASolver';
iterSolver.MGM2 = 'org.anon.cocoa.solvers.MGM2Solver';
iterSolver.ACLS = 'org.anon.cocoa.solvers.ACLSSolver';
iterSolver.ACLSUB = 'org.anon.cocoa.solvers.ACLSUBSolver';
iterSolver.MCSMGM = 'org.anon.cocoa.solvers.MCSMGMSolver';

solvers = struct([]);
for init = fieldnames(initSolver)'
    for iter = fieldnames(iterSolver)'
        solvers(end + 1).name = sprintf('%s - %s', init{:}, iter{:});
        solvers(end).initSolverType = initSolver.(init{:});
        solvers(end).iterSolverType = iterSolver.(iter{:});
    end
end

%% Do the experiment
% edges = feval(options.graphType, options.graph);
% edges = [1 2; 1 3; 1 4; 2 4; 3 4; 3 5; 4 5; 4 6; 4 9; 5 6; 7 8; 7 9; 8 9; 8 10; 9 10; 9 11; 9 12; 10 12; 11 12];
edges = [1 2; 1 3; 1 4; 1 5; 1 6; 1 7; 1 8; 1 9; 1 10; 2 3; 3 4; 4 5; 5 6; 6 7; 7 8; 8 9; 9 10;
    11 12; 11 13; 11 14; 11 15; 11 16; 11 17; 11 18; 11 19; 11 20; 12 13; 13 14; 14 15; 15 16; 16 17; 17 18; 18 19; 19 20;
    1 11];

exp = GraphColoringExperiment(edges, options);

for a = 1:numel(solvers)
    solvername = solvers(a).name;
    solverfield = matlab.lang.makeValidName(solvername);
    if strcmp(solvers(a).initSolverType, 'Unfortunate')
        exp.initSolverType = 'org.anon.cocoa.solvers.RandomSolver'; %will be discarded anyway
    else
        exp.initSolverType = solvers(a).initSolverType;
    end
    exp.iterSolverType = solvers(a).iterSolverType;
    
    for e = 1:settings.numExps
        %         try
        fprintf('Performing experiment with %s (%d/%d)\n', solvername, e, settings.numExps);
        exp.init();
        
        % Force inconvenient initialization
        if strcmp(solvers(a).initSolverType, 'Unfortunate')
            arrayfun(@(x) exp.variable{x}.setValue(int32(1)), [1 11], 'UniformOutput', false);
            arrayfun(@(x) exp.variable{x}.setValue(int32(2)), [2 4 6 8 10 12 14 16 18 20], 'UniformOutput', false);
            arrayfun(@(x) exp.variable{x}.setValue(int32(3)), [3 5 7 9 13 15 17 19], 'UniformOutput', false);
        end
        
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
%         return
        % catch err
        % warning('Timeout or error occured:');
        % disp(err);
        % end
        exp.reset();
    end
end

%% Save results
saveResults

%% Create graph
resultsMat = prepareResults(results); %, graphoptions.plot.range);
close all;
incoroporateUnsetComparison = true;
for iter = fieldnames(iterSolver)'
    figure();
    cla;
    hold on;
    title(iter);
    for init = fieldnames(initSolver)'
        solvername = sprintf('%s - %s', init{:}, iter{:});
        solverfield = matlab.lang.makeValidName(solvername);
        
        plot(mean(resultsMat.(solverfield).costs, 2), 'LineWidth', 3);
        %         density = mean(results.(solverfield).density);
        %         uniquevalexplored = mean([results.(solverfield).uniquevalexplored{:}]);
        %         numvalexplored = mean([results.(solverfield).allvalexplored{:}]);
        % %         allcombos = (density/2) * settings.nagents * settings.nagents * (settings.ncolors + incoroporateUnsetComparison) * (settings.ncolors + incoroporateUnsetComparison);
        % %         supercombos = (settings.ncolors + incoroporateUnsetComparison) ^ settings.nagents;
        %         fprintf('%s average values explored: %1.2f in %1.2f tries\n', ... %, (of %1.2f, so coverage %1.2f %%, precision %1.2f %%)\n', ...
        %             solvername, uniquevalexplored, numvalexplored); %, supercombos, 100 * uniquevalexplored / supercombos, 100 * uniquevalexplored / numvalexplored);
    end
    fprintf('\n');
    h = legend(fieldnames(initSolver));
    set(h,'interpreter', 'none');
    
%     for init = fieldnames(initSolver)'
%         solvername = sprintf('%s - %s', init{:}, iter{:});
%         solverfield = matlab.lang.makeValidName(solvername);
%         plot(min(resultsMat.(solverfield).costs, [], 2), 'LineWidth', 1);
% %         plot(mean(resultsMat.(solverfield).costs, 2), 'LineWidth', 3);
%         plot(max(resultsMat.(solverfield).costs, [], 2), 'LineWidth', 1);
%     end
end

% fprintf(


