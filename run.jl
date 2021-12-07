using DataFrames, CSV, Statistics, IterativeSolvers, StatsPlots, Polynomials, DelimitedFiles
include("./src/OptimizerParaibaDoSul.jl")

function function_compiler(trial_params,df_stats,trial_name)
    
    b = [250,(250+trial_params["min_flow"])/2,trial_params["min_flow"]]
    coef = zeros(12,3)
    for i in 1:size(df_stats,1)
        max = df_stats[i,"max"] - trial_params["reservoir_confidence"]*(df_stats[i,"max"] - df_stats[i,"mean"])
        min = df_stats[i,"mean"] - trial_params["tail_height"]*2*df_stats[i,"std"]
        avg = df_stats[i,"mean"] - trial_params["tail_height"]/2*df_stats[i,"std"]

        A = [max^2 max^1 max^0
            avg^2 avg^1 avg^0
            min^2 min^1 min^0]

        p = Polynomial(reverse(lsmr(A,b)))
        coef[i,:] = coeffs(p)
        d = derivative(p)
        
        x = -0.1:0.01:1
        y = [(p(i) > b[3]) && (d(i) > 0) ? p(i) : b[3] for i in x]
        p = plot(x,y,
            ylim = [0,300],
            legend = false,
            xlabel = "Reservatório Equivalente (%)",
            ylabel = "Vazão (m^3/s)",
            title = "Função de Defluência Mês $(i)"
        )

        p = plot!([df_stats[i,"mean"]], seriestype="vline",color=:red)
        annotate!(df_stats[i,"mean"]-0.07, 305, text("Média: "*string(round(df_stats[i,"mean"],digits = 3)), :red, 6))

        p = plot!([160], seriestype="hline",color=:red)
        annotate!(-0.16, 160, text("160", :red, 6))

        p = plot!([0.8], seriestype="vline",color=:purple, alpha = 0.3)
        annotate!(0.8, -15, text("80%", :purple, 6))

        if !isdir(joinpath(trial_name,"figures"))
            mkdir(joinpath(trial_name,"figures"))
        end

        savefig(joinpath(trial_name,"figures//month_$(i).png"))
    end
    return coef
end

const OPS = OptimizerParaibaDoSul
dir = ARGS[1]

base_name = "base_results"
df_reservoir = DataFrame(CSV.File(joinpath(base_name,"results",base_name*"_reservoir_Hm3.csv")))[:,["month","ps_equivalent_reservoir"]]
gdf = groupby(df_reservoir, "month")
df_stats = combine(gdf,
    "ps_equivalent_reservoir" => mean => "mean",
    "ps_equivalent_reservoir" => maximum => "max",
    "ps_equivalent_reservoir" => minimum => "min",
    "ps_equivalent_reservoir" => std => "std",
    )
    
df_params = DataFrame(CSV.File(joinpath(dir,"trial_params.csv")))

for min_flow in df_params[1,"start"]:df_params[1,"step"]:df_params[1,"end"]
    for reservoir_confidence in df_params[2,"start"]:df_params[2,"step"]:df_params[2,"end"]
        for tail_height in df_params[3,"start"]:df_params[3,"step"]:df_params[3,"end"]
            println("TRIAL (A = $(min_flow), B = $(reservoir_confidence), C = $(tail_height))")
            trial_params = Dict(
                "min_flow"=>min_flow,
                "reservoir_confidence"=>reservoir_confidence,
                "tail_height"=>tail_height
            )

            trial_name = "trial_$(trial_params["min_flow"])_$(Int64(round(100*trial_params["reservoir_confidence"])))%_$(tail_height)"

            if !isdir(joinpath(dir,trial_name))
                mkdir(joinpath(dir,trial_name))
            end

            cp(joinpath(base_name), joinpath(dir,trial_name),force=true)
            rm(joinpath(dir,trial_name,"results"), recursive=true)
            
            coef = function_compiler(trial_params,df_stats,joinpath(dir,trial_name))
            conc_down = true
            for i in 1:size(coef,1)
                if coeffs(derivative(derivative(Polynomial(coef[i,:]))))[1] < 0
                    conc_down = false
                end
            end
            if conc_down
                writedlm(joinpath(dir,trial_name,"defluence_poly.csv"),  coef, '\t')
                writedlm(joinpath(dir,trial_name,"defluence_poly_meta.csv"),  [min_flow, reservoir_confidence], '\t')
                OPS.run_simulation(joinpath(dir,trial_name))
            else
                println("CASE ELIMINATED DUE TO UPWARD CONCAVITY PARABOLE.")
                rm(joinpath(dir,trial_name), recursive=true)
            end
        end
    end
end