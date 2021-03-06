%#ok<*SAGROW>
superclear
warning('off', 'MATLAB:legend:PlotEmpty');
warning('off', 'MATLAB:legend:IgnoringExtraEntries');

%% Overall experiment settings
settings.numExps = 1; % i.e. number of problems generated
settings.nMaxIterations = [];
settings.nStableIterations = 100;
settings.nagents = 50;
settings.densities = .05:.05:.5;
settings.visualizeProgress = true;
settings.makeRandomConstraintCosts = true;

%% Create the experiment options
options.ncolors = uint16(3);
% options.constraint.type = 'org.anon.cocoa.constraints.InequalityConstraint';
% options.constraint.arguments = {1};
options.constraint.type = 'org.anon.cocoa.constraints.CostMatrixConstraint';
% options.constraint.arguments = {[[1 0 3];[3 1 0];[0 3 1]], [[1 0 3];[3 1 0];[0 3 1]]};
% options.constraint.type = 'org.anon.cocoa.constraints.SemiRandomConstraint';
% options.constraint.type = 'org.anon.cocoa.constraints.RandomConstraint';

options.graphType = @randomGraph;

options.graph.nAgents = uint16(settings.nagents);

options.nStableIterations = uint16(settings.nStableIterations);
options.nMaxIterations = uint16(settings.nMaxIterations);
options.maxTime = 120;
options.waitTime = 1;
options.keepCostGraph = true;

solvers.ACLS = 'org.anon.cocoa.solvers.ACLSSolver';
% solvers.ACLSUB = 'org.anon.cocoa.solvers.ACLSUBSolver';
% solvers.ACLSProb = 'org.anon.cocoa.solvers.ACLSProbSolver';
% solvers.AFB = 'org.anon.cocoa.solvers.FBSolver';
% solvers.CFL = 'org.anon.cocoa.solvers.TickCFLSolver';
solvers.CoCoA = 'org.anon.cocoa.solvers.CoCoASolver';
solvers.CoCoS = 'org.anon.cocoa.solvers.CoCoSolver';
% solvers.ReCoCoS = 'org.anon.cocoa.solvers.ReCoCoSolver';
solvers.DSA = 'org.anon.cocoa.solvers.DSASolver';
% solvers.Greedy = 'org.anon.cocoa.solvers.GreedySolver';
% solvers.MaxSum = 'org.anon.cocoa.solvers.MaxSumVariableSolver';
% solvers.MaxSumAD = 'org.anon.cocoa.solvers.MaxSumADVariableSolver';
solvers.MaxSumADVP = 'org.anon.cocoa.solvers.MaxSumADVPVariableSolver';
solvers.MCSMGM = 'org.anon.cocoa.solvers.MCSMGMSolver';
% solvers.MGM = 'org.anon.cocoa.solvers.MGMSolver';
solvers.MGM2 = 'org.anon.cocoa.solvers.MGM2Solver';
% solvers.Random = 'org.anon.cocoa.solvers.RandomSolver';
% solvers.SCA2 = 'org.anon.cocoa.solvers.SCA2Solver';

%%
solvertypes = fieldnames(solvers);

C = strsplit(options.constraint.type, '.');
expname = sprintf('exp_%s_%s_i%d_d%d_n%d_t%s', C{end}, func2str(options.graphType), settings.numExps, options.ncolors, settings.nagents, datestr(now,30));

% Do the experiment
clear handles;
for i = 1:numel(settings.densities)
    options.graph.density = settings.densities(i);
    for e = 1:settings.numExps
        edges = feval(options.graphType, options.graph);

        if isfield(settings, 'makeRandomConstraintCosts') && settings.makeRandomConstraintCosts
            constraintCosts = randi(10, options.ncolors, options.ncolors, numel(edges));
            options.constraint.arguments = arrayfun(@(x) constraintCosts(:,:,x), 1:numel(edges), 'UniformOutput', false);
        else
            options.constraint.arguments = {};
        end

        for a = 1:numel(solvertypes)
            solvername = solvertypes{a};
            options.solverType = solvers.(solvername);

%             try
                fprintf('Performing experiment with %s (%d/%d) (%d/%d)\n', solvername, e, settings.numExps, i, numel(settings.densities));
                exp = doExperiment(edges, options);
                fprintf('Finished in t = %0.1f seconds\n', exp.time);
%             catch err
%                 warning('Timeout or error occured:');
%                 disp(err);
%                 
%                 exp.time = nan;
%                 exp.allcost = nan;
%                 exp.allevals = nan;
%                 exp.allmsgs = nan;
%                 exp.iterations = nan;
%                 exp.alltimes = nan;
%             end

            results.(solvername).costs{e,i} = exp.allcost; 
            results.(solvername).evals{e,i} = exp.allevals;
            results.(solvername).msgs{e,i} = exp.allmsgs;
            results.(solvername).times{e,i} = exp.alltimes;
            results.(solvername).iterations(e,i) = exp.iterations;

            if settings.visualizeProgress
                visualizeProgress(exp, solvername);
            end
        end
    end
end

%% Save results

save(fullfile('data', sprintf('%s_results.mat', expname)), 'settings', 'options', 'solvers', 'results');

%% Create graph

graphoptions = getGraphOptions();
graphoptions.figure.number = 188;
graphoptions.axes.yscale = 'linear'; % True for most situations
graphoptions.axes.xscale = 'linear';
graphoptions.axes.ymin = [];
graphoptions.axes.xmax = 250;
graphoptions.export.do = false;
% graphoptions.export.name = expname;
graphoptions.label.Y = 'Solution Cost';
% graphoptions.label.X = 'Time';
graphoptions.plot.errorbar = false;
graphoptions.plot.emphasize = []; %'CoCoA';
% graphoptions.legend.location = 'NorthEast';
% graphoptions.legend.orientation = 'Horizontal';
% graphoptions.plot.x_fun = @(x) 1:max(x);
% graphoptions.plot.range = 1:1600;
resultsMat = prepareResults(results); %, graphoptions.plot.range);
createResultGraph(resultsMat, 'times', 'costs', graphoptions);

