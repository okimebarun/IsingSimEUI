module IsingMCMC

function genFunctor( Jd, Hd)
    Jd = Jd
    Hd = Hd
    
    # E(S) = - 1/2\sum_{i,j, i not j} J_{i,j} si sj - \sum_i H_i si
    function E(S, N)
        local Et = 0
        for i in 1:N
            for (j,Jv) in Jd[i]
                @inbounds Et += -S[i]*Jv*S[j]/2
            end
            @inbounds Et += -S[i]*Hd[i]
        end
        Et
    end

    # differential energy
    function dE(S, k, N)
        local dEt = 0
        for (j,Jv) in Jd[k]
            @inbounds dEt += S[k]*Jv*S[j]*2
        end
        @inbounds dEt += S[k]*Hd[k]*2
        dEt
    end

    # probability for dE
    PrE(dE, T) = exp(-dE/T)

    # flip spin at x
    function flipx!(list, x)
        list[x] *= -1
    end

    # initialize
    function initS(S, N)
        for i in 1:N
            if rand() < 0.5
                flipx!(S,i) # random flip at first
            end
        end
    end
    
    # MCMC
    function MCMC( S, T, N, trial)
        # initialize
        #simE = zeros(Int, div(trial,1000)+1)
        simE = zeros(Float32, div(trial,1000)+1)

        # MCMC trial
        Ec = E(S,N) # current energy
        simE[1] = Ec
        local k, de
        @inbounds for t in 1:trial
            k  = rand(1:N) # Gibbs sampling position
            de = dE(S, k, N)
            if rand() < PrE(de, T) # MH criteria   
                flipx!(S, k) # change k
                Ec += de     # change E
            end
            (t % 1000 == 0) && (simE[div(t,1000)+1] = Ec)
        end

        (simE)
    end
    
    return (E, initS, MCMC)
end # of functor

end # of module