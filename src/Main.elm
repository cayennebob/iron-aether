import Graphics.Element as Element exposing (Element)
import Graphics.Input as Input
import Random
import Time exposing (Time)

import Dice

-- MODEL

type alias Character = { totalHP : Int
                       , currentHP : Int
                       , attack : Int
                       , defense : Int
                       }

type alias Game = { player : Character
                  , enemy : Character
                  , seed : Random.Seed
                  , seedInitialized : Bool
                  }

type Attack = BasicAttack

type CombatState = InProgress | Won | Lost

initCharacter : Int -> Int -> Int -> Character
initCharacter hp attack defense =
    { totalHP = hp
    , currentHP = hp
    , attack = attack
    , defense = defense
    }

initGame : Game
initGame = { player = initCharacter 100 10 10
           , enemy = initCharacter 50 10 10
           , seed = Random.initialSeed 0 -- make types happy; not used
           , seedInitialized = False
           }

alive : Character -> Bool
alive char =
    char.currentHP > 0

combatState model =
    if | not (alive model.player) -> Lost
       | not (alive model.enemy) -> Won
       | otherwise -> InProgress

-- UPDATE

update : (Time, Attack) -> Game -> Game
update (time, attack) model =
    model |> Dice.ensureSeed time
          |> doPlayerAttack attack
          |> doEnemyAttack

doAttack : Random.Seed -> Attack -> Character -> Character -> (Character, Random.Seed)
doAttack seed attack attacker defender =
    if alive attacker
       then let (roll, newSeed) = Dice.basicRoll seed
                damage = max 0 (roll + attacker.attack - defender.defense + 5)
                updatedHP = defender.currentHP - damage
            in ({ defender | currentHP <- updatedHP }, newSeed)
       else (defender, seed)

doPlayerAttack : Attack -> Game -> Game
doPlayerAttack attack model =
    let (updatedEnemy, newSeed) =
            doAttack model.seed attack model.player model.enemy
    in { model | enemy <- updatedEnemy
               , seed <- newSeed }

doEnemyAttack : Game -> Game
doEnemyAttack model =
    let (updatedPlayer, newSeed) =
            doAttack model.seed BasicAttack model.enemy model.player
    in { model | player <- updatedPlayer
               , seed <- newSeed }

-- SIGNALS

game : Signal.Signal Game
game =
    attack.signal
        |> Time.timestamp
        |> Signal.foldp update initGame

-- VIEW

attack : Signal.Mailbox Attack
attack = Signal.mailbox BasicAttack

main : Signal Element
main =
    Signal.map view game

view : Game -> Element
view game =
    Element.flow Element.down
        [ Element.show (combatState game)
        , Element.show game
        , Input.button (Signal.message attack.address BasicAttack) "Attack"
        ]
