# SlurmAddAllocatedProcs

A helper package to make adding processes easier when using Slurm's batch mode.
The package [ClusterManagers.jl](https://github.com/JuliaParallel/ClusterManagers.jl) provides a function `addprocs_slurm` that one may use to add workers on a cluster. However to use this, one needs to know the number of tasks to add. A typical workflow would be, for example

jobscript:
```console
#!/bin/bash
#SBATCH --job-name=julia-demo
#SBATCH --time=00:01:00
#SBATCH -n 4
#SBATCH --nodes 2
#SBATCH --output=log.out
#SBATCH --error=log.err

julia script.jl
```

julia script:
```julia
using ClusterManagers
ntasks = parse(Int, ENV["SLURM_NTASKS"])
addprocs_slurm(ntasks)
using Distributed

ids = [@spawnat w Libc.gethostname() for w in workers()]
println.(fetch.(ids))
```

The output from running this is
```console
connecting to worker 1 out of 4
connecting to worker 2 out of 4
connecting to worker 3 out of 4
connecting to worker 4 out of 4
compute-20-10.local
compute-20-10.local
compute-20-10.local
compute-20-17.local
```

so three workers were added on one node, and one on the other.

In this script, we need to infer the number of tasks allocated in the jobscript by parsing the environment variable `SLURM_NTASKS`. This variable, however, is defined only if the `-n` option is specified in the jobscript. In general the environment variable that is always defined is `SLURM_TASKS_PER_NODE`, which is a little harder to parse. This package does exactly this, it parses `SLURM_TASKS_PER_NODE` and infers the number of tasks to be added. The modified julia script when using this package would be:

```julia
using SlurmAddAllocatedProcs
addprocs_slurm_allocated()
using Distributed

ids = [@spawnat w Libc.gethostname() for w in workers()]
println.(fetch.(ids))
```

Now the number of tasks to be added is automatically inferred from the batch script. This produces the same output:

```
connecting to worker 1 out of 4
connecting to worker 2 out of 4
connecting to worker 3 out of 4
connecting to worker 4 out of 4
compute-5-12.local
compute-5-12.local
compute-5-12.local
compute-5-13.local
```
where, as before, three workers are added on one node and one on another.

More flags may be specified in the jobscript to fine-tune the workers added, for example:

```console
#!/bin/bash
#SBATCH --job-name=julia-demo
#SBATCH --time=00:01:00
#SBATCH -n 4
#SBATCH --nodes 2
#SBATCH --ntasks-per-node 2
#SBATCH --output=log.out
#SBATCH --error=log.err

julia script.jl
```

which, with the julia script from above, leads to the output
```console
connecting to worker 1 out of 4
connecting to worker 2 out of 4
connecting to worker 3 out of 4
connecting to worker 4 out of 4
compute-5-12.local
compute-5-12.local
compute-5-13.local
compute-5-13.local
```

where now two workers are added on each node.
