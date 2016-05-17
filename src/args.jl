

const _allAxes = [:auto, :left, :right]
@compat const _axesAliases = KW(
    :a => :auto,
    :l => :left,
    :r => :right
  )

const _3dTypes = [:path3d, :scatter3d, :surface, :wireframe, :contour3d]
const _allTypes = vcat([
                        :none, :line, :path, :steppre, :steppost, :sticks, :scatter,
                        :heatmap, :hexbin, :hist, :hist2d, :hist3d, :density, :bar, :hline, :vline, :ohlc,
                        :contour, :pie, :shape, :image #, :boxplot, :violin, :quiver,
                       ], _3dTypes)
@compat const _typeAliases = KW(
    :n             => :none,
    :no            => :none,
    :l             => :line,
    :p             => :path,
    :stepinv       => :steppre,
    :stepsinv      => :steppre,
    :stepinverted  => :steppre,
    :stepsinverted => :steppre,
    :step          => :steppost,
    :steps         => :steppost,
    :stair         => :steppost,
    :stairs        => :steppost,
    :stem          => :sticks,
    :stems         => :sticks,
    :dots          => :scatter,
    :histogram     => :hist,
    :pdf           => :density,
    :contours      => :contour,
    :line3d        => :path3d,
    :surf          => :surface,
    :wire          => :wireframe,
    :shapes        => :shape,
    :poly          => :shape,
    :polygon       => :shape,
    :box           => :boxplot,
    :velocity      => :quiver,
    :gradient      => :quiver,
    :img           => :image,
    :imshow        => :image,
    :imagesc       => :image,
  )

like_histogram(seriestype::Symbol) = seriestype in (:hist, :density)
like_line(seriestype::Symbol)      = seriestype in (:line, :path, :steppre, :steppost)
like_surface(seriestype::Symbol)   = seriestype in (:contour, :contour3d, :heatmap, :surface, :wireframe, :image)

is3d(seriestype::Symbol) = seriestype in _3dTypes
is3d(d::KW) = trueOrAllTrue(is3d, d[:seriestype])

const _allStyles = [:auto, :solid, :dash, :dot, :dashdot, :dashdotdot]
@compat const _styleAliases = KW(
    :a    => :auto,
    :s    => :solid,
    :d    => :dash,
    :dd   => :dashdot,
    :ddd  => :dashdotdot,
  )

# const _allMarkers = [:none, :auto, :ellipse, :rect, :diamond, :utriangle, :dtriangle,
#                      :cross, :xcross, :star5, :star8, :hexagon, :octagon, Shape]
const _allMarkers = vcat(:none, :auto, sort(collect(keys(_shapes))))
@compat const _markerAliases = KW(
    :n            => :none,
    :no           => :none,
    :a            => :auto,
    :circle       => :ellipse,
    :c            => :ellipse,
    :square       => :rect,
    :sq           => :rect,
    :r            => :rect,
    :d            => :diamond,
    :^            => :utriangle,
    :ut           => :utriangle,
    :utri         => :utriangle,
    :uptri        => :utriangle,
    :uptriangle   => :utriangle,
    :v            => :dtriangle,
    :V            => :dtriangle,
    :dt           => :dtriangle,
    :dtri         => :dtriangle,
    :downtri      => :dtriangle,
    :downtriangle => :dtriangle,
    :+            => :cross,
    :plus         => :cross,
    :x            => :xcross,
    :X            => :xcross,
    :star         => :star5,
    :s            => :star5,
    :star1        => :star5,
    :s2           => :star8,
    :star2        => :star8,
    :p            => :pentagon,
    :pent         => :pentagon,
    :h            => :hexagon,
    :hex          => :hexagon,
    :hep          => :heptagon,
    :o            => :octagon,
    :oct          => :octagon,
    :spike        => :vline,
  )

const _allScales = [:identity, :ln, :log2, :log10, :asinh, :sqrt]
@compat const _scaleAliases = KW(
    :none => :identity,
    :log  => :log10,
  )

# -----------------------------------------------------------------------------

const _series_defaults = KW()

# series-specific
_series_defaults[:axis]            = :left
_series_defaults[:label]           = "AUTO"
_series_defaults[:seriescolor]     = :auto
_series_defaults[:seriesalpha]     = nothing
_series_defaults[:seriestype]        = :path
_series_defaults[:linestyle]       = :solid
_series_defaults[:linewidth]       = :auto
_series_defaults[:linecolor]       = :match
_series_defaults[:linealpha]       = nothing
_series_defaults[:fillrange]       = nothing   # ribbons, areas, etc
_series_defaults[:fillcolor]       = :match
_series_defaults[:fillalpha]       = nothing
_series_defaults[:markershape]     = :none
_series_defaults[:markercolor]     = :match
_series_defaults[:markeralpha]     = nothing
_series_defaults[:markersize]      = 6
_series_defaults[:markerstrokestyle] = :solid
_series_defaults[:markerstrokewidth] = 1
_series_defaults[:markerstrokecolor] = :match
_series_defaults[:markerstrokealpha] = nothing
_series_defaults[:bins]            = 30               # number of bins for hists
_series_defaults[:smooth]          = false               # regression line?
_series_defaults[:group]           = nothing           # groupby vector
_series_defaults[:x]               = nothing
_series_defaults[:y]               = nothing
_series_defaults[:z]               = nothing           # depth for contour, surface, etc
_series_defaults[:marker_z]        = nothing           # value for color scale
_series_defaults[:levels]          = 15
_series_defaults[:orientation]     = :vertical
_series_defaults[:bar_position]    = :overlay  # for bar plots and histograms: could also be stack (stack up) or dodge (side by side)
_series_defaults[:xerror]          = nothing
_series_defaults[:yerror]          = nothing
_series_defaults[:ribbon]          = nothing
_series_defaults[:quiver]          = nothing
_series_defaults[:arrow]           = nothing   # allows for adding arrows to line/path... call `arrow(args...)`
_series_defaults[:normalize]       = false     # do we want a normalized histogram?
_series_defaults[:weights]         = nothing   # optional weights for histograms (1D and 2D)
_series_defaults[:contours]        = false     # add contours to 3d surface and wireframe plots
_series_defaults[:match_dimensions] = false   # do rows match x (true) or y (false) for heatmap/image/spy? see issue 196
                                             # this ONLY effects whether or not the z-matrix is transposed for a heatmap display!
_series_defaults[:subplot]   = :auto         # which subplot(s) does this series belong to?


const _plot_defaults = KW()

_plot_defaults[:title]             = ""
_plot_defaults[:legend]            = :best
_plot_defaults[:colorbar]          = :legend
_plot_defaults[:background_color]            = colorant"white"   # default for all backgrounds
_plot_defaults[:background_color_outside]    = :match            # background outside grid
_plot_defaults[:foreground_color]            = :auto             # default for all foregrounds
_plot_defaults[:size]              = (600,400)
_plot_defaults[:pos]               = (0,0)
_plot_defaults[:windowtitle]       = "Plots.jl"
_plot_defaults[:show]              = false
_plot_defaults[:layout]            = :auto
_plot_defaults[:num_subplots]      = -1
_plot_defaults[:num_rows]          = -1
_plot_defaults[:num_cols]          = -1
_plot_defaults[:color_palette]     = :auto
_plot_defaults[:link]              = false
_plot_defaults[:linkx]             = false
_plot_defaults[:linky]             = false
_plot_defaults[:linkfunc]          = nothing
_plot_defaults[:overwrite_figure]  = false


const _subplot_defaults = KW()

_subplot_defaults[:title]                   = ""
_subplot_defaults[:background_color_legend] = :match            # background of legend
_subplot_defaults[:background_color_inside] = :match            # background inside grid
_subplot_defaults[:foreground_color_legend] = :match            # foreground of legend
_subplot_defaults[:foreground_color_grid]   = :match            # grid color
_subplot_defaults[:legendfont]              = font(8)
_subplot_defaults[:grid]                    = true
_subplot_defaults[:annotation]              = nothing           # annotation tuple(s)... (x,y,annotation)
_subplot_defaults[:polar]                   = false
_subplot_defaults[:aspect_ratio]            = :none             # choose from :none or :equal

const _axis_defaults = KW()

_axis_defaults[:label]     = :auto
_axis_defaults[:xlims]     = :auto
_axis_defaults[:xticks]    = :auto
_axis_defaults[:xscale]    = :identity
_axis_defaults[:xrotation] = 0
_axis_defaults[:xflip]     = false
# _axis_defaults[:axis]      = :auto
_axis_defaults[:tickfont]  = font(8)
_axis_defaults[:guidefont] = font(11)
_axis_defaults[:foreground_color_axis]   = :match            # axis border/tick colors
_axis_defaults[:foreground_color_border] = :match            # plot area border/spines
_axis_defaults[:foreground_color_text]   = :match            # tick text color
_axis_defaults[:foreground_color_guide]  = :match            # guide text color

const _all_defaults = KW[
    _series_defaults,
    _plot_defaults,
    _subplot_defaults,
    _axis_defaults
]

const _all_args = sort(collect(union(map(keys, _all_defaults)...)))
supportedArgs(::AbstractBackend) = error("supportedArgs not defined") #_all_args
supportedArgs() = supportedArgs(backend())

RecipesBase.is_key_supported(k::Symbol) = (k in supportedArgs())

# -----------------------------------------------------------------------------

makeplural(s::Symbol) = symbol(string(s,"s"))

autopick(arr::AVec, idx::Integer) = arr[mod1(idx,length(arr))]
autopick(notarr, idx::Integer) = notarr

autopick_ignore_none_auto(arr::AVec, idx::Integer) = autopick(setdiff(arr, [:none, :auto]), idx)
autopick_ignore_none_auto(notarr, idx::Integer) = notarr

function aliasesAndAutopick(d::KW, sym::Symbol, aliases::KW, options::AVec, plotIndex::Int)
    if d[sym] == :auto
        d[sym] = autopick_ignore_none_auto(options, plotIndex)
    elseif haskey(aliases, d[sym])
        d[sym] = aliases[d[sym]]
    end
end

function aliases(aliasMap::KW, val)
    sortedkeys(filter((k,v)-> v==val, aliasMap))
end

# -----------------------------------------------------------------------------

const _keyAliases = KW()

function add_aliases(sym::Symbol, aliases::Symbol...)
    for alias in aliases
        if haskey(_keyAliases, alias)
            error("Already an alias $alias => $(_keyAliases[alias])... can't also alias $sym")
        end
        _keyAliases[alias] = sym
    end
end

# colors
add_aliases(:seriescolor, :c, :color, :colour)
add_aliases(:linecolor, :lc, :lcolor, :lcolour, :linecolour)
add_aliases(:markercolor, :mc, :mcolor, :mcolour, :markercolour)
add_aliases(:markerstokecolor, :msc, :mscolor, :mscolour, :markerstokecolour)
add_aliases(:fillcolor, :fc, :fcolor, :fcolour, :fillcolour)

add_aliases(:background_color, :bg, :bgcolor, :bg_color, :background,
                              :background_colour, :bgcolour, :bg_colour)
add_aliases(:background_color_legend, :bg_legend, :bglegend, :bgcolor_legend, :bg_color_legend, :background_legend,
                              :background_colour_legend, :bgcolour_legend, :bg_colour_legend)
add_aliases(:background_color_inside, :bg_inside, :bginside, :bgcolor_inside, :bg_color_inside, :background_inside,
                              :background_colour_inside, :bgcolour_inside, :bg_colour_inside)
add_aliases(:background_color_outside, :bg_outside, :bgoutside, :bgcolor_outside, :bg_color_outside, :background_outside,
                              :background_colour_outside, :bgcolour_outside, :bg_colour_outside)
add_aliases(:foreground_color, :fg, :fgcolor, :fg_color, :foreground,
                            :foreground_colour, :fgcolour, :fg_colour)
add_aliases(:foreground_color_legend, :fg_legend, :fglegend, :fgcolor_legend, :fg_color_legend, :foreground_legend,
                            :foreground_colour_legend, :fgcolour_legend, :fg_colour_legend)
add_aliases(:foreground_color_grid, :fg_grid, :fggrid, :fgcolor_grid, :fg_color_grid, :foreground_grid,
                            :foreground_colour_grid, :fgcolour_grid, :fg_colour_grid, :gridcolor)
add_aliases(:foreground_color_axis, :fg_axis, :fgaxis, :fgcolor_axis, :fg_color_axis, :foreground_axis,
                            :foreground_colour_axis, :fgcolour_axis, :fg_colour_axis, :axiscolor)
add_aliases(:foreground_color_border, :fg_border, :fgborder, :fgcolor_border, :fg_color_border, :foreground_border,
                            :foreground_colour_border, :fgcolour_border, :fg_colour_border, :bordercolor, :border)
add_aliases(:foreground_color_text, :fg_text, :fgtext, :fgcolor_text, :fg_color_text, :foreground_text,
                            :foreground_colour_text, :fgcolour_text, :fg_colour_text, :textcolor)
add_aliases(:foreground_color_guide, :fg_guide, :fgguide, :fgcolor_guide, :fg_color_guide, :foreground_guide,
                            :foreground_colour_guide, :fgcolour_guide, :fg_colour_guide, :guidecolor)

# alphas
add_aliases(:seriesalpha, :alpha, :α, :opacity)
add_aliases(:linealpha, :la, :lalpha, :lα, :lineopacity, :lopacity)
add_aliases(:makeralpha, :ma, :malpha, :mα, :makeropacity, :mopacity)
add_aliases(:markerstrokealpha, :msa, :msalpha, :msα, :markerstrokeopacity, :msopacity)
add_aliases(:fillalpha, :fa, :falpha, :fα, :fillopacity, :fopacity)

# series attributes
add_aliases(:seriestype, :st, :t, :typ, :linetype, :lt)
add_aliases(:label, :lab)
add_aliases(:line, :l)
add_aliases(:linewidth, :w, :width, :lw)
add_aliases(:linestyle, :style, :s, :ls)
add_aliases(:marker, :m, :mark)
add_aliases(:markershape, :shape)
add_aliases(:markersize, :ms, :msize)
add_aliases(:marker_z, :markerz, :zcolor)
add_aliases(:fill, :f, :area)
add_aliases(:fillrange, :fillrng, :frange, :fillto, :fill_between)
add_aliases(:group, :g, :grouping)
add_aliases(:bins, :bin, :nbin, :nbins, :nb)
add_aliases(:ribbon, :rib)
add_aliases(:annotation, :ann, :anns, :annotate, :annotations)
add_aliases(:xlabel, :xlab, :xl)
add_aliases(:xlims, :xlim, :xlimit, :xlimits)
add_aliases(:xticks, :xtick)
add_aliases(:xrotation, :xrot, :xr)
add_aliases(:ylabel, :ylab, :yl)
add_aliases(:ylims, :ylim, :ylimit, :ylimits)
add_aliases(:yticks, :ytick)
add_aliases(:yrightlabel, :yrlab, :yrl, :ylabel2, :y2label, :ylab2, :y2lab, :ylabr, :ylabelright)
add_aliases(:yrightlims, :yrlim, :yrlimit, :yrlimits)
add_aliases(:yrightticks, :yrtick)
add_aliases(:yrotation, :yrot, :yr)
add_aliases(:zlabel, :zlab, :zl)
add_aliases(:zlims, :zlim, :zlimit, :zlimits)
add_aliases(:zticks, :ztick)
add_aliases(:zrotation, :zrot, :zr)
add_aliases(:legend, :leg, :key)
add_aliases(:colorbar, :cb, :cbar, :colorkey)
add_aliases(:smooth, :regression, :reg)
add_aliases(:levels, :nlevels, :nlev, :levs)
add_aliases(:size, :windowsize, :wsize)
add_aliases(:windowtitle, :wtitle)
add_aliases(:show, :gui, :display)
add_aliases(:color_palette, :palette)
add_aliases(:linkx, :xlink)
add_aliases(:linky, :ylink)
add_aliases(:num_subplots, :n, :numplots, :nplts)
add_aliases(:num_rows, :nr, :nrow, :nrows, :rows)
add_aliases(:num_cols, :nc, :ncol, :ncols, :cols, :ncolumns, :columns)
add_aliases(:overwrite_figure, :clf, :clearfig, :overwrite, :reuse)
add_aliases(:xerror, :xerr, :xerrorbar)
add_aliases(:yerror, :yerr, :yerrorbar, :err, :errorbar)
add_aliases(:quiver, :velocity, :quiver2d, :gradient)
add_aliases(:normalize, :norm, :normed, :normalized)
add_aliases(:aspect_ratio, :aspectratio, :axis_ratio, :axisratio, :ratio)
add_aliases(:match_dimensions, :transpose, :transpose_z)


# add all pluralized forms to the _keyAliases dict
for arg in keys(_series_defaults)
    _keyAliases[makeplural(arg)] = arg
end



# -----------------------------------------------------------------------------

# update the defaults globally

"""
`default(key)` returns the current default value for that key
`default(key, value)` sets the current default value for that key
`default(; kw...)` will set the current default value for each key/value pair
"""

function default(k::Symbol)
    k = get(_keyAliases, k, k)
    for defaults in _all_defaults
        if haskey(defaults, k)
            return defaults[k]
        end
    end
    error("Unknown key: ", k)
    # if haskey(_series_defaults, k)
    #     return _series_defaults[k]
    # elseif haskey(_plot_defaults, k)
    #     return _plot_defaults[k]
    # else
    #     error("Unknown key: ", k)
    # end
end

function default(k::Symbol, v)
    k = get(_keyAliases, k, k)
    for defaults in _all_defaults
        if haskey(defaults, k)
            defaults[k] = v
            return v
        end
    end
    error("Unknown key: ", k)
    # if haskey(_series_defaults, k)
    #     _series_defaults[k] = v
    # elseif haskey(_plot_defaults, k)
    #     _plot_defaults[k] = v
    # else
    #     error("Unknown key: ", k)
    # end
end

function default(; kw...)
    for (k,v) in kw
        default(k, v)
    end
end


# -----------------------------------------------------------------------------

# if arg is a valid color value, then set d[csym] and return true
function handleColors!(d::KW, arg, csym::Symbol)
    try
        if arg == :auto
            d[csym] = :auto
        else
            c = colorscheme(arg)
            d[csym] = c
        end
        return true
    end
    false
end

# given one value (:log, or :flip, or (-1,1), etc), set the appropriate arg
# TODO: use trueOrAllTrue for subplots which can pass vectors for these
function processAxisArg(d::KW, letter::AbstractString, arg)
    T = typeof(arg)
    arg = get(_scaleAliases, arg, arg)
    scale, flip, label, lim, tick = axis_symbols(letter, "scale", "flip", "label", "lims", "ticks")

    if typeof(arg) <: Font
        d[:tickfont] = arg

    elseif arg in _allScales
        d[scale] = arg

    elseif arg in (:flip, :invert, :inverted)
        d[flip] = true

    elseif T <: @compat(AbstractString)
        d[label] = arg

    # xlims/ylims
    elseif (T <: Tuple || T <: AVec) && length(arg) == 2
        d[typeof(arg[1]) <: Number ? lim : tick] = arg

    # xticks/yticks
    elseif T <: AVec
        d[tick] = arg

    elseif arg == nothing
        d[tick] = []

    else
        warn("Skipped $(letter)axis arg $arg")

    end
end


function processLineArg(d::KW, arg)
    # seriestype
    if allLineTypes(arg)
        d[:seriestype] = arg

    # linestyle
    elseif allStyles(arg)
        d[:linestyle] = arg

    elseif typeof(arg) <: Stroke
        arg.width == nothing || (d[:linewidth] = arg.width)
        arg.color == nothing || (d[:linecolor] = arg.color == :auto ? :auto : colorscheme(arg.color))
        arg.alpha == nothing || (d[:linealpha] = arg.alpha)
        arg.style == nothing || (d[:linestyle] = arg.style)

    elseif typeof(arg) <: Brush
        arg.size  == nothing || (d[:fillrange] = arg.size)
        arg.color == nothing || (d[:fillcolor] = arg.color == :auto ? :auto : colorscheme(arg.color))
        arg.alpha == nothing || (d[:fillalpha] = arg.alpha)

    elseif typeof(arg) <: Arrow || arg in (:arrow, :arrows)
        d[:arrow] = arg

    # linealpha
    elseif allAlphas(arg)
        d[:linealpha] = arg

    # linewidth
    elseif allReals(arg)
        d[:linewidth] = arg

    # color
    elseif !handleColors!(d, arg, :linecolor)
        warn("Skipped line arg $arg.")

    end
end


function processMarkerArg(d::KW, arg)
    # markershape
    if allShapes(arg)
        d[:markershape] = arg

    # stroke style
    elseif allStyles(arg)
        d[:markerstrokestyle] = arg

    elseif typeof(arg) <: Stroke
        arg.width == nothing || (d[:markerstrokewidth] = arg.width)
        arg.color == nothing || (d[:markerstrokecolor] = arg.color == :auto ? :auto : colorscheme(arg.color))
        arg.alpha == nothing || (d[:markerstrokealpha] = arg.alpha)
        arg.style == nothing || (d[:markerstrokestyle] = arg.style)

    elseif typeof(arg) <: Brush
        arg.size  == nothing || (d[:markersize]  = arg.size)
        arg.color == nothing || (d[:markercolor] = arg.color == :auto ? :auto : colorscheme(arg.color))
        arg.alpha == nothing || (d[:markeralpha] = arg.alpha)

    # linealpha
    elseif allAlphas(arg)
        d[:markeralpha] = arg

    # markersize
    elseif allReals(arg)
        d[:markersize] = arg

    # markercolor
    elseif !handleColors!(d, arg, :markercolor)
        warn("Skipped marker arg $arg.")

    end
end


function processFillArg(d::KW, arg)
    if typeof(arg) <: Brush
        arg.size  == nothing || (d[:fillrange] = arg.size)
        arg.color == nothing || (d[:fillcolor] = arg.color == :auto ? :auto : colorscheme(arg.color))
        arg.alpha == nothing || (d[:fillalpha] = arg.alpha)

    # fillrange function
    elseif allFunctions(arg)
        d[:fillrange] = arg

    # fillalpha
    elseif allAlphas(arg)
        d[:fillalpha] = arg

    elseif !handleColors!(d, arg, :fillcolor)

        d[:fillrange] = arg
    end
end

_replace_markershape(shape::Symbol) = get(_markerAliases, shape, shape)
_replace_markershape(shapes::AVec) = map(_replace_markershape, shapes)
_replace_markershape(shape) = shape

function _add_markershape(d::KW)
    # add the markershape if it needs to be added... hack to allow "m=10" to add a shape,
    # and still allow overriding in _apply_recipe
    ms = pop!(d, :markershape_to_add, :none)
    if !haskey(d, :markershape) && ms != :none
        d[:markershape] = ms
    end
end

"Handle all preprocessing of args... break out colors/sizes/etc and replace aliases."
function preprocessArgs!(d::KW)
    replaceAliases!(d, _keyAliases)

    # handle axis args
    for letter in ("x", "y", "z")
        asym = symbol(letter * "axis")
        for arg in wraptuple(pop!(d, asym, ()))
            processAxisArg(d, letter, arg)
        end
        # delete!(d, asym)

        # # NOTE: this logic was moved to _add_plotargs...
        # # turn :labels into :ticks_and_labels
        # tsym = symbol(letter * "ticks")
        # if haskey(d, tsym) && ticksType(d[tsym]) == :labels
        #     d[tsym] = (1:length(d[tsym]), d[tsym])
        # end
        #
        # ssym = symbol(letter * "scale")
        # if haskey(d, ssym) && haskey(_scaleAliases, d[ssym])
        #     d[ssym] = _scaleAliases[d[ssym]]
        # end
    end

    # handle line args
    for arg in wraptuple(pop!(d, :line, ()))
        processLineArg(d, arg)
    end

    if haskey(d, :seriestype) && haskey(_typeAliases, d[:seriestype])
        d[:seriestype] = _typeAliases[d[:seriestype]]
    end

    # handle marker args... default to ellipse if shape not set
    anymarker = false
    for arg in wraptuple(get(d, :marker, ()))
        processMarkerArg(d, arg)
        anymarker = true
    end
    delete!(d, :marker)
    if haskey(d, :markershape)
        d[:markershape] = _replace_markershape(d[:markershape])
    elseif anymarker
        d[:markershape_to_add] = :ellipse  # add it after _apply_recipe
    end

    # handle fill
    for arg in wraptuple(get(d, :fill, ()))
        processFillArg(d, arg)
    end
    delete!(d, :fill)

  # convert into strokes and brushes

    if haskey(d, :arrow)
        a = d[:arrow]
        d[:arrow] = if a == true
            arrow()
        elseif a == false
            nothing
        elseif !(typeof(a) <: Arrow)
            arrow(wraptuple(a)...)
        else
            a
        end
    end


    if get(d, :arrow, false) == true
        d[:arrow] = arrow()
    end

    # legends
    if haskey(d, :legend)
        d[:legend] = convertLegendValue(d[:legend])
    end
    if haskey(d, :colorbar)
        d[:colorbar] = convertLegendValue(d[:colorbar])
    end

    # handle subplot links
    if haskey(d, :link)
        l = d[:link]
        if isa(l, Bool)
            d[:linkx] = l
            d[:linky] = l
        elseif isa(l, Function)
            d[:linkx] = true
            d[:linky] = true
            d[:linkfunc] = l
        else
            warn("Unhandled/invalid link $l.  Should be a Bool or a function mapping (row,column) -> (linkx, linky), where linkx/y can be Bool or Void (nothing)")
        end
        delete!(d, :link)
    end

    # pull out invalid keywords into their own KW dict... these are likely user-defined through recipes
    kw = KW()
    for k in keys(d)
        try
            # this should error for invalid keywords (assume they are user-defined)
            k == :markershape_to_add || default(k)
        catch
            # not a valid key... pop and add to user list
            kw[k] = pop!(d, k)
        end
    end
    kw
end

# -----------------------------------------------------------------------------

"A special type that will break up incoming data into groups, and allow for easier creation of grouped plots"
type GroupBy
    groupLabels::Vector{UTF8String}   # length == numGroups
    groupIds::Vector{Vector{Int}}     # list of indices for each group
end


# this is when given a vector-type of values to group by
function extractGroupArgs(v::AVec, args...)
    groupLabels = sort(collect(unique(v)))
    n = length(groupLabels)
    if n > 20
        warn("You created n=$n groups... Is that intended?")
    end
    groupIds = Vector{Int}[filter(i -> v[i] == glab, 1:length(v)) for glab in groupLabels]
    GroupBy(map(string, groupLabels), groupIds)
end


# expecting a mapping of "group label" to "group indices"
function extractGroupArgs{T, V<:AVec{Int}}(idxmap::Dict{T,V}, args...)
    groupLabels = sortedkeys(idxmap)
    groupIds = VecI[collect(idxmap[k]) for k in groupLabels]
    GroupBy(groupLabels, groupIds)
end

filter_data(v::AVec, idxfilter::AVec{Int}) = v[idxfilter]
filter_data(v, idxfilter) = v

function filter_data!(d::KW, idxfilter)
    for s in (:x, :y, :z)
        d[s] = filter_data(get(d, s, nothing), idxfilter)
    end
end

function _filter_input_data!(d::KW)
    idxfilter = pop!(d, :idxfilter, nothing)
    if idxfilter != nothing
        filter_data!(d, idxfilter)
    end
end


# -----------------------------------------------------------------------------

function warnOnUnsupportedArgs(pkg::AbstractBackend, d::KW)
    for k in sortedkeys(d)
        if (!(k in supportedArgs(pkg))
                # && k != :subplot
                && d[k] != default(k))
            warn("Keyword argument $k not supported with $pkg.  Choose from: $(supportedArgs(pkg))")
        end
    end
end

_markershape_supported(pkg::AbstractBackend, shape::Symbol) = shape in supportedMarkers(pkg)
_markershape_supported(pkg::AbstractBackend, shape::Shape) = Shape in supportedMarkers(pkg)
_markershape_supported(pkg::AbstractBackend, shapes::AVec) = all([_markershape_supported(pkg, shape) for shape in shapes])

function warnOnUnsupported(pkg::AbstractBackend, d::KW)
    (d[:axis] in supportedAxes(pkg)
        || warn("axis $(d[:axis]) is unsupported with $pkg.  Choose from: $(supportedAxes(pkg))"))
    (d[:seriestype] == :none
        || d[:seriestype] in supportedTypes(pkg)
        || warn("seriestype $(d[:seriestype]) is unsupported with $pkg.  Choose from: $(supportedTypes(pkg))"))
    (d[:linestyle] in supportedStyles(pkg)
        || warn("linestyle $(d[:linestyle]) is unsupported with $pkg.  Choose from: $(supportedStyles(pkg))"))
    (d[:markershape] == :none
        || _markershape_supported(pkg, d[:markershape])
        || warn("markershape $(d[:markershape]) is unsupported with $pkg.  Choose from: $(supportedMarkers(pkg))"))
end

function warnOnUnsupportedScales(pkg::AbstractBackend, d::KW)
  for k in (:xscale, :yscale)
    if haskey(d, k)
      d[k] in supportedScales(pkg) || warn("scale $(d[k]) is unsupported with $pkg.  Choose from: $(supportedScales(pkg))")
    end
  end
end


# -----------------------------------------------------------------------------

# 1-row matrices will give an element
# multi-row matrices will give a column
# InputWrapper just gives the contents
# anything else is returned as-is
# getArgValue(v::Tuple, idx::Int) = v[mod1(idx, length(v))]
function getArgValue(v::AMat, idx::Int)
    c = mod1(idx, size(v,2))
    size(v,1) == 1 ? v[1,c] : v[:,c]
end
getArgValue(wrapper::InputWrapper, idx) = wrapper.obj
getArgValue(v, idx) = v


# given an argument key (k), we want to extract the argument value for this index.
# if nothing is set (or container is empty), return the default.
function setDictValue(d_in::KW, d_out::KW, k::Symbol, idx::Int, defaults::KW)
    if haskey(d_in, k) && !(typeof(d_in[k]) <: Union{AbstractMatrix, Tuple} && isempty(d_in[k]))
        d_out[k] = getArgValue(d_in[k], idx)
    else
        d_out[k] = deepcopy(defaults[k])
    end
end

function convertLegendValue(val::Symbol)
    if val in (:both, :all, :yes)
        :best
    elseif val in (:no, :none)
        :none
    elseif val in (:right, :left, :top, :bottom, :inside, :best, :legend, :topright, :topleft, :bottomleft, :bottomright)
        val
    else
        error("Invalid symbol for legend: $val")
    end
end
convertLegendValue(val::Bool) = val ? :best : :none

# -----------------------------------------------------------------------------

# build the argument dictionary for the plot
function getPlotArgs(pkg::AbstractBackend, kw, idx::Int; set_defaults = true)
    kwdict = KW(kw)
    d = KW()

    # add defaults?
    if set_defaults
        for k in keys(_plot_defaults)
            setDictValue(kwdict, d, k, idx, _plot_defaults)
        end
    end
    #
    # for k in (:xscale, :yscale)
    #     if haskey(_scaleAliases, d[k])
    #         d[k] = _scaleAliases[d[k]]
    #     end
    # end

    # handle legend/colorbar
    d[:legend] = convertLegendValue(d[:legend])
    d[:colorbar] = convertLegendValue(d[:colorbar])
    if d[:colorbar] == :legend
        d[:colorbar] = d[:legend]
    end

    # convert color
    handlePlotColors(pkg, d)

    # no need for these
    delete!(d, :x)
    delete!(d, :y)

    d
end

function has_black_border_for_default(st::Symbol)
    like_histogram(st) || st in (:hexbin, :bar)
end
#
# # build the argument dictionary for a series
# function getSeriesArgs(pkg::AbstractBackend, plotargs::KW, kw, commandIndex::Int, plotIndex::Int, globalIndex::Int)  # TODO, pass in plotargs, not plt
#     kwdict = KW(kw)
#     d = KW()
#
#     # add defaults?
#     for k in keys(_series_defaults)
#         setDictValue(kwdict, d, k, commandIndex, _series_defaults)
#     end
#
#     # groupby args?
#     for k in (:idxfilter, :numUncounted, :dataframe)
#         if haskey(kwdict, k)
#             d[k] = kwdict[k]
#         end
#     end
#
#     if haskey(_typeAliases, d[:seriestype])
#         d[:seriestype] = _typeAliases[d[:seriestype]]
#     end
#
#     aliasesAndAutopick(d, :axis, _axesAliases, supportedAxes(pkg), plotIndex)
#     aliasesAndAutopick(d, :linestyle, _styleAliases, supportedStyles(pkg), plotIndex)
#     aliasesAndAutopick(d, :markershape, _markerAliases, supportedMarkers(pkg), plotIndex)
#
#     # update color
#     d[:seriescolor] = getSeriesRGBColor(d[:seriescolor], plotargs, plotIndex)
#
#     # # update linecolor
#     # c = d[:linecolor]
#     # c = (c == :match ? d[:seriescolor] : getSeriesRGBColor(c, plotargs, plotIndex))
#     # d[:linecolor] = c
#
#     # # update markercolor
#     # c = d[:markercolor]
#     # c = (c == :match ? d[:seriescolor] : getSeriesRGBColor(c, plotargs, plotIndex))
#     # d[:markercolor] = c
#
#     # # update fillcolor
#     # c = d[:fillcolor]
#     # c = (c == :match ? d[:seriescolor] : getSeriesRGBColor(c, plotargs, plotIndex))
#     # d[:fillcolor] = c
#
#     # update colors
#     for csym in (:linecolor, :markercolor, :fillcolor)
#         d[csym] = if d[csym] == :match
#             if has_black_border_for_default(d[:seriestype]) && csym == :linecolor
#                 :black
#             else
#                 d[:seriescolor]
#             end
#         else
#             getSeriesRGBColor(d[csym], plotargs, plotIndex)
#         end
#     end
#
#     # update markerstrokecolor
#     c = d[:markerstrokecolor]
#     c = (c == :match ? plotargs[:foreground_color] : getSeriesRGBColor(c, plotargs, plotIndex))
#     d[:markerstrokecolor] = c
#
#     # update alphas
#     for asym in (:linealpha, :markeralpha, :markerstrokealpha, :fillalpha)
#         if d[asym] == nothing
#             d[asym] = d[:seriesalpha]
#         end
#     end
#
#     # scatter plots don't have a line, but must have a shape
#     if d[:seriestype] in (:scatter, :scatter3d)
#         d[:linewidth] = 0
#         if d[:markershape] == :none
#             d[:markershape] = :ellipse
#         end
#     end
#
#     # set label
#     label = d[:label]
#     label = (label == "AUTO" ? "y$globalIndex" : label)
#     if d[:axis] == :right && !(length(label) >= 4 && label[end-3:end] != " (R)")
#         label = string(label, " (R)")
#     end
#     d[:label] = label
#
#     warnOnUnsupported(pkg, d)
#
#     d
# end
