push!(LOAD_PATH, Sys.STDLIB)
using SlurmAddAllocatedProcs
using Test
addprocs_slurm_allocated()
using Distributed

SLURM_TASKS_PER_NODE = ENV["SLURM_TASKS_PER_NODE"]
@test nworkers() == parse_slurm_tasks_per_node(SLURM_TASKS_PER_NODE)
hosts = [@fetchfrom w Libc.gethostname() for w in workers()]
@test length(unique(hosts)) == parse(Int, ENV["SLURM_JOB_NUM_NODES"])
