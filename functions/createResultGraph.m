%% CREATERESULTGRAPH
% *Summary of this function goes here*
%
% Detailed explanation goes here
%
%% Copyright
% * *2015 - Anonymous*
% * *Author*: Anomymous
% * *Since*: July 30, 2015
% 
%% See also:
%

%% Function Definition
function [varargout] = createResultGraph(results, x_field, y_field, plotOptions)

%% Get what should be on the X axis
if ischar(x_field)
    default_x_label = x_field;
else
    default_x_label = '';
end

%% Get the different algorithms from the results
algos = sort(fieldnames(results));
myalgo = getSubOption({}, 'cell', plotOptions, 'plot', 'emphasize');

if numel(myalgo) == 1 % && use_regexp_to_expand
    k = cellfun(@(x) ~isempty(regexp(x, myalgo{1}, 'ONCE')), algos);
    myalgo = algos(k);
end

% Set default style
algos = [intersect(algos, myalgo); setdiff(algos, myalgo)];
default_styles = repmat({'-', '--', '-.', ':'}, 1, ceil(numel(algos)/4));

%% Go through the options to get the layout etc.

fignum = getSubOption(187, 'double', plotOptions, 'figure', 'number');
figwidth = getSubOption(20, 'double', plotOptions, 'figure', 'width');
figheight = getSubOption(15, 'double', plotOptions, 'figure', 'height');
figunits = getSubOption('centimeters', 'char', plotOptions, 'figure', 'units');

% y_field = getSubOption('costs', 'char', plotOptions, 'plot', 'y_field');
% plotRange = getSubOption([], 'double', plotOptions, 'plot', 'range');
styles = getSubOption(default_styles, 'cell', plotOptions, 'plot', 'styles');
colors = getSubOption(cubehelix(numel(algos) + 1, .5, -1.5, 3, 1), 'double', plotOptions, 'plot', 'colors');
fixedStyles = getSubOption(struct, 'struct', plotOptions, 'plot', 'fixedStyles');
yfun = getSubOption(@(x) mean(x,2), 'function_handle', plotOptions, 'plot', 'y_fun');
xfun = getSubOption(@(x) mean(x,2), 'function_handle', plotOptions, 'plot', 'x_fun');
linewidth = getSubOption(2, 'double', plotOptions, 'plot', 'linewidth');
do_errorbar = getSubOption(false, 'logical', plotOptions, 'plot', 'errorbar');

% How to plot the error bar
lo_fun = getSubOption(@(x) mean(x,2) - std(x,[],2), 'function_handle', plotOptions, 'plot', 'low_error_fun');
hi_fun = getSubOption(@(x) mean(x,2) + std(x,[],2), 'function_handle', plotOptions, 'plot', 'hi_error_fun');
errorlinewidth = getSubOption(0.5, 'double', plotOptions, 'plot', 'errorlinewidth');

legendfont = getSubOption('times', 'char', plotOptions, 'legend', 'font');
legendsize = getSubOption(14, 'double', plotOptions, 'legend', 'fontsize');
legendlinewidth = getSubOption(1, 'double', plotOptions, 'legend', 'linewidth');
legendbox = getSubOption('off', 'char', plotOptions, 'legend', 'box');
legendloc = getSubOption('NorthEast', 'char', plotOptions, 'legend', 'location');

axesfont = getSubOption('times', 'char', plotOptions, 'axes', 'font');
axessize = getSubOption(14, 'double', plotOptions, 'axes', 'fontsize');
axeslinewidth = getSubOption(.25, 'double', plotOptions, 'axes', 'linewidth');

axesbox = getSubOption('on', 'char', plotOptions, 'axes', 'box');
axesgrid = getSubOption('on', 'char', plotOptions, 'axes', 'grid');
minorgrid = getSubOption('off', 'char', plotOptions, 'axes', 'minorgrid');
minortick = getSubOption('on', 'char', plotOptions, 'axes', 'minortick');

yscale = getSubOption('linear', 'char', plotOptions, 'axes', 'yscale');
yminval = getSubOption([], 'double', plotOptions, 'axes', 'ymin');
ymaxval = getSubOption([], 'double', plotOptions, 'axes', 'ymax');
xscale = getSubOption('linear', 'char', plotOptions, 'axes', 'xscale');
xmin = getSubOption([], 'double', plotOptions, 'axes', 'xmin');
xmax = getSubOption([], 'double', plotOptions, 'axes', 'xmax');

labelfont = getSubOption('times', 'char', plotOptions, 'label', 'font');
labelsize = getSubOption(16, 'double', plotOptions, 'label', 'fontsize');
x_label = getSubOption(default_x_label, 'char', plotOptions, 'label', 'X');
y_label = getSubOption(y_field, 'char', plotOptions, 'label', 'Y');

doExport = getSubOption(false, 'logical', plotOptions, 'export', 'do');
printoptions = getSubOption({'-transparent'}, 'cell', plotOptions, 'export', 'arguments');
outputfolder = getSubOption(pwd, 'char', plotOptions, 'export', 'folder');
expname = getSubOption('experiment', 'char', plotOptions, 'export', 'name');
format = getSubOption('eps', 'char', plotOptions, 'export', 'format');

%%
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end

%% Make the plot
fig = figure(fignum);
clf(fig);

y_label(1) = upper(y_label(1));
x_label(1) = upper(x_label(1));

set(fig, 'Units', figunits, 'Position', [3 3 figwidth figheight], ...
    'name', sprintf('%s for %s experiment', y_label, expname));

ax = cla;
hold(ax, 'on');
ymax = [];
for i = 1:numel(algos)
    y = yfun(results.(algos{i}).(y_field));
    x = xfun(results.(algos{i}).(x_field));
    
    if size(y,1) == 1
    	style = {'LineStyle', 'none', 'Marker', 'o'};
        x = max(x);
    else
        style = {'Marker', 'none'};
        
        if size(x,1) == 1
            % Old setting... why did we have this?
            % x = 1:numel(y);
            x = results.(algos{i}).(x_field);
        end
%         
%         if ~isempty(plotRange)
%             x = x(plotRange);
%             y = y(plotRange);
%         end
    end

    % Sometimes the plotRange is empty if Y adjusted to max length of Y
%     if isempty(x)
%         x = 1:numel(y);
%     end
    
    lw = linewidth;
    if strcmp(algos{i}, myalgo); lw = 1.5 * lw; end
    
    plotStyle = {styles{mod(i-1, numel(styles))+1}, ...
        'color', colors(mod(i-1, size(colors,1))+1,:), style{:}};
    if isfield(fixedStyles, algos{i})
        plotStyle = fixedStyles.(algos{i});
    end
    
    plot(ax, x, y, plotStyle{:}, 'linewidth', lw);
    
    if (do_errorbar)
        lo = lo_fun(results.(algos{i}).(y_field));
        hi = hi_fun(results.(algos{i}).(y_field));  
        addErrorBar(ax, x, y, lo, hi, 10, ...
            'linewidth', errorlinewidth, 'color', colors(mod(i-1, size(colors,1))+1,:));
        ymax = max([ymax; hi]);
    end
end
    
hl = legend(ax, algos{:}, 'Location', 'NorthWest');

ymax = max([ymax get(ax, 'YLim')]);
if ~isempty(ymaxval); ymax = ymaxval; end
if isempty(yminval); yminval = min(get(ax, 'YLim')); end

if isempty(xmin); xmin = min(get(ax, 'XLim')); end
if isempty(xmax); xmax = max(get(ax, 'XLim')); end

%% calculate where the ticks should go

% if strcmp(yscale,'log')
%     candidates = 0:10;
%     k = find(log10(ymax)./candidates < 5, 1, 'first');
%     ytick = [0 10.^(candidates(k) * (0:10))];
% else
%     base_candidates = [1 2 5];
%     factors = 10.^(0:8);
%     candidates = bsxfun(@times, base_candidates', factors);
%     candidates = sort(candidates(:));
%     k = find((ymax./candidates) < 5, 1, 'first');
%     ytick = 0:candidates(k):ymax;
% end

set(hl, 'fontsize', legendsize, 'fontname', legendfont, 'linewidth', ...
    legendlinewidth, 'Box', legendbox, 'Location', legendloc, 'Interpreter', 'none');
set(ax, 'fontsize', axessize, 'fontname', axesfont, 'linewidth', axeslinewidth, ...
    'YMinorGrid', minorgrid, 'YMinorTick', minortick, ...
    'XMinorGrid', minorgrid, 'XMinorTick', minortick, ...
    'Box', axesbox, 'YGrid', axesgrid, 'XGrid', axesgrid, ... 
    'YScale', yscale,  'XScale', xscale, 'XLim', [xmin xmax], ...
    'YLim', [yminval ymax]);%, 'YTick', ytick); %max(get(ax, 'YLim'))]);

yax = get(ax, 'YAxis');
if (ymax > 0)
    set(yax, 'Exponent', floor(log10(ymax)));
end

% ht = title('Solution cost', 'fontsize', titlesize, 'fontname', font, 'fontweight', titleweight);
xlabel(ax, x_label, 'fontsize', labelsize, 'fontname', labelfont);
ylabel(ax, y_label, 'fontsize', labelsize, 'fontname', labelfont);
 
filename = [];
if doExport
    filename = fullfile(outputfolder, sprintf('%s_%s.%s', expname, y_field, format));
    export_fig(fig, filename, printoptions{:}); 
end

if nargout > 0
    varargout{1} = filename;
end

end

function addErrorBar(ax,x,y,l,u,n,varargin)

sample = 1:n:numel(x);
x = x(sample);
y = y(sample);
l = l(sample);
u = u(sample);

npt = numel(x);
tee = (max(x(:))-min(x(:)))/100;  % make tee .02 x-distance for error bars
xl = x - tee;
xr = x + tee;
ytop = u;
ybot = l;
n = size(y,2);

% build up nan-separated vector for bars
xb = zeros(npt*9,n);
xb(1:9:end,:) = x;
xb(2:9:end,:) = x;
xb(3:9:end,:) = NaN;
xb(4:9:end,:) = xl;
xb(5:9:end,:) = xr;
xb(6:9:end,:) = NaN;
xb(7:9:end,:) = xl;
xb(8:9:end,:) = xr;
xb(9:9:end,:) = NaN;

yb = zeros(npt*9,n);
yb(1:9:end,:) = ytop;
yb(2:9:end,:) = ybot;
yb(3:9:end,:) = NaN;
yb(4:9:end,:) = ytop;
yb(5:9:end,:) = ytop;
yb(6:9:end,:) = NaN;
yb(7:9:end,:) = ybot;
yb(8:9:end,:) = ybot;
yb(9:9:end,:) = NaN;

plot(ax,xb,yb,'-',varargin{:});

end