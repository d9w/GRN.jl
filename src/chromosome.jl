
struct GRN
    nin::Int64
    nout::Int64
    nreg::Int64
    ids::Array{Float64}
    enh::Array{Float64}
    inh::Array{Float64}
    beta::Float64
    delta::Float64
    weights::Array{Float64}
    cons::Array{Float64}
end

function get_weights(ids::Array{Float64}, enh::Array{Float64}, inh::Array{Float64},
                     beta::Float64)
    glen = length(ids)
    weights = zeros(length(ids), length(ids))
    for i in eachindex(ids)
        for j in eachindex(ids)
            # influence of i on j (based on excitatory and inhibitory proteins of i)
            weights[i, j] = (exp(-beta * abs(enh[i] - ids[j])) -
                             exp(-beta * abs(inh[i] - ids[j])))
        end
    end
    weights
end

function GRN(nin::Int64, nout::Int64, nreg::Int64, config::Config)
    grn_size = nin + nout + nreg
    ids = rand(grn_size)
    enh = rand(grn_size)
    inh = rand(grn_size)
    beta = rand() * (config.beta_max - config.beta_min) + config.beta_min
    delta = rand() * (config.delta_max - config.delta_min) + config.delta_min
    weights = get_weights(ids, enh, inh, beta)
    cons = ones(grn_size) ./ grn_size
    GRN(nin, nout, nreg, inh, enh, ids, beta, delta, weights, cons)
end

function reset!(grn::GRN)
    grn.cons .= 1./length(grn.ids)
end

function set_input!(grn::GRN, input::Array{Float64})
    @assert length(input) == grn.nin
    for i in eachindex(input)
        grn.cons[i] = input[i]
    end
end

function get_output(grn::GRN)
    grn.cons[grn.nin+(1:grn.nout)]
end

function step!(grn::GRN)
    reg = deepcopy(grn.cons)
    reg[grn.nin+(1:grn.nout)] .= 0.0
    cons = max.(0.0, grn.delta / length(grn.ids) * (reg' * grn.weights))
    sumcons = sum(cons[(grn.nin+1):end])
    if sumcons > 0
        cons = cons ./ sumcons
    end
    for i in (grn.nin+1):length(grn.ids)
        grn.cons[i] = cons[i]
    end
end