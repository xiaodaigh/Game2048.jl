# replay a game step by step
export GameReplayer

function GameReplayer()
    board = initboard()
    i = 1
    return function()
        display(h[i])
        display(policy(h[i]))
        i+=1
    end
end
