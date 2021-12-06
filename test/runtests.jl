using Test
using OptimizerParaibaDoSul

const OPS = OptimizerParaibaDoSul

case_name = "base_results"
input_folder = "../$(case_name)"

@testset "SimulatorParaibaDoSul" begin

    @testset "Locates example files" begin
        @test isdir(input_folder)
        for folder in ["evaporation_data","flow_data","generation_data","irrigation_data"]
            @test isdir(joinpath(input_folder,folder))
        end
        for file in ["hidroplants_params.csv","topology.csv","cfur.csv"]
            @test isfile(joinpath(input_folder,file))
        end
    end

    @testset "Runs simulation" begin
        @test OPS.run_simulation(input_folder) == "Simulation complete, results available at: $(input_folder)/results"
    end
end