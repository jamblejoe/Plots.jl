using Contour: Contour
using UUIDs
Base.@kwdef mutable struct PGFPlotsXPlot
    is_created::Bool = false
    was_shown::Bool = false
    the_plot::PGFPlotsX.TikzDocument = PGFPlotsX.TikzDocument()
    function PGFPlotsXPlot(is_created, was_shown, the_plot)
        pgfx_plot = new(is_created, was_shown, the_plot)
        # tikz libraries
        PGFPlotsX.push_preamble!(
            pgfx_plot.the_plot,
            "\\usetikzlibrary{arrows.meta}",
        )
        PGFPlotsX.push_preamble!(
            pgfx_plot.the_plot,
            "\\usetikzlibrary{backgrounds}",
        )
        # pgfplots libraries
        PGFPlotsX.push_preamble!(
            pgfx_plot.the_plot,
            "\\usepgfplotslibrary{patchplots}",
        )
        PGFPlotsX.push_preamble!(
            pgfx_plot.the_plot,
            "\\usepgfplotslibrary{fillbetween}",
        )
        # compatibility fixes
        # add background layer to standard layers
        PGFPlotsX.push_preamble!(
            pgfx_plot.the_plot,
            raw"""
            \pgfplotsset{%
            layers/standard/.define layer set={%
                background,axis background,axis grid,axis ticks,axis lines,axis tick labels,pre main,main,axis descriptions,axis foreground%
            }{grid style= {/pgfplots/on layer=axis grid},%
                tick style= {/pgfplots/on layer=axis ticks},%
                axis line style= {/pgfplots/on layer=axis lines},%
                label style= {/pgfplots/on layer=axis descriptions},%
                legend style= {/pgfplots/on layer=axis descriptions},%
                title style= {/pgfplots/on layer=axis descriptions},%
                colorbar style= {/pgfplots/on layer=axis descriptions},%
                ticklabel style= {/pgfplots/on layer=axis tick labels},%
                axis background@ style={/pgfplots/on layer=axis background},%
                3d box foreground style={/pgfplots/on layer=axis foreground},%
                },
            }
            """,
        )
        pgfx_plot
    end
end

## end user utility functions
function pgfx_axes(pgfx_plot::PGFPlotsXPlot)
    return pgfx_plot.the_plot.elements[1].elements
end

pgfx_preamble() = pgfx_preamble(current())
function pgfx_preamble(pgfx_plot::Plot{PGFPlotsXBackend})
    old_flag = pgfx_plot.attr[:tex_output_standalone]
    pgfx_plot.attr[:tex_output_standalone] = true
    fulltext = String(repr("application/x-tex", pgfx_plot))
    preamble = fulltext[1:(first(findfirst("\\begin{document}", fulltext)) - 1)]
    pgfx_plot.attr[:tex_output_standalone] = old_flag
    preamble
end
##

function surface_to_vecs(x::AVec, y::AVec, s::Union{AMat,Surface})
    a = Array(s)
    xn = Vector{eltype(x)}(undef, length(a))
    yn = Vector{eltype(y)}(undef, length(a))
    zn = Vector{eltype(s)}(undef, length(a))
    for (n, (i, j)) in enumerate(Tuple.(CartesianIndices(a)))
        xn[n] = x[j]
        yn[n] = y[i]
        zn[n] = a[i, j]
    end
    return xn, yn, zn
end

function Base.push!(pgfx_plot::PGFPlotsXPlot, item)
    push!(pgfx_plot.the_plot, item)
end

function (pgfx_plot::PGFPlotsXPlot)(plt::Plot{PGFPlotsXBackend})
    if !pgfx_plot.is_created || pgfx_plot.was_shown
        pgfx_sanitize_plot!(plt)
        # extract extra kwargs
        extra_plot_opt = plt[:extra_plot_kwargs]
        extra_plot = nothing
        if haskey(extra_plot_opt, :add)
            extra_plot = wraptuple(pop!(extra_plot_opt,:add))
        end
        the_plot = PGFPlotsX.TikzPicture(PGFPlotsX.Options(extra_plot_opt...))
        if extra_plot !== nothing
            push!(the_plot, extra_plot...)
        end
        bgc = plt.attr[:background_color_outside] == :match ?
            plt.attr[:background_color] : plt.attr[:background_color_outside]
        if bgc isa Colors.Colorant
            cstr = plot_color(bgc)
            a = alpha(cstr)
            push!(
                the_plot.options,
                "/tikz/background rectangle/.style" => PGFPlotsX.Options(
                    # "draw" => "black",
                    "fill" => cstr,
                    "draw opacity" => a,
                ),
                "show background rectangle" => nothing,
            )
        end

        for sp in plt.subplots
            bb1 = sp.plotarea
            bb2 = bbox(sp)
            sp_width = width(bb2)
            sp_height = height(bb2)
            dx, dy = bb2.x0
            lpad = leftpad(sp) + sp[:left_margin]
            rpad = rightpad(sp) + sp[:right_margin]
            tpad = toppad(sp) + sp[:top_margin]
            bpad = bottompad(sp) + sp[:bottom_margin]
            dx += lpad
            dy += tpad
            axis_height = sp_height - (tpad + bpad)
            axis_width = sp_width - (rpad + lpad)

            cstr = plot_color(sp[:background_color_legend])
            a = alpha(cstr)
            fg_alpha = alpha(plot_color(sp[:foreground_color_legend]))
            title_cstr = plot_color(sp[:titlefontcolor])
            title_a = alpha(title_cstr)
            title_loc = sp[:titlelocation]
            bgc_inside = plot_color(sp[:background_color_inside])
            bgc_inside_a = alpha(bgc_inside)
            axis_opt = PGFPlotsX.Options(
                "point meta max" => get_clims(sp)[2],
                "point meta min" => get_clims(sp)[1],
                "legend cell align" => "left",
                "title" => sp[:title],
                "title style" => PGFPlotsX.Options(
                        pgfx_get_title_pos(title_loc)...,
                        "font" => pgfx_font(
                            sp[:titlefontsize],
                            pgfx_thickness_scaling(sp),
                    ),
                    "color" => title_cstr,
                    "draw opacity" => title_a,
                    "rotate" => sp[:titlefontrotation],
                ),
                "legend style" => PGFPlotsX.Options(
                    pgfx_linestyle(
                        pgfx_thickness_scaling(sp),
                        sp[:foreground_color_legend],
                        fg_alpha,
                        "solid",
                    ) => nothing,
                    "fill" => cstr,
                    "fill opacity" => a,
                    "text opacity" =>     alpha(plot_color(sp[:legendfontcolor])),
                    "font" => pgfx_font(
                        sp[:legendfontsize],
                        pgfx_thickness_scaling(sp),
                    ),
                ),
                "axis background/.style" => PGFPlotsX.Options(
                    "fill" => bgc_inside,
                    "opacity" => bgc_inside_a,
                ),
                # These are for layouting
                "anchor" => "north west",
                "xshift" => string(dx),
                "yshift" => string(-dy),
            )
            sp_width > 0 * mm ? push!(axis_opt, "width" => string(axis_width)) :
            nothing
            sp_height > 0 * mm ? push!(axis_opt, "height" => string(axis_height)) :
            nothing
            # legend position
            push!(axis_opt["legend style"], pgfx_get_legend_pos(sp[:legend])...)
            for letter in (:x, :y, :z)
                if letter != :z || RecipesPipeline.is3d(sp)
                    pgfx_axis!(axis_opt, sp, letter)
                end
            end
            # Search series for any gradient. In case one series uses a gradient set
            # the colorbar and colomap.
            # The reasoning behind doing this on the axis level is that pgfplots
            # colorbar seems to only works on axis level and needs the proper colormap for
            # correctly displaying it.
            # It's also possible to assign the colormap to the series itself but
            # then the colormap needs to be added twice, once for the axis and once for the
            # series.
            # As it is likely that all series within the same axis use the same
            # colormap this should not cause any problem.
            for series in series_list(sp)
                if hascolorbar(series)
                    cg = get_colorgradient(series)
                    cm = pgfx_colormap(get_colorgradient(series))
                    PGFPlotsX.push_preamble!(
                        pgfx_plot.the_plot,
                        """\\pgfplotsset{
                        colormap={plots$(sp.attr[:subplot_index])}{$cm},
                        }""",
                    )
                    push!(axis_opt, "colormap name" => "plots$(sp.attr[:subplot_index])")
                    if cg isa PlotUtils.CategoricalColorGradient
                        push!(
                            axis_opt,
                            "colormap access" => "piecewise const",
                            "colorbar sampled" => nothing,
                        )
                    end
                    # goto is needed to break out of col and series for
                    @goto colorbar_end
                end
            end
            @label colorbar_end

            if hascolorbar(sp)
                colorbar_style = PGFPlotsX.Options(
                    "title" => sp[:colorbar_title],
                    "xticklabel style" => pgfx_get_ticklabel_style(sp, sp[:xaxis]),
                    "yticklabel style" => pgfx_get_ticklabel_style(sp, sp[:yaxis]),
                )
                if sp[:colorbar] === :top
                    push!(colorbar_style,
                        "at" => string((0.5, 1.05)),
                        "anchor" => "south",
                        "xticklabel pos" => "upper",
                    )
                end
                push!(
                    axis_opt,
                    string("colorbar", pgfx_get_colorbar_pos(sp[:colorbar])) => nothing,
                    "colorbar style" => colorbar_style,
                )
            end
            if RecipesPipeline.is3d(sp)
                azim, elev = sp[:camera]
                push!(axis_opt, "view" => (azim, elev))
            end
            axisf = if sp[:projection] == :polar
                # push!(axis_opt, "xmin" => 90)
                # push!(axis_opt, "xmax" => 450)
                PGFPlotsX.PolarAxis
            else
                PGFPlotsX.Axis
            end
            extra_sp_opt = sp[:extra_kwargs]
            extra_sp = nothing
            if haskey(extra_sp_opt, :add)
                extra_sp = wraptuple(pop!(extra_sp_opt,:add))
            end
            axis = axisf(merge(axis_opt, PGFPlotsX.Options(extra_sp_opt...)))
            if extra_sp !== nothing
                push!(axis, extra_sp...)
            end
            if sp[:legendtitle] !== nothing
                push!(axis, PGFPlotsX.Options("\\addlegendimage{empty legend}" => nothing))
                push!(
                    axis,
                    PGFPlotsX.LegendEntry(
                        string("\\hspace{-.6cm}{\\textbf{", sp[:legendtitle], "}}"),
                        false,
                    ),
                )
            end
            for (series_index, series) in enumerate(series_list(sp))
                # give each series a uuid for fillbetween
                series_id = uuid4()
                _pgfplotsx_series_ids[Symbol("$series_index")] = series_id
                opt = series.plotattributes
                st = series[:seriestype]
                sf = series[:fillrange]
                series_opt = PGFPlotsX.Options(
                    "color" => single_color(opt[:linecolor]),
                    "name path" => string(series_id),
                )
                extra_series_opt = series[:extra_kwargs]
                extra_series = nothing
                if haskey(extra_series_opt, :add)
                    extra_series = wraptuple(pop!(extra_series_opt,:add))
                end
                series_opt = merge(series_opt, PGFPlotsX.Options(extra_series_opt...))
                if RecipesPipeline.is3d(series) || st in (:heatmap, :contour)
                    series_func = PGFPlotsX.Plot3
                else
                    series_func = PGFPlotsX.Plot
                end
                if sf !== nothing &&
                   !isfilledcontour(series) && series[:ribbon] === nothing
                    push!(series_opt, "area legend" => nothing)
                end
                if st in (:heatmap, :contour)
                    push!(axis.options, "view" => "{0}{90}")
                end
                # treat segments
                segments =
                    if st in (:wireframe, :heatmap, :contour, :surface, :contour3d)
                        iter_segments(surface_to_vecs(
                            series[:x],
                            series[:y],
                            series[:z],
                        )...)
                    else
                        iter_segments(series)
                    end
                for (i, rng) in enumerate(segments)
                    segment_opt = PGFPlotsX.Options()
                    segment_opt = merge(segment_opt, pgfx_linestyle(opt, i))
                    if opt[:markershape] != :none
                        marker = opt[:markershape]
                        if marker isa Shape
                            x = marker.x
                            y = marker.y
                            scale_factor = 0.00125
                            mark_size = opt[:markersize] * scale_factor
                            path = join(
                                [
                                    "($(x[i] * mark_size), $(y[i] * mark_size))"
                                    for i in eachindex(x)
                                ],
                                " -- ",
                            )
                            c = get_markercolor(series, i)
                            a = get_markeralpha(series, i)
                            PGFPlotsX.push_preamble!(
                                pgfx_plot.the_plot,
                                """
                                \\pgfdeclareplotmark{PlotsShape$(series_index)}{
                                \\filldraw
                                $path;
                                }
                                """,
                            )
                        end
                        segment_opt = merge(segment_opt, pgfx_marker(opt, i))
                    end
                    if st == :shape
                        segment_opt = merge(segment_opt, pgfx_fillstyle(opt, i))
                    end
                    # add fillrange
                    if sf !== nothing &&
                       !isfilledcontour(series) &&
                       series[:ribbon] === nothing
                        if sf isa Number || sf isa AVec
                            pgfx_fillrange_series!(
                                axis,
                                series,
                                series_func,
                                i,
                                _cycle(sf, rng),
                                rng,
                            )
                        end
                        if i == 1 &&
                           sp[:legend] != :none && pgfx_should_add_to_legend(series)
                            pgfx_filllegend!(series_opt, opt)
                        end
                    end
                    coordinates =
                        pgfx_series_coordinates!(sp, series, segment_opt, opt, rng)
                    segment_plot =
                        series_func(merge(series_opt, segment_opt), coordinates)
                    if extra_series !== nothing
                        push!(segment_plot, extra_series...)
                    end
                    push!(axis, segment_plot)
                    # fill between functions
                    if sf isa Tuple && series[:ribbon] === nothing
                        sf1, sf2 = sf
                        @assert sf1 == series_index "First index of the tuple has to match the current series index."
                        push!(
                            axis,
                            series_func(
                                merge(
                                    pgfx_fillstyle(opt, series_index),
                                    PGFPlotsX.Options("forget plot" => nothing),
                                ),
                                "fill between [of=$series_id and $(_pgfplotsx_series_ids[Symbol(string(sf2))])]",
                            ),
                        )
                    end
                    # add ribbons?
                    ribbon = series[:ribbon]
                    if ribbon !== nothing
                        pgfx_add_ribbons!(
                            axis,
                            series,
                            segment_plot,
                            series_func,
                            series_index,
                        )
                    end
                    # add to legend?
                    if sp[:legend] != :none
                        leg_entry = if opt[:label] isa AVec
                            get(opt[:label], i, "")
                        elseif opt[:label] isa AbstractString
                            if i == 1
                                get(opt, :label, "")
                            else
                                ""
                            end
                        else
                            throw(ArgumentError("Malformed label. label = $(opt[:label])"))
                        end
                        if leg_entry == "" || !pgfx_should_add_to_legend(series)
                            push!(axis.contents[end].options, "forget plot" => nothing)
                        else
                            leg_opt = PGFPlotsX.Options()
                            if ribbon !== nothing
                                pgfx_filllegend!(axis.contents[end - 3].options, opt)
                            end
                            legend = PGFPlotsX.LegendEntry(leg_opt, leg_entry, false)
                            push!(axis, legend)
                        end
                    end
                end # for segments
                # add series annotations
                anns = series[:series_annotations]
                for (xi, yi, str, fnt) in EachAnn(anns, series[:x], series[:y])
                    pgfx_add_annotation!(
                        axis,
                        xi,
                        yi,
                        PlotText(str, fnt),
                        pgfx_thickness_scaling(series),
                    )
                end
            end # for series
            # add subplot annotations
            for ann in sp[:annotations]
                pgfx_add_annotation!(
                    axis,
                    locate_annotation(sp, ann...)...,
                    pgfx_thickness_scaling(sp),
                )
            end
            push!(the_plot, axis)
            if length(plt.o.the_plot.elements) > 0
                plt.o.the_plot.elements[1] = the_plot
            else
                push!(plt.o, the_plot)
            end
        end # for subplots
        pgfx_plot.is_created = true
        pgfx_plot.was_shown = false
    end # if
    return pgfx_plot
end
## seriestype specifics
@inline function pgfx_series_coordinates!(sp, series, segment_opt, opt, rng)
    st = series[:seriestype]
    # function args
    args = if st in (:contour, :contour3d)
        opt[:x], opt[:y], Array(opt[:z])'
    elseif st in (:heatmap, :surface, :wireframe)
        surface_to_vecs(opt[:x], opt[:y], opt[:z])
    elseif RecipesPipeline.is3d(st)
        opt[:x], opt[:y], opt[:z]
    elseif st == :straightline
        straightline_data(series)
    elseif st == :shape
        shape_data(series)
    elseif ispolar(sp)
        theta, r = opt[:x], opt[:y]
        rad2deg.(theta), r
    else
        opt[:x], opt[:y]
    end
    seg_args = if st in (:contour, :contour3d)
        args
    else
        (arg[rng] for arg in args)
    end
    if opt[:quiver] !== nothing
        push!(
            segment_opt,
            "quiver" => PGFPlotsX.Options(
                "u" => "\\thisrow{u}",
                "v" => "\\thisrow{v}",
                pgfx_arrow(opt[:arrow]) => nothing,
            ),
        )
        x, y = collect(seg_args)
        return PGFPlotsX.Table([
            :x => x,
            :y => y,
            :u => opt[:quiver][1],
            :v => opt[:quiver][2],
        ])
    else
        if isfilledcontour(series)
            st = :filledcontour
        end
        pgfx_series_coordinates!(Val(st), segment_opt, opt, seg_args)
    end
end
function pgfx_series_coordinates!(
    st_val::Union{Val{:path},Val{:path3d},Val{:straightline}},
    segment_opt,
    opt,
    args,
)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(
    st_val::Union{Val{:scatter},Val{:scatter3d}},
    segment_opt,
    opt,
    args,
)
    push!(segment_opt, "only marks" => nothing)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(st_val::Val{:heatmap}, segment_opt, opt, args)
    push!(
        segment_opt,
        "matrix plot*" => nothing,
        "mesh/rows" => length(opt[:x]),
        "mesh/cols" => length(opt[:y]),
    )
    return PGFPlotsX.Table(args...)
end

function pgfx_series_coordinates!(st_val::Val{:steppre}, segment_opt, opt, args)
    push!(segment_opt, "const plot mark right" => nothing)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(st_val::Val{:stepmid}, segment_opt, opt, args)
    push!(segment_opt, "const plot mark mid" => nothing)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(st_val::Val{:steppost}, segment_opt, opt, args)
    push!(segment_opt, "const plot" => nothing)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(
    st_val::Union{Val{:ysticks},Val{:sticks}},
    segment_opt,
    opt,
    args,
)
    push!(segment_opt, "ycomb" => nothing)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(st_val::Val{:xsticks}, segment_opt, opt, args)
    push!(segment_opt, "xcomb" => nothing)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(st_val::Val{:surface}, segment_opt, opt, args)
    push!(
        segment_opt,
        "surf" => nothing,
        "mesh/rows" => length(opt[:x]),
        "mesh/cols" => length(opt[:y]),
    )
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(st_val::Val{:volume}, segment_opt, opt, args)
    push!(segment_opt, "patch" => nothing)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(st_val::Val{:wireframe}, segment_opt, opt, args)
    push!(segment_opt, "mesh" => nothing, "mesh/rows" => length(opt[:x]))
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(st_val::Val{:shape}, segment_opt, opt, args)
    push!(segment_opt, "area legend" => nothing)
    return PGFPlotsX.Coordinates(args...)
end
function pgfx_series_coordinates!(
    st_val::Union{Val{:contour},Val{:contour3d}},
    segment_opt,
    opt,
    args,
)
    push!(
        segment_opt,
        "contour prepared" => PGFPlotsX.Options("labels" => opt[:contour_labels]),
    )
    return PGFPlotsX.Table(Contour.contours(args..., opt[:levels]))
end
function pgfx_series_coordinates!(
    st_val::Val{:filledcontour},
    segment_opt,
    opt,
    args,
)
    xs, ys, zs = collect(args)
    push!(
        segment_opt,
        "contour filled" => PGFPlotsX.Options(), # labels not supported
        "patch type" => "bilinear",
        "shader" => "flat",
    )
    if opt[:levels] isa Number
        push!(segment_opt["contour filled"], "number" => opt[:levels])
    elseif opt[:levels] isa AVec
        push!(segment_opt["contour filled"], "levels" => opt[:levels])
    end

    PGFPlotsX.Coordinates(args...)
end
##
pgfx_get_linestyle(k) = get(
    (
        solid = "solid",
        dash = "dashed",
        dot = "dotted",
        dashdot = "dashdotted",
        dashdotdot = "dashdotdotted",
    ),
    Symbol(k),
    "solid",
)

pgfx_get_marker(k) = get(
    (
        none = "none",
        cross = "+",
        xcross = "x",
        + = "+",
        x = "x",
        utriangle = "triangle*",
        dtriangle = "triangle*",
        rtriangle = "triangle*",
        ltriangle = "triangle*",
        circle = "*",
        rect = "square*",
        star5 = "star",
        star6 = "asterisk",
        diamond = "diamond*",
        pentagon = "pentagon*",
        hline = "-",
        vline = "|",
    ),
    Symbol(k),
    "*",
)

pgfx_get_xguide_pos(k) = get(
    (
        top = "at={(0.5,1)},above,",
        right = "at={(ticklabel* cs:1.02)}, anchor=west,",
        left = "at={(ticklabel* cs:-0.02)}, anchor=east,",
    ),
    k,
    "at={(ticklabel cs:0.5)}, anchor=near ticklabel"
)

pgfx_get_yguide_pos(k) = get(
    (
        top = "at={(ticklabel* cs:1.02)}, anchor=south",
        right = "at={(1,0.5)},below,",
        bottom = "at={(ticklabel* cs:-0.02)}, anchor=north,",
    ),
    k,
    "at={(ticklabel cs:0.5)}, anchor=near ticklabel"
)

pgfx_get_legend_pos(k) = get(
    (
        top = ("at" => string((0.5, 0.98)), "anchor" => "north"),
        bottom = ("at" => string((0.5, 0.02)), "anchor" => "south"),
        left = ("at" => string((0.02, 0.5)), "anchor" => "west"),
        right = ("at" => string((0.98, 0.5)), "anchor" => "east"),
        bottomleft = ("at" => string((0.02, 0.02)), "anchor" => "south west"),
        bottomright = ("at" => string((0.98, 0.02)), "anchor" => "south east"),
        topright = ("at" => string((0.98, 0.98)), "anchor" => "north east"),
        topleft = ("at" => string((0.02, 0.98)), "anchor" => "north west"),
        outertop = ("at" => string((0.5, 1.02)), "anchor" => "south"),
        outerbottom = ("at" => string((0.5, -0.02)), "anchor" => "north"),
        outerleft = ("at" => string((-0.02, 0.5)), "anchor" => "east"),
        outerright = ("at" => string((1.02, 0.5)), "anchor" => "west"),
        outerbottomleft = ("at" => string((-0.02, -0.02)), "anchor" => "north east"),
        outerbottomright = ("at" => string((1.02, -0.02)), "anchor" => "north west"),
        outertopright = ("at" => string((1.02, 1)), "anchor" => "north west"),
        outertopleft = ("at" => string((-0.02, 1)), "anchor" => "north east"),
    ),
    Symbol(k),
    ("at" => string((1.02, 1)), "anchor" => "north west"),
)
pgfx_get_legend_pos(t::Tuple) = ("at" => "{$(string(t))}", "anchor" => "north west")
pgfx_get_legend_pos(nt::NamedTuple) = ("at" => "{$(string(nt.at))}", "anchor" => string(nt.anchor))

pgfx_get_colorbar_pos(s) =
    get((left = " left", bottom = " horizontal", top = " horizontal"), s, "")
pgfx_get_colorbar_pos(b::Bool) = ""

pgfx_get_title_pos(s) =
    get((
        left = ("at" => "{(0,1)}", "anchor" => "south west"),
        right = ("at" => "{(1,1)}", "anchor" => "south east"),
        ), s,
        ("at" => "{(0.5,1)}", "anchor" => "south"))
pgfx_get_title_pos(t::Tuple) = ("at" => "{$(string(t))}", "anchor" => "south")
pgfx_get_title_pos(nt::NamedTuple) = ("at" => "{$(string(nt.at))}", "anchor" => string(nt.anchor))

function pgfx_get_ticklabel_style(sp, axis)
    cstr = plot_color(axis[:tickfontcolor])
    return PGFPlotsX.Options(
        "font" => pgfx_font(
            axis[:tickfontsize], pgfx_thickness_scaling(sp)
        ),
        "color" => cstr,
        "draw opacity" => alpha(cstr),
        "rotate" => axis[:tickfontrotation],
    )
end

## --------------------------------------------------------------------------------------
# Generates a colormap for pgfplots based on a ColorGradient
pgfx_arrow(::Nothing) = "every arrow/.append style={-}"
function pgfx_arrow(arr::Arrow)
    components = String[]
    head = String[]
    push!(head, "{stealth[length = $(arr.headlength)pt, width = $(arr.headwidth)pt")
    if arr.style == :open
        push!(head, ", open")
    end
    push!(head, "]}")
    head = join(head, "")
    if arr.side == :both || arr.side == :tail
        push!(components, head)
    end
    push!(components, "-")
    if arr.side == :both || arr.side == :head
        push!(components, head)
    end
    components = join(components, "")
    return "every arrow/.append style={$(components)}"
end

function pgfx_filllegend!(series_opt, opt)
    io = IOBuffer()
    PGFPlotsX.print_tex(io, pgfx_fillstyle(opt))
    style = strip(String(take!(io)), ['[', ']', ' '])
    push!(series_opt, "legend image code/.code" => """{
              \\draw[$style] (0cm,-0.1cm) rectangle (0.6cm,0.1cm);
              }""")
end

pgfx_colormap(cl::PlotUtils.AbstractColorList) = pgfx_colormap(color_list(cl))
function pgfx_colormap(v::Vector{<:Colorant})
    join(map(v) do c
        @sprintf("rgb=(%.8f,%.8f,%.8f)", red(c), green(c), blue(c))
    end, "\n")
end
function pgfx_colormap(cg::ColorGradient)
    join(map(1:length(cg)) do i
        @sprintf("rgb(%.8fcm)=(%.8f,%.8f,%.8f)", cg.values[i], red(cg.colors[i]), green(cg.colors[i]), blue(cg.colors[i]))
    end, "\n")
end


function pgfx_framestyle(style::Symbol)
    if style in (:box, :axes, :origin, :zerolines, :grid, :none)
        return style
    else
        default_style = get((semi = :box,), style, :axes)
        @warn( "Framestyle :$style is not (yet) supported by the PGFPlotsX backend. :$default_style was cosen instead.",)
        default_style
    end
end

pgfx_thickness_scaling(plt::Plot) = plt[:thickness_scaling]
pgfx_thickness_scaling(sp::Subplot) = pgfx_thickness_scaling(sp.plt)
pgfx_thickness_scaling(series) = pgfx_thickness_scaling(series[:subplot])

function pgfx_fillstyle(plotattributes, i = 1)
    cstr = get_fillcolor(plotattributes, i)
    a = get_fillalpha(plotattributes, i)
    if a === nothing
        a = alpha(single_color(cstr))
    end
    PGFPlotsX.Options("fill" => cstr, "fill opacity" => a)
end

function pgfx_linestyle(linewidth::Real, color, α = 1, linestyle = :solid)
    cstr = plot_color(color, α)
    a = alpha(cstr)
    return PGFPlotsX.Options(
        "color" => cstr,
        "draw opacity" => a,
        "line width" => linewidth,
        pgfx_get_linestyle(linestyle) => nothing,
    )
end

function pgfx_linestyle(plotattributes, i = 1)
    lw = pgfx_thickness_scaling(plotattributes) * get_linewidth(plotattributes, i)
    lc = single_color(get_linecolor(plotattributes, i))
    la = get_linealpha(plotattributes, i)
    ls = get_linestyle(plotattributes, i)
    return pgfx_linestyle(lw, lc, la, ls)
end

function pgfx_font(fontsize, thickness_scaling = 1, font = "\\selectfont")
    fs = fontsize * thickness_scaling
    return string("{\\fontsize{", fs, " pt}{", 1.3fs, " pt}", font, "}")
end

function pgfx_should_add_to_legend(series::Series)
    series.plotattributes[:primary] &&
    !(
        series.plotattributes[:seriestype] in (
            :hexbin,
            :bins2d,
            :histogram2d,
            :hline,
            :vline,
            :contour,
            :contourf,
            :contour3d,
            :heatmap,
            :image,
        )
    )
end

function pgfx_marker(plotattributes, i = 1)
    shape = _cycle(plotattributes[:markershape], i)
    cstr =
        plot_color(get_markercolor(plotattributes, i), get_markeralpha(plotattributes, i))
    a = alpha(cstr)
    cstr_stroke = plot_color(
        get_markerstrokecolor(plotattributes, i),
        get_markerstrokealpha(plotattributes, i),
    )
    a_stroke = alpha(cstr_stroke)
    mark_size =
        pgfx_thickness_scaling(plotattributes) *
        0.75 *
        _cycle(plotattributes[:markersize], i)
    return PGFPlotsX.Options(
        "mark" => shape isa Shape ? "PlotsShape$i" : pgfx_get_marker(shape),
        "mark size" => "$mark_size pt",
        "mark options" => PGFPlotsX.Options(
            "color" => cstr_stroke,
            "draw opacity" => a_stroke,
            "fill" => cstr,
            "fill opacity" => a,
            "line width" =>
                pgfx_thickness_scaling(plotattributes) *
                0.75 *
                _cycle(plotattributes[:markerstrokewidth], i),
            "rotate" => if shape == :dtriangle
                180
            elseif shape == :rtriangle
                270
            elseif shape == :ltriangle
                90
            else
                0
            end,
            pgfx_get_linestyle(_cycle(plotattributes[:markerstrokestyle], i)) => nothing,
        ),
    )
end

function pgfx_add_annotation!(o, x, y, val, thickness_scaling = 1)
    # Construct the style string.
    cstr = val.font.color
    a = alpha(cstr)
    push!(
        o,
        [
            "\\node",
            PGFPlotsX.Options(
                get((center = "", left = "right", right = "left"), val.font.halign, "") =>
                    nothing,
                "color" => cstr,
                "draw opacity" => convert(Float16, a),
                "rotate" => val.font.rotation,
                "font" => pgfx_font(val.font.pointsize, thickness_scaling),
            ),
            " at (axis cs:$x, $y) {$(val.str)};",
        ],
    )
end

function pgfx_add_ribbons!(axis, series, segment_plot, series_func, series_index)
    ribbon_y = series[:ribbon]
    opt = series.plotattributes
    if ribbon_y isa AVec
        ribbon_n = length(opt[:y]) ÷ length(ribbon_y)
        ribbon_yp = ribbon_ym = repeat(ribbon_y, outer = ribbon_n)
    elseif ribbon_y isa Tuple
        ribbon_ym, ribbon_yp = ribbon_y
        ribbon_nm = length(opt[:y]) ÷ length(ribbon_ym)
        ribbon_ym = repeat(ribbon_ym, outer = ribbon_nm)
        ribbon_np = length(opt[:y]) ÷ length(ribbon_yp)
        ribbon_yp = repeat(ribbon_yp, outer = ribbon_np)
    else
        ribbon_yp = ribbon_ym = ribbon_y
    end
    # upper ribbon
    rib_uuid = uuid4()
    ribbon_name_plus = "plots_rib_p$rib_uuid"
    ribbon_opt_plus = merge(
        segment_plot.options,
        PGFPlotsX.Options(
            "name path" => ribbon_name_plus,
            "color" => opt[:fillcolor],
            "draw opacity" => opt[:fillalpha],
            "forget plot" => nothing,
        ),
    )
    coordinates_plus = PGFPlotsX.Coordinates(opt[:x], opt[:y] .+ ribbon_yp)
    ribbon_plot_plus = series_func(ribbon_opt_plus, coordinates_plus)
    push!(axis, ribbon_plot_plus)
    # lower ribbon
    ribbon_name_minus = "plots_rib_m$rib_uuid"
    ribbon_opt_minus = merge(
        segment_plot.options,
        PGFPlotsX.Options(
            "name path" => ribbon_name_minus,
            "color" => opt[:fillcolor],
            "draw opacity" => opt[:fillalpha],
            "forget plot" => nothing,
        ),
    )
    coordinates_plus = PGFPlotsX.Coordinates(opt[:x], opt[:y] .- ribbon_ym)
    ribbon_plot_plus = series_func(ribbon_opt_minus, coordinates_plus)
    push!(axis, ribbon_plot_plus)
    # fill
    push!(
        axis,
        series_func(
            merge(
                pgfx_fillstyle(opt, series_index),
                PGFPlotsX.Options("forget plot" => nothing),
            ),
            "fill between [of=$(ribbon_name_plus) and $(ribbon_name_minus)]",
        ),
    )
    return axis
end

function pgfx_fillrange_series!(axis, series, series_func, i, fillrange, rng)
    fillrange_opt = PGFPlotsX.Options("line width" => "0", "draw opacity" => "0")
    fillrange_opt = merge(fillrange_opt, pgfx_fillstyle(series, i))
    fillrange_opt = merge(fillrange_opt, pgfx_marker(series, i))
    push!(fillrange_opt, "forget plot" => nothing)
    opt = series.plotattributes
    args = RecipesPipeline.is3d(series) ? (opt[:x][rng], opt[:y][rng], opt[:z][rng]) :
        (opt[:x][rng], opt[:y][rng])
    push!(
        axis,
        PGFPlotsX.PlotInc(fillrange_opt, pgfx_fillrange_args(fillrange, args...)),
    )
    return axis
end

function pgfx_fillrange_args(fillrange, x, y)
    n = length(x)
    x_fill = [x; x[n:-1:1]; x[1]]
    y_fill = [y; _cycle(fillrange, n:-1:1); y[1]]
    return PGFPlotsX.Coordinates(x_fill, y_fill)
end

function pgfx_fillrange_args(fillrange, x, y, z)
    n = length(x)
    x_fill = [x; x[n:-1:1]; x[1]]
    y_fill = [y; y[n:-1:1]; x[1]]
    z_fill = [z; _cycle(fillrange, n:-1:1); z[1]]
    return PGFPlotsX.Coordiantes(x_fill, y_fill, z_fill)
end

function pgfx_sanitize_string(p::PlotText)
    PlotText(pgfx_sanitize_string(p.str), p.font)
end
function pgfx_sanitize_string(s::AbstractString)
    s = replace(s, r"\\?\#" => "\\#")
    s = replace(s, r"\\?\%" => "\\%")
    s = replace(s, r"\\?\_" => "\\_")
    s = replace(s, r"\\?\&" => "\\&")
    s = replace(s, r"\\?\{" => "\\{")
    s = replace(s, r"\\?\}" => "\\}")
end
@require LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f" begin
    using .LaTeXStrings
    function pgfx_sanitize_string(s::LaTeXString)
        s = replace(s, r"\\?\#" => "\\#")
        s = replace(s, r"\\?\%" => "\\%")
    end
end
function pgfx_sanitize_plot!(plt)
        for (key, value) in plt.attr
            if value isa Union{AbstractString, AbstractVector{<:AbstractString}}
                plt.attr[key] = pgfx_sanitize_string.(value)
            end
        end
        for subplot in plt.subplots
            for (key, value) in subplot.attr
                if key == :annotations && subplot.attr[:annotations] !== nothing
                    old_ann = subplot.attr[key]
                    for i in eachindex(old_ann)
                        subplot.attr[key][i] = (old_ann[i][1], old_ann[i][2], pgfx_sanitize_string(old_ann[i][3]))
                    end
                elseif value isa Union{AbstractString, AbstractVector{<:AbstractString}}
                    subplot.attr[key] = pgfx_sanitize_string.(value)
                end
            end
        end
        for series in plt.series_list
            for (key, value) in series.plotattributes
                if key == :series_annotations && series.plotattributes[:series_annotations] !== nothing
                    old_ann = series.plotattributes[key].strs
                    for i in eachindex(old_ann)
                        series.plotattributes[key].strs[i] = pgfx_sanitize_string(old_ann[i])
                    end
                elseif value isa Union{AbstractString, AbstractVector{<:AbstractString}}
                    series.plotattributes[key] = pgfx_sanitize_string.(value)
                end
            end
        end
        ##
end
# --------------------------------------------------------------------------------------
function pgfx_axis!(opt::PGFPlotsX.Options, sp::Subplot, letter)
    axis = sp[Symbol(letter, :axis)]

    # turn off scaled ticks
    push!(
        opt,
        "scaled $(letter) ticks" => "false",
        string(letter, :label) => axis[:guide],
    )
    tick_color = plot_color(axis[:foreground_color_axis])
    push!(opt,
        "$(letter) tick style" => PGFPlotsX.Options(
            "color" => color(tick_color),
            "opacity" => alpha(tick_color),
        ),
    )
    tick_label_color = plot_color(axis[:tickfontcolor])
    push!(opt,
        "$(letter) tick label style" => PGFPlotsX.Options(
            "color" => color(tick_color),
            "opacity" => alpha(tick_color),
            "rotate" => axis[:rotation]
        ),
    )

    # set to supported framestyle
    framestyle = pgfx_framestyle(sp[:framestyle] == false ? :none : sp[:framestyle])

    # axis label position
    labelpos = ""
    if letter == :x
        labelpos = pgfx_get_xguide_pos(axis[:guide_position])
    elseif letter == :y
        labelpos = pgfx_get_yguide_pos(axis[:guide_position])
    end

    # Add label font
    cstr = plot_color(axis[:guidefontcolor])
    α = alpha(cstr)
    push!(
        opt,
        string(letter, "label style") => PGFPlotsX.Options(
            labelpos => nothing,
            "font" =>     pgfx_font(axis[:guidefontsize], pgfx_thickness_scaling(sp)),
            "color" => cstr,
            "draw opacity" => α,
            "rotate" => axis[:guidefontrotation],
        ),
    )

    # flip/reverse?
    axis[:flip] && push!(opt, "$letter dir" => "reverse")

    # scale
    scale = axis[:scale]
    if scale in (:log2, :ln, :log10)
        push!(opt, string(letter, :mode) => "log")
        scale == :ln ||
        push!(opt, "log basis $letter" => "$(scale == :log2 ? 2 : 10)")
    end

    # ticks on or off
    if axis[:ticks] in (nothing, false, :none) || framestyle == :none
        push!(opt, "$(letter)majorticks" => "false")
    elseif framestyle in (:grid, :zerolines)
        push!(opt, "$letter tick style" => PGFPlotsX.Options("draw" => "none"))
    end

    # grid on or off
    if axis[:grid] && framestyle != :none
        push!(opt, "$(letter)majorgrids" => "true")
    else
        push!(opt, "$(letter)majorgrids" => "false")
    end

    # limits
    lims = ispolar(sp) && letter == :x ? rad2deg.(axis_limits(sp, :x)) :
        axis_limits(sp, letter)
    push!(opt, string(letter, :min) => lims[1], string(letter, :max) => lims[2])

    if !(axis[:ticks] in (nothing, false, :none, :native)) && framestyle != :none
        # ticks
        ticks = get_ticks(sp, axis)
        #pgf plot ignores ticks with angle below 90 when xmin = 90 so shift values
        tick_values =
            ispolar(sp) && letter == :x ? [rad2deg.(ticks[1])[3:end]..., 360, 405] :
            ticks[1]
        push!(
            opt,
            string(letter, "tick") => string("{", join(tick_values, ","), "}"),
        )
        if axis[:showaxis] &&
           axis[:scale] in (:ln, :log2, :log10) && axis[:ticks] == :auto
            # wrap the power part of label with }
            tick_labels = Vector{String}(undef, length(ticks[2]))
            for (i, label) in enumerate(ticks[2])
                base, power = split(label, "^")
                power = string("{", power, "}")
                tick_labels[i] = string(base, "^", power)
            end
            push!(
                opt,
                string(letter, "ticklabels") =>
                    string("{\$", join(tick_labels, "\$,\$"), "\$}"),
            )
        elseif axis[:showaxis]
            tick_labels =
                ispolar(sp) && letter == :x ? [ticks[2][3:end]..., "0", "45"] :
                ticks[2]
            if axis[:formatter] in (:scientific, :auto)
                tick_labels = string.("\$", convert_sci_unicode.(tick_labels), "\$")
                tick_labels = replace.(tick_labels, Ref("×" => "\\times"))
            end
            push!(
                opt,
                string(letter, "ticklabels") =>
                    string("{", join(tick_labels, ","), "}"),
            )
        else
            push!(opt, string(letter, "ticklabels") => "{}")
        end
        push!(
            opt,
            string(letter, "tick align") =>
                (axis[:tick_direction] == :out ? "outside" : "inside"),
        )
        push!(
            opt, string(letter, "ticklabel style") => pgfx_get_ticklabel_style(sp, axis)
        )
        push!(
            opt,
            string(letter, " grid style") => pgfx_linestyle(
                pgfx_thickness_scaling(sp) * axis[:gridlinewidth],
                axis[:foreground_color_grid],
                axis[:gridalpha],
                axis[:gridstyle],
            ),
        )

        # minor ticks
        # NOTE: PGFPlots would provide "minor x ticks num", but this only places minor ticks
        #       between major ticks and not outside first and last tick to the axis limits.
        #       Hence, we hack around with extra ticks. Unfortunately this conflicts with
        #       `:zerolines` framestyle hack. So minor ticks are not working with
        #       `:zerolines`.
        minor_ticks = get_minor_ticks(sp, axis, ticks)
        if minor_ticks !== nothing
            minor_ticks =
                ispolar(sp) && letter == :x ? [rad2deg.(minor_ticks)[3:end]..., 360, 405] :
                minor_ticks
            push!(
                opt,
                string("extra ", letter, " ticks") => string("{", join(minor_ticks, ","), "}"),
            )
            push!(opt, string("extra ", letter, " tick labels") => "")
            push!(
                opt,
                string("extra ", letter, " tick style") => PGFPlotsX.Options(
                    "grid" => axis[:minorgrid] ? "major" : "none",
                    string(letter, " grid style") => pgfx_linestyle(
                        pgfx_thickness_scaling(sp) * axis[:minorgridlinewidth],
                        axis[:foreground_color_minor_grid],
                        axis[:minorgridalpha],
                        axis[:minorgridstyle],
                    ),
                    "major tick length" => typeof(axis[:minorticks]) <: Integer && axis[:minorticks] > 1 || axis[:minorticks] ? "0.1cm" : "0"
                ),
            )
        end
    end

    # framestyle
    if framestyle in (:axes, :origin)
        axispos = axis[:mirror] ? "right" : framestyle == :axes ? "left" : "middle"

        if axis[:draw_arrow]
            push!(opt, string("axis ", letter, " line") => axispos)
        else
            # the * after line disables the arrow at the axis
            push!(opt, string("axis ", letter, " line*") => axispos)
        end
    end

    if framestyle == :zerolines
        push!(opt, string("extra ", letter, " ticks") => "0")
        push!(opt, string("extra ", letter, " tick labels") => "")
        push!(
            opt,
            string("extra ", letter, " tick style") => PGFPlotsX.Options(
                "grid" => "major",
                string(letter, " grid style") => pgfx_linestyle(
                    pgfx_thickness_scaling(sp),
                    axis[:foreground_color_border],
                    1.0,
                ),
            ),
        )
    end

    if !axis[:showaxis]
        push!(opt, "separate axis lines")
    end
    if !axis[:showaxis] || framestyle in (:zerolines, :grid, :none)
        push!(opt, string(letter, " axis line style") => "{draw opacity = 0}")
    else
        push!(
            opt,
            string(letter, " axis line style") => pgfx_linestyle(
                pgfx_thickness_scaling(sp),
                axis[:foreground_color_border],
                1.0,
            ),
        )
    end
end

# --------------------------------------------------------------------------------------
# display calls this and then _display, its called 3 times for plot(1:5)
# Set the (left, top, right, bottom) minimum padding around the plot area
# to fit ticks, tick labels, guides, colorbars, etc.
function _update_min_padding!(sp::Subplot{PGFPlotsXBackend})
    leg = sp[:legend]
    if leg in (:best, :outertopright, :outerright, :outerbottomright) || (leg isa Tuple && leg[1] >= 1)
        sp.minpad = (0mm, 0mm, 5mm, 0mm)
    else
        sp.minpad = (0mm, 0mm, 0mm, 0mm)
    end
end

function _create_backend_figure(plt::Plot{PGFPlotsXBackend})
    plt.o = PGFPlotsXPlot()
end

function _series_added(plt::Plot{PGFPlotsXBackend}, series::Series)
    plt.o.is_created = false
end

function _update_plot_object(plt::Plot{PGFPlotsXBackend})
    plt.o(plt)
end

for mime in ("application/pdf", "image/png", "image/svg+xml")
    @eval function _show(
        io::IO,
        mime::MIME{Symbol($mime)},
        plt::Plot{PGFPlotsXBackend},
    )
        plt.o.was_shown = true
        show(io, mime, plt.o.the_plot)
    end
end

function _show(
    io::IO,
    mime::MIME{Symbol("application/x-tex")},
    plt::Plot{PGFPlotsXBackend},
)
    plt.o.was_shown = true
    PGFPlotsX.print_tex(
        io,
        plt.o.the_plot,
        include_preamble = plt.attr[:tex_output_standalone],
    )
end

function _display(plt::Plot{PGFPlotsXBackend})
    plt.o.was_shown = true
    display(PGFPlotsX.PGFPlotsXDisplay(), plt.o.the_plot)
end
