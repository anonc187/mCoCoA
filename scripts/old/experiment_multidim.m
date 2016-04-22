%#ok<*SAGROW>
superclear

%% Overall experiment settings
settings.nagents = 50;
settings.numExps = 10;
settings.nMaxIterations = 500;
settings.nStableIterations = [];
settings.msgProb = 0:.1:1;

%% Experiment options
options.ncolors = uint16(3);
options.costFunction = 'org.anon.cocoa.costfunctions.LocalInequalityConstraintCostFunction';
% options.costFunction = 'org.anon.cocoa.costfunctions.LocalGameTheoreticCostFunction';
% options.costFunction = 'org.anon.cocoa.costfunctions.SemiRandomCostFunction';
% options.costFunction = 'org.anon.cocoa.costfunctions.RandomCostFunction';
% options.costFunction = 'org.anon.cocoa.costfunctions.NoisyLocalInequalityConstraintCostFunction';

% options.graphType = @scalefreeGraph;
% options.graph.maxLinks = uint16(4);
% options.graph.initialsize = uint16(10);

% options.graphType = @randomGraph;
% options.graph.density = 0.05;

options.graphType = @delaunayGraph;
options.graph.nAgents = uint16(settings.nagents);
options.graph.sampleMethod = 'poisson';
% options.graph.sampleMethod = 'random';

options.nStableIterations = uint16(settings.nStableIterations);
options.nMaxIterations = uint16(settings.nMaxIterations);
options.maxTime = 120;
options.waitTime = 1;
options.keepCostGraph = true;

%% Solvers
% solvers.ACLS = 'org.anon.cocoa.solvers.ACLSSolver';
% solvers.ACLSUB = 'org.anon.cocoa.solvers.ACLSUBSolver';
% solvers.ACLSProb = 'org.anon.cocoa.solvers.ACLSProbSolver';
% solvers.AFB = 'org.anon.cocoa.solvers.FBSolver';
% solvers.CFL = 'org.anon.cocoa.solvers.TickCFLSolver';
% solvers.CoCoA = 'org.anon.cocoa.solvers.UniqueFirstCooperativeSolver';
solvers.DSA = 'org.anon.cocoa.solvers.DSASolver';
% solvers.Greedy = 'org.anon.cocoa.solvers.GreedyLocalSolver';
% solvers.MaxSum = 'org.anon.cocoa.solvers.MaxSumVariableSolver';
% solvers.MaxSumAD = 'org.anon.cocoa.solvers.MaxSumADVariableSolver';
% solvers.MaxSumADVP = 'org.anon.cocoa.solvers.MaxSumADVPVariableSolver';
% solvers.MCSMGM = 'org.anon.cocoa.solvers.MCSMGMSolver';
% solvers.MGM = 'org.anon.cocoa.solvers.MGMSolver';
% solvers.MGM2 = 'org.anon.cocoa.solvers.MGM2Solver';
% solvers.Random = 'org.anon.cocoa.solvers.RandomSolver';
% solvers.SCA2 = 'org.anon.cocoa.solvers.SCA2Solver';

solvertypes = fieldnames(solvers);

C = strsplit(options.costFunction, '.');
expname = sprintf('exp_multidim_%s_%s_i%d_d%d_n%d_t%s', C{end}, func2str(options.graphType), settings.numExps, options.ncolors, datestr(now,30));

% Do the experiment
clear handles;
for n = 1:numel(settings.msgProb)
%     options.graph.nAgents = uint16(settings.nagents(n));
    org.anon.cocoa.agents.AbstractSolverAgent.setArrivalProbability(settings.msgProb(n));
    
    for e = 1:settings.numExps
        edges = feval(options.graphType, options.graph);

        for a = 1:numel(solvertypes)
            solvername = solvertypes{a};
            options.solverType = solvers.(solvername);
            
            try
                fprintf('Performing experiment with %s (%d/%d)\n', solvername, e, settings.numExps);
                exp = doExperiment(edges, options);
    %             exp = struct('allcost', rand(1,100), 'iterations', 100, 'allevals', rand(1,100), 'allmsgs', rand(1,100));
            catch err
                warning('Timeout or error occured:');
                disp(err);

                exp.allcost = nan;
                exp.allevals = nan;
                exp.allmsgs = nan;
                exp.iterations = nan;
            end

            results.(solvername).costs{n,e} = exp.allcost; 
            results.(solvername).evals{n,e} = exp.allevals;
            results.(solvername).msgs{n,e} = exp.allmsgs;
            results.(solvername).iterations{n,e} = exp.iterations;
            
            if ~exist('handles', 'var') || ~isfield(handles, 'fig') || ~ishandle(handles.fig)
                handles.fig = figure(007);
                handles.ax = gca(handles.fig);
                hold(handles.ax, 'on');
                handles.legend = legend(handles.ax, solvertypes);
            end

            if ~isfield(handles, solvername) || ~ishandle(handles.(solvername))
                handles.(solvername) = plot(exp.allcost, 'parent', handles.ax);
                handles.legend = legend(handles.ax, solvertypes);
            else
                set(handles.(solvername), 'XData', 1:numel(exp.allcost), 'YData', exp.allcost);
            end
            drawnow;
        end
    end
end

%% Save results

save(fullfile('data', sprintf('%s_results.mat', expname)), 'settings', 'solvers', 'results');

%% Create graph
% 
% options = getGraphOptions();
% options.axes.yscale = 'linear'; % True for most situations
% options.export.do = false;
% options.label.Y = 'Solution cost';
% options.plot.hi_error_fun = @(x)x + 1;
% options.plot.low_error_fun = @(x)x - 1;
% createResultGraph(results, settings, 'costs', options);


% create_graphs;

