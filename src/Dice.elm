module Dice where

import Random
import Time exposing (Time)

type alias WithSeed a = { a | seed : Random.Seed
                            , seedInitialized : Bool
                            }

ensureSeed : Time -> WithSeed a -> WithSeed a
ensureSeed time model =
    if model.seedInitialized
       then model
       else { model | seedInitialized <- True 
            , seed <- Random.initialSeed (floor time) }     

twoDTenGen : Random.Generator (Int, Int)
twoDTenGen = Random.pair (Random.int 1 10) (Random.int 1 10)

basicRoll : Random.Seed -> (Int, Random.Seed)
basicRoll seed =
    let ((firstDie, secondDie), newSeed) = Random.generate twoDTenGen seed
    in (firstDie + secondDie, newSeed)
    
