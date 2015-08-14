% superclear
clear all
clear java

rng(1, 'twister');

colornames = {'red', 'green', 'blue', 'yellow', 'cyan', 'magenta'};
options.ncolors = uint16(3);
options.costFunction = 'org.anon.cocoa.costfunctions.LocalInequalityConstraintCostFunction';
% options.costFunction = 'org.anon.cocoa.costfunctions.LocalGameTheoreticCostFunction';
% options.costFunction = 'org.anon.cocoa.costfunctions.RandomCostFunction';

% options.solverType = 'org.anon.cocoa.solvers.DSASolver';
% options.solverType = 'org.anon.cocoa.solvers.UniqueFirstCooperativeSolver';
% options.solverType = 'org.anon.cocoa.solvers.GreedyCooperativeSolver';
% options.solverType = 'org.anon.cocoa.solvers.GreedyLocalSolver';
% options.solverType = 'org.anon.cocoa.solvers.TickCFLSolver';
options.solverType = 'org.anon.cocoa.solvers.FBSolver';
% options.solverType = 'org.anon.cocoa.solvers.MGMSolver';
% options.solverType = 'org.anon.cocoa.solvers.SCA2Solver';
% options.solverType = 'org.anon.cocoa.solvers.MGM2Solver';

options.graph.nAgents = uint16(10);
% options.graphType = @delaunayGraph;
% options.graphType = @scalefreeGraph;
options.graphType = @randomGraph;
options.graph.density = .2;

options.nIterations = uint16(60);
options.keepCostGraph = false;

% Do the experiment
edges = feval(options.graphType, options.graph);
experimentResult = doExperiment(edges, options);

% plot(experimentResult.allcost)
% line([0 numel(experimentResult.allcost)], [experimentResult.cost experimentResult.cost]);
% shg

%% Show results
fprintf('\nExperiment results:\n');
fprintf('\tFound cost: %d\n', experimentResult.cost);
fprintf('\tFunction evals: %d\n', experimentResult.evals);
fprintf('\tNumber of msgs: %d\n', experimentResult.msgs);
fprintf('\tSolver type: %s\n', class(experimentResult.vars.solver(1)));
fprintf('\tCost function: %s\n', class(experimentResult.vars.costfun(1)));
fprintf('\tGraph type: %s\n', func2str(options.graphType));
fprintf('\t\t- size: %d\n', experimentResult.graph.nAgents);
fprintf('\t\t- density: %1.5f\n', experimentResult.graph.density);

return
%% The rest makes a nice graph, which is not required

fid = fopen('test.gv', 'w');
fprintf(fid, 'graph {\n');
fprintf(fid, 'graph [K=0.03, overlap=false];\n');
fprintf(fid, 'node [style=filled];\n');

for i = 1:experimentResult.graph.nAgents
    var = experimentResult.vars.variable(i);
    if var.isSet()
        fprintf(fid, ' %d [fillcolor=%s, width=.2, height=.1];\n', i, colornames{double(var.getValue)});
    else
        fprintf(fid, ' %d [fillcolor=white];\n', i);
    end
end

for i = 1:size(experimentResult.graph.edges,1)
    fprintf(fid, ' %d -- %d;\n', experimentResult.graph.edges(i,1), experimentResult.graph.edges(i,2));
end
fprintf(fid, '}\n');
fclose(fid);


graphvizpath = 'c:\Progra~2/Graphviz2.34/bin';

% layout = fullfile(graphvizpath, 'sfdp.exe');
layout = fullfile(graphvizpath, 'twopi.exe');

gvfile = fullfile(pwd, 'test.gv');
pngfile = fullfile(pwd, 'test.png');
[a,b] = system(sprintf('%s %s -T png -o %s', layout, gvfile, pngfile));

fprintf('%s - Done!\n', datestr(now));