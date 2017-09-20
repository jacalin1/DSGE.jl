"""
```
plot_scenario(m, var, class, scen; title = "", kwargs...)

plot_scenario(m, vars, class, scen; untrans = false, fourquarter = false,
    plotroot = figurespath(m, \"scenarios\"), titles = [], tick_size = 1,
    legend = :none, kwargs...)
```

Plot `var` or `vars` *in deviations from baseline* for the alternative scenario
specified by `key` and `vint`.

### Inputs

- `var::Symbol` or `vars::Vector{Symbol}`: variable(s) to be plotted,
  e.g. `:obs_gdp` or `[:obs_gdp, :obs_nominalrate]`
- `class::Symbol`
- `scen::AbstractScenario`: scenario

### Keyword Arguments

- `untrans::Bool`: whether to plot untransformed (model units) forecast
- `fourquarter::Bool`: whether to plot four-quarter forecast
- `plotroot::String`: if nonempty, plots will be saved in that directory
- `title::String` or `titles::Vector{String}`
- `tick_size::Int`: x-axis (time) tick size in units of years
- `legend`
- Other keyword arguments passed in to `plot_history_and_forecast`

### Output

- `p::Plot` or `plots::OrderedDict{Symbol, Plot}`
"""
function plot_scenario(m::AbstractModel, var::Symbol, class::Symbol, scen::AbstractScenario;
                       title::String = "", kwargs...)

    plots = plot_scenario(m, [var], class, scen,
                          titles = isempty(title) ? String[] : [title],
                          kwargs...)
    return plots[var]
end

function plot_scenario(m::AbstractModel, vars::Vector{Symbol}, class::Symbol,
                       scen::AbstractScenario; untrans::Bool = false, fourquarter::Bool = false,
                       plotroot::String = figurespath(m, "scenarios"),
                       titles::Vector{String} = String[],
                       tick_size::Int = 1,
                       legend = :none,
                       kwargs...)
    # Determine output_var
    fcast_prod = if untrans && fourquarter
        error("Only one of untrans or fourquarter can be true")
    elseif untrans
        :forecastut
    elseif fourquarter
        :forecast4q
    else
        :forecast
    end

    # Read in MeansBands
    hist  = MeansBands()
    fcast = read_scenario_mb(m, scen, Symbol(fcast_prod, class))

    # Get titles if not provided
    if isempty(titles)
        detexify_title = typeof(Plots.backend()) == Plots.GRBackend
        titles = map(var -> describe_series(m, var, class, detexify = detexify_title), vars)
    end

    # Loop through variables
    plots = OrderedDict{Symbol, Plots.Plot}()
    for (var, title) in zip(vars, titles)
        output_file = if isempty(plotroot)
            ""
        else
            get_scenario_filename(m, scen, Symbol(fcast_prod, "_", detexify(var)),
                                  pathfcn = figurespath,
                                  fileformat = plot_extension())
        end
        ylabel = series_ylabel(m, var, class, untrans = untrans, fourquarter = fourquarter)
        ylabel = ylabel * " (deviations from baseline)"

        plots[var] = plot_history_and_forecast(var, hist, fcast;
                                               output_file = output_file, title = title,
                                               tick_size = tick_size, legend = legend,
                                               ylabel = ylabel,
                                               start_date = date_forecast_start(m),
                                               kwargs...)
    end
    return plots
end