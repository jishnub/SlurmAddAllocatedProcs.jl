using ClusterManagerSlurmBatch
using Test

@testset "ClusterManagerSlurmBatch.jl" begin
    @test_throws ErrorException addprocs_sbatch()
    @testset "parse_SLURM_TASKS_PER_NODE" begin
        @test ClusterManagerSlurmBatch.parse_SLURM_TASKS_PER_NODE("28(x3)") == 28*3
        @test ClusterManagerSlurmBatch.parse_SLURM_TASKS_PER_NODE("28(x3),1") == 28*3+1
        @test ClusterManagerSlurmBatch.parse_SLURM_TASKS_PER_NODE("2,28(x2),1") == 2+28*2+1
    end
end
