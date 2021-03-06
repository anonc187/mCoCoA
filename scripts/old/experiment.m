superclear
rng(1, 'twister');

colornames = {'red', 'green', 'cyan', 'blue', 'yellow', 'magenta', 'brown', 'coral', 'gold', 'black', 'azure'};
options.ncolors = uint16(11);

% options.constraint.type = 'org.anon.cocoa.constraints.RandomConstraint';
% options.constraint.type = 'org.anon.cocoa.constraints.InequalityConstraint';
options.constraint.type = 'org.anon.cocoa.constraints.CostMatrixConstraint';
load('staticCosts.mat');
options.constraint.arguments = {localCost, localCost};

% options.constraint.arguments = {[[1 0 3];[3 1 0];[0 3 1]], [[1 0 3];[3 1 0];[0 3 1]]};
% options.constraint.arguments = {1};
makeRandomConstraintCosts = false;

options.solverType = 'org.anon.cocoa.solvers.DSASolver';
% options.solverType = 'org.anon.cocoa.solvers.CoCoASolver';
% options.solverType = 'org.anon.cocoa.solvers.CoCoSolver';
% options.solverType = 'org.anon.cocoa.solvers.ReCoCoSolver';
% options.solverType = 'org.anon.cocoa.solvers.ReCoCoMGMSolver';
% options.solverType = 'org.anon.cocoa.solvers.GreedySolver';
% options.solverType = 'org.anon.cocoa.solvers.TickCFLSolver';
% options.solverType = 'org.anon.cocoa.solvers.FBSolver';
% options.solverType = 'org.anon.cocoa.solvers.MGMSolver';
% options.solverType = 'org.anon.cocoa.solvers.SCA2Solver';
% options.solverType = 'org.anon.cocoa.solvers.MGM2Solver';
% options.solverType = 'org.anon.cocoa.solvers.ACLSSolver';
% options.solverType = 'org.anon.cocoa.solvers.MCSMGMSolver';
% options.solverType = 'org.anon.cocoa.solvers.MaxSumVariableSolver';
% options.solverType = 'org.anon.cocoa.solvers.MaxSumADVPVariableSolver';

options.graph.nAgents = uint16(3);
options.graphType = @delaunayGraph;
options.graph.sampleMethod = 'poisson';
% options.graphType = @scalefreeGraph;
% options.graph.maxLinks = uint16(4);
% options.graph.initialsize = uint16(10);

% options.graphType = @randomGraph;
% options.graph.density = .2;

% options.graphType = @nGridGraph;
% options.graph.nDims = uint16(3);
% options.graph.doWrap = '';

% options.nStableIterations = uint16(100);
options.nMaxIterations = uint16(100);
options.keepCostGraph = true;

% Do the experiment
edges = feval(options.graphType, options.graph);
if makeRandomConstraintCosts
    constraintCosts = randi(10, options.ncolors, options.ncolors, numel(edges));
    options.constraint.arguments = arrayfun(@(x) constraintCosts(:,:,x), 1:numel(edges), 'UniformOutput', false);
end
experimentResult = doExperiment(edges, options);

% plot(experimentResult.allcost)
% line([0 numel(experimentResult.allcost)], [experimentResult.cost experimentResult.cost]);
% shg

% Show results
fprintf('\nExperiment results:\n');
fprintf('\tFound cost: %d\n', experimentResult.cost);
fprintf('\tNumber of iterations: %d\n', experimentResult.iterations);
fprintf('\tTime to complete: %1.5f\n', experimentResult.time);
fprintf('\tFunction evals: %d\n', experimentResult.evals);
fprintf('\tNumber of msgs: %d\n', experimentResult.msgs);
fprintf('\tSolver type: %s\n', class(experimentResult.vars.solver(1)));
% fprintf('\tCost function: %s\n', class(experimentResult.vars.costfun(1)));
fprintf('\tGraph type: %s\n', func2str(options.graphType));
fprintf('\t\t- size: %d\n', experimentResult.graph.nAgents);
fprintf('\t\t- density: %1.5f\n', experimentResult.graph.density);

if isfield(experimentResult, 'allcost') && numel(experimentResult.allcost) > 1
    figure(187)
    plot(experimentResult.allcost)
end

% return
%% Create pretty graph (not required)

fid = fopen('test.gv', 'w');
fprintf(fid, 'graph {\n');
fprintf(fid, 'graph [K=0.03, overlap=false];\n');
fprintf(fid, 'node [style=filled];\n');

for i = 1:experimentResult.graph.nAgents
    var = experimentResult.vars.variable(i);
    if var.isSet()
        fprintf(fid, ' %d [fillcolor=%s, width=.2, height=.1];\n', i, colornames{double(var.getValue)});
    else
        fprintf(fid, ' %d [fillcolor=white, width=.2, height=.1];\n', i);
    end
end

for i = 1:size(experimentResult.graph.edges,1)
    fprintf(fid, ' %d -- %d;\n', experimentResult.graph.edges(i,1), experimentResult.graph.edges(i,2));
end
fprintf(fid, '}\n');
fclose(fid);

searchpath = 'c:\Progra~1';
files = dir(fullfile(searchpath, 'Graphviz*'));
if (numel(files) == 0)
    % Also search (x86)
    searchpath = 'c:\Progra~2';
    files = dir(fullfile(searchpath, 'Graphviz*'));
end

if (numel(files) == 0)
    error('Unable to complete printing graph, could not find Graphviz installation');
end
graphvizpath = fullfile(searchpath, files(1).name, 'bin');

layout = fullfile(graphvizpath, 'sfdp.exe');
% layout = fullfile(graphvizpath, 'twopi.exe');

gvfile = fullfile(pwd, 'test.gv');
pngfile = fullfile(pwd, 'test_colored.png');
[a,b] = system(sprintf('%s %s -T png -Gdpi=100 -o %s', layout, gvfile, pngfile));

fprintf('%s - Done!\n', datestr(now));