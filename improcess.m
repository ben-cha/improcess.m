function varargout = improcess(im, funcs, args, varargin)

nOutputs = nargout;
varargout = cell(1,nOutputs);
if nOutputs > 1
    procedural = true;
    ims = cell(1,numel(funcs)+1);
else
    procedural = false;
end

p = inputParser;

imcond = @(x) ismatrix(x) || (ndims(x) == 3 && size(x,3)==3);
funcscond = @(x) iscell(x) && numel(x) == numel(args) && isa(x{1},'function_handle') ;
argscond = @(x) iscell(x) && numel(x) == numel(funcs) ; % 
% ordercond = @(x) isequal(sort(x), 1:numel(funcs));
ordercond = @(x) all(ismember(x, 1:numel(funcs)));
labcond = @(x) iscell(x) && (ischar(x{1}) || isstring(x));

addRequired(p,'im', imcond);
addRequired(p,'funcs', funcscond);
addRequired(p,'args', argscond);
addOptional(p,'order', [], ordercond);
addParameter(p,'show', false, @islogical)
addParameter(p,'labels', [], labcond)

parse(p,im,funcs,args, varargin{:});

im      = p.Results.im;
funcs   = p.Results.funcs;
args    = p.Results.args;
order   = p.Results.order;
shw     = p.Results.show;
labs    = p.Results.labels;

if ~isempty(order)
    funcs = funcs(order);
    args = args(order);
end

temp = im;
ims{1} = im;
for i = 1 : numel(funcs)
    thisfun = funcs{i};
    thisarg = args{i};
    if isa(thisarg, 'function_handle')
        thisarg = thisarg(temp);
    end
    if isempty(thisarg)
        temp = thisfun(temp);
    elseif ~iscell(thisarg)
        temp = thisfun(temp,thisarg);
    else
        temp = thisfun(temp,thisarg{:});
    end
    if ~isequal(class(im), class(temp))
        % convert image to original format
        % works on all formats except (u)int32
        tempfun = str2func(['im2' class(im)]);
        temp = tempfun(temp);
    end
    if procedural
        ims{i+1} = temp;
    end
end

switch nOutputs
    case 2
        varargout{1} = temp;
        varargout{2} = ims;
        if shw
            figure;
            makemontage(ims, funcs, labs)
        end
    case 3
        varargout{1} = temp;
        varargout{2} = ims;
        fig = figure('Visible','off');
        makemontage(ims,funcs);
        h = getframe(fig);
        varargout{3} = h.cdata;
        if shw
            set(fig,'Visible', 'on');
        else
            close(fig)
        end
    otherwise
        varargout{1} = temp;
        if shw
            figure; imshow(temp,[]);
        end
end

% rangefilt?

end

function makemontage(ims, funcs, labs)
tiledlayout('flow', 'TileSpacing','tight', 'Padding','compact');
nexttile
imshow(ims{1},[]);
title('original');
for j = 2:numel(ims)
    nexttile
    imshow(ims{j},[]);
    if ~isempty(labs) && ~isempty(labs{j-1})
        lab = labs{j-1};
    else
        lab = func2str(funcs{j-1});
    end
    title(['Step ' num2str(j-1) ': ' lab])
end
end