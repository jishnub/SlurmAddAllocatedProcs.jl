module SlurmAddAllocatedProcs

using ClusterManagers
export addprocs_slurm_allocated

function parse_SLURM_TASKS_PER_NODE(SLURM_TASKS_PER_NODE)
    v = split(SLURM_TASKS_PER_NODE, ",")
    pattern = r"([0-9]+)\(x([0-9]+)\)"
    np = 0
    n = 0
    for el in v
        el_Int = tryparse(Int, el)
        if el_Int isa Int
            np += el_Int
            n += 1
        else
            rm = match(pattern, el)
            if rm !== nothing
                ni = parse(Int, rm[2])
                n += ni
                p_ni = parse(Int, rm[1])
                np += p_ni*ni
            end
        end
    end
    if n == 0
        error("Could not infer the number of tasks")
    end
    return np
end

"""
    addprocs_slurm_allocated()

Add workers when run in a batch Slurm job. The number of tasks to use is inferred from the environment
variables set by the resource allocation step (eg. using `sbatch` flags).
"""
function addprocs_slurm_allocated()
    SLURM_TASKS_PER_NODE = get(ENV, "SLURM_TASKS_PER_NODE", "")
    np = parse_SLURM_TASKS_PER_NODE(SLURM_TASKS_PER_NODE)
    addprocs_slurm(np)
end

end
