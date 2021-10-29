using SlurmAddAllocatedProcs
using SlurmAddAllocatedProcs: parse_SLURM_TASKS_PER_NODE
using Test

@testset "SlurmAddAllocatedProcs.jl" begin
    @test_throws ErrorException addprocs_slurm_allocated()
    @testset "parse_SLURM_TASKS_PER_NODE" begin
        @test parse_SLURM_TASKS_PER_NODE("28(x3)") == 28*3
        @test parse_SLURM_TASKS_PER_NODE("28(x3),1") == 28*3+1
        @test parse_SLURM_TASKS_PER_NODE("2,28(x2),1") == 2+28*2+1
        @test parse_SLURM_TASKS_PER_NODE("2,28(x2),1,28(x4)") == 2+28*2+1+28*4
    end
end

# tests from SlurmClusterManager .jl
# https://github.com/kleinhenz/SlurmClusterManager.jl/blob/master/test/runtests.jl
JULIAPATH = joinpath(Sys.BINDIR, Base.julia_exename())

function testslurmjob(; ntasks = nothing, nnodes = nothing, cpupertask = nothing)
    project_path = abspath(joinpath(@__DIR__, ".."))
    # project should point to top level dir so that SlurmAddAllocatedProcs is available to script.jl
    script_path = joinpath(@__DIR__, "script.jl")
    juliacmd = "$JULIAPATH --startup=no --project=$project_path $script_path"
    # submit job
    mktempdir(@__DIR__) do dir
        cd(dir)
        @show pwd()
        open("jobscript.slurm", "w") do f
            println(f, "#!/bin/bash")
            println(f, juliacmd)
        end
        tasks = ntasks === nothing ? `` : `-n $ntasks`
        nodes = nnodes === nothing ? `` : `-N $nnodes`
        cpuspernode = cpupertask === nothing ? `` : `--cpus-per-task $cpupertask`
        outfile = joinpath(dir, "test.out")
        sbatchcmd = `sbatch --export=ALL --parsable $tasks $nodes $cpuspernode -o $outfile jobscript.slurm`
        jobid = read(sbatchcmd, String)
        println("jobid = $jobid")

        # get job state from jobid
        getjobstate = jobid -> read(`sacct -j $jobid --format=state --noheader`, String)

        # wait for job to complete
        status = timedwait(300.0, pollint=10.0) do
          state = getjobstate(jobid)
          state == "" && return false
          state = first(split(state)) # don't care about jobsteps
          println("jobstate = $state")
          return state == "COMPLETED" || state == "FAILED"
        end

        # check that job finished running within timelimit (either completed or failed)
        @test status == :ok

        # print job output
        output = read(outfile, String)
        println("script output:")
        println(output)

        state = getjobstate(jobid) |> split

        # check that everything exited without errors
        @test all(state .== "COMPLETED")
    end
end

# test job submission if slurm is available
if Sys.which("sinfo") !== nothing
    testslurmjob(ntasks = 4) # 4 tasks on 1 node
    testslurmjob(nnodes = 2) # all workers on 2 nodes
    testslurmjob(ntasks = 4, nnodes = 1) # 4 tasks on 1 nodes
    testslurmjob(ntasks = 4, nnodes = 2) # 2 tasks each on 2 nodes
    testslurmjob(ntasks = 2, cpupertask = 2) # 2 tasks on 1 node with 2 CPUs per task
    testslurmjob(ntasks = 2, nnodes = 2, cpupertask = 2) # 1 task each on 2 nodes with 2 CPUs per task
end
