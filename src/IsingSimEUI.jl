#=
title: IsingSimEUI( manipulatable Ising model simulation with Electron UI ) 
version: 1.0
date: 2020/08/12
author: okimebarun
url: https://github.com/okimebarun/
url: https://qiita.com/oki_mebarun/
=#

module IsingSimEUI

greet() = print("Hello World!")

###################################################################################################
# load libraries
using Electron

# load local modules
include("HexaLatticeModel03a.jl")
include("SquareLatticeModel03a.jl")
include("IsingMCMC04a.jl")

###################################################################################################
# prepare
# setting for energy function

function genInitialJH(d=d)
    Jd = [Dict{Int,Int8}() for i in 1:d.N]
    Hd = zeros(Float32, d.N)
    (Jd, Hd)
end

function setJH!( Jd=Jd, Hd=Hd, d=d)
    J0 = 1
    H0 = 0
    for i in 1:d.N
        for j in getNeighbors(i,d)
            @inbounds Jd[i][j] = J0
        end
        @inbounds Hd[i] = H0
    end
end

function setH!(H0, Hd=Hd, d=d)
    @simd for i in 1:d.N
        @inbounds Hd[i] = H0
    end
end

###################################################################################################
# JS command

function jscmd(cmd, win=win)
    run(win, cmd)
end

function drawBH(H, S, d=d, N=N)
    x = H
    y = sum(S)/N
    jscmd("drawbox02.setrange(-1.1,1.1,-1.1,1.1);")
    jscmd("trajectory.add($(x), $(y) );")
end

function drawSim02(snap, d=d, N=N)
    jscmd("drawbox01.setrange(0,$(d.ncols),0,$(d.nrows));")
    
    (xs,ys) = genPoly(1, d)
    len = length(xs)
    ps = zeros(len*2*N)
    i1 = 0 
    @inbounds @simd for i in 1:N
        # bits
        (xs,ys) = genPoly(i, d)
        if (snap[i] == 1) # up-spin
            for i in 0:(len-1)
                ps[i*2 + 1 + i1*len] = xs[i + 1]
                ps[i*2 + 2 + i1*len] = ys[i + 1]
            end
            i1 += 2
        else # down-spin
        end
    end
    jscmd("drawbox01.clear();")
    jscmd("drawbox01.drawPoly02($(string(ps)), $(string(len)) );")
end

###################################################################################################
# setting for model
d = SquareLatticeModel.ParamDict(128,128,0)
N = d.nrows * d.ncols
d.N = N

###################################################################################################
# simulation main

main_html_uri = string("file:///", replace(joinpath(@__DIR__, "IsingView01b.html"), '\\' => '/'))

function winmain(mdlno)
    ##########
    # setting for simulation
    trial = 10^5 # MCMC trial
    
    # gen functors as global
    global getNeighbors, genPoly
    if mdlno == 1
        (getNeighbors, genPoly)= SquareLatticeModel.genFunctor(d)
    elseif mdlno == 2
        (getNeighbors, genPoly)= HexaLatticeModel.genFunctor(d)
    end
    
    # generate Jd, Hd
    (Jd, Hd) = genInitialJH(d)
    setJH!(Jd, Hd)
    
    # simulation
    global E, initS, MCMC
    (E, initS, MCMC) = IsingMCMC.genFunctor(Jd, Hd)
    S = ones(Int8, N)
    initS(S, N)

    ##########
    global win
    win = Window( URI(main_html_uri))
    ElectronAPI.setBounds(win, Dict("width"=>1050, "height"=>700))
    ch = msgchannel(win)

    while true
        local msg, jscmd
        try
            msg = take!(ch)
        catch
            println("channel closed.")
            break
        end

        m = match(r"^calc T:(?<T>[\d\.]+) H:(?<H>[-\d\.]+)", msg)
        if !(m === nothing)
            T = parse(Float32, m[:T])
            H = parse(Float32, m[:H])
            print("calc with T=$(T) & H=$(H)")
            setH!(H, Hd, d)
            #
            @time (simE) = MCMC(S, T, N, trial);
            drawSim02(S)
            drawBH(H, S)
        end
    end
end

###################################################################################################
# main functions for PackageCompiler

function julia_main()
    try
        real_main()
    catch
        Base.invokelatest(Base.display_error, Base.catch_stack())
        return 1
    end
    return 0
end

#
function real_main()
    @show ARGS
    @show Base.PROGRAM_FILE

    # do something
    winmain(1)
end

if abspath(PROGRAM_FILE) == @__FILE__
    real_main()
end
#
end # module
