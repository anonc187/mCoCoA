%#ok<*SAGROW>
superclear
warning('off', 'MATLAB:legend:PlotEmpty');
warning('off', 'MATLAB:legend:IgnoringExtraEntries');

%% Overall experiment settings
settings.numExps = 10; % i.e. number of problems generated
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
options.ssetrack = true;

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
% initSolver.Greedy = 'org.anon.cocoa.solvers.GreedySolver';
% initSolver.CoCoA = 'org.anon.cocoa.solvers.CoCoSolver';
initSolver.CoCoA_UF = 'org.anon.cocoa.solvers.CoCoASolver';
% initSolver.CoCoA_WPT = 'org.anon.cocoa.solvers.CoCoAWPTSolver';


clear iterSolver;
% iterSolver.NULL = '';
% iterSolver.DSA = 'org.anon.cocoa.solvers.DSASolver';
iterSolver.MGM2 = 'org.anon.cocoa.solvers.MGM2Solver';
iterSolver.ACLS = 'org.anon.cocoa.solvers.ACLSSolver';
% iterSolver.ACLSUB = 'org.anon.cocoa.solvers.ACLSUBSolver';
% iterSolver.MCSMGM = 'org.anon.cocoa.solvers.MCSMGMSolver';

clear iterSolver2;
iterSolver2.MGM2 = 'org.anon.cocoa.solvers.MGM2Solver';
iterSolver2.ACLS = 'org.anon.cocoa.solvers.ACLSSolver';
% iterSolver2.DSA = 'org.anon.cocoa.solvers.DSASolver';


solvers = struct([]);
for init = fieldnames(initSolver)'
    for iter = fieldnames(iterSolver)'
        for iter2 = fieldnames(iterSolver2)'
            solvers(end + 1).name = sprintf('%s - %s - %s', init{:}, iter{:}, iter2{:});
            solvers(end).initSolverType = initSolver.(init{:});
            solvers(end).iterSolverType = iterSolver.(iter{:});
            solvers(end).iterSolverType2 = iterSolver2.(iter2{:});
        end
    end
end

%% Do the experiment
for e = 1:settings.numExps
    edges = feval(options.graphType, options.graph);

    exp = SwitchingSolverGCE(edges, options);
    
    for a = 1:numel(solvers)
        solvername = solvers(a).name;
        solverfield = matlab.lang.makeValidName(solvername);
        exp.initSolverType = solvers(a).initSolverType;
        exp.iterSolverType = solvers(a).iterSolverType; 
        
%         try
            fprintf('Performing experiment with %s (%d/%d)\n', solvername, e, settings.numExps);
            exp.runI(100);
            exp.switchSolver(solvers(a).iterSolverType2);
            
            exp.run();
            
            fprintf('\nFinished in t = %0.1f seconds\n', exp.results.time(end));
            
            results.(solverfield).costs{e} = exp.results.cost; 
            results.(solverfield).evals{e} = exp.results.evals;
            results.(solverfield).msgs{e} = exp.results.msgs;
            results.(solverfield).times{e} = exp.results.time;
            results.(solverfield).iterations(e) = exp.results.numIters;
            results.(solverfield).density(e) = exp.graph.density;
            results.(solverfield).explored{e} = exp.results.sse_explored;
            
            results.(solverfield).uniquevalexplored{e} = org.anon.cocoa.constraints.CompareCounter.loggedComparisons.size();
            results.(solverfield).allvalexplored{e} = org.anon.cocoa.constraints.CompareCounter.numComparisons;
            
            if settings.visualizeProgress
                visualizeProgress(exp, solverfield);
            end
			drawnow;
			pause(0.1);
%             return
%         catch err
%             warning('Timeout or error occured:');
%             disp(err);
%         end
    end
end

%% Save results
saveResults

%% Create graph
resultsMat = prepareResults(results); %, graphoptions.plot.range);
close all;
incoroporateUnsetComparison = true;
for iter = fieldnames(iterSolver2)'
    figure();
    cla;
    hold on;
    title(iter);
    
    k = cellfun(@(x) endsWith(x, sprintf(' - %s', iter{:})), {solvers.name});    
    for i = find(k)
        solvername = solvers(i).name;
        solverfield = matlab.lang.makeValidName(solvername);
%         plot(mean(resultsMat.(solverfield).times, 2), mean(resultsMat.(solverfield).costs, 2), 'LineWidth', 3); 
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
    h = legend({solvers(k).name});
    set(h,'interpreter', 'none');
end

% fprintf(


