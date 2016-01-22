function Base.call(x::Function, df::DataFrame)
    x(df)
end


"""
`function annualtoquarter(v)`

Convert from annual to quarter by dividing by 4
"""
function annualtoquarter(v)
    v / 4
end

"""
`nominal_to_real(col, df; deflator_mnemonic=:GDPCTPI)`

Converts nominal to real values using the specified
deflator.

## Parameters
- `col`: symbol indicating which column of `df` to transform
- `df`: DataFrame containining series for proper population measure and `col`

## Keyword arguments

- `deflator_mnemonic`: indicates which deflator to use to calculate real values. Default value is the FRED GDP Deflator mnemonic.
"""
function nominal_to_real(col, df; deflator_mnemonic=:GDPCTPI)
    return df[col] ./ df[deflator_mnemonic] 
end


"""
`function nominal_to_realpercapita(col::Symbol, df)`

Convert column `col` in `df` from a nominal to a real, per-person-employed value
"""
function nominal_to_realpercapita(col, df; population_mnemonic=:CNP16OV, deflator_mnemonic=:GDPCTPI, scale = 1)

    # create a temporary column to hold per-capita values
    df[:temp] = percapita(col, df, population_mnemonic=population_mnemonic) 

    # convert to real values and scale 
    realpercapita = scale * nominal_to_real(:temp, df, deflator_mnemonic=deflator_mnemonic)
    
    # delete temporary column
    delete!(df, :temp)
    
    return realpercapita
end


"""
`percapita(col, df; population_mnemonic=:CNP16OV)`

Converts data column `col` of DataFrame `df` to a per-capita value.

## Parameters
- `col`: symbol indicating which column of data to transform
- `df`: DataFrame containining series for proper population measure and `col`

## Keyword arguments

- `population_mnemonic`: a mnemonic found in df for some population
  measure. Default value = civilian noninstitutional population age 16+ (CNP16OV).
"""
function percapita(col, df; population_mnemonic=:CNP16OV)
   df[col] ./ df[population_mnemonic] 
end


"""
```
yt, yf = hpfilter(y, λ::AbstractFloat)
```

Applies the Hodrick-Prescott filter. The smoothing parameter `λ` is applied to the columns of
`y`, returning the trend component `yt` and the cyclical component `yf`.
"""
function hpfilter(y, λ::Real)
    n = length(y)
    a = spzeros(n,n)
    for i = 3:n-2
        a[i,i]   = 6λ+1
        a[i,i+1] = -4λ
        a[i,i+2] = λ
        a[i,i-2] = λ
        a[i,i-1] = -4λ
    end

    a[2,2] = 1+5λ
    a[2,3] = -4λ
    a[2,4] = λ
    a[2,1] = -2λ
    a[1,1] = 1+λ
    a[1,2] = -2λ
    a[1,3] = λ
    
    a[n-1,n-1] = 1+5λ
    a[n-1,n-2] = -4λ
    a[n-1,n-3] = λ
    a[n-1,n]   = -2λ
    a[n,n]     = 1+λ
    a[n,n-1]   = -2λ
    a[n,n-2]   = λ

    if !isa(y, Vector{Float64}) float64(y) end

    yt = a\y
    yf = y-yt

    return yt, yf
end

"""
```
difflog(x::Vector{AbstractFloat})
```
"""
function difflog{T<:AbstractFloat}(x::Vector{T})
    [NaN; log(x[2:end]) - log(x[1:end-1])]
end


"""
```
difflog(x::DataArray{AbstractFloat})
```
"""
function difflog(x::DataArray)
    DSGE.na2nan!(x)
    y = convert(Vector{Float64}, x)
    return difflog(y)
end


"""
```
q2qpctchange(y)
```

Calculates the quarter-to-quarter percentage change of a series.
"""
function q2qpctchange(y)
    100 * difflog(y)
end


"""
```
realq2qpctchange(col::Symbol, df::DataFrame, deflator=:GDP)
```

Calculates the real quarter-to-quarter percentage change of a series.
"""
function realq2qpctchange(col::Symbol, df::DataFrame, deflator=:GDP)

    deflator_symbol = if deflator == :GDP 
        :GDPCTPI
    elseif deflator == :PCE
        :PCEPILFE        
    end

    100 * (difflog(df[col]) - difflog(df[deflator_symbol]))
end

"""
```
hpadjust(y, df)
```

## Parameters
- `y`: A vector of data
- `df`: DataFrame containing both a filtered and unfiltered population growth series 
"""
function hpadjust(y, df)
    y + 100*(df[:unfiltered_population_growth] - df[:filtered_population_growth])
end

