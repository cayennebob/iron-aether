import Color
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
                       , friendly : Bool
                       , name : String
                       }

type alias Game = { player : Character
                  , enemy : Character
                  , events : List String
                  , seed : Random.Seed
                  , seedInitialized : Bool
                  }

type Attack = BasicAttack

type CombatState = InProgress | Won | Lost

initCharacter : String -> Bool -> Int -> Int -> Int -> Character
initCharacter name friendly hp attack defense =
    { totalHP = hp
    , currentHP = hp
    , attack = attack
    , defense = defense
    , friendly = friendly
    , name = name
    }

initGame : Game
initGame = { player = initCharacter "Skuld" True 100 10 10
           , enemy = initCharacter "Goblin" False 50 10 10
           , events = []
           , seed = Random.initialSeed 0 -- make types happy; not used
           , seedInitialized = False
           }

alive : Character -> Bool
alive char =
    char.currentHP > 0

combatState : Game -> CombatState
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
          |> trimEvents

doAttack : Random.Seed -> Attack -> Character -> Character -> (String, Character, Random.Seed)
doAttack seed attack attacker defender =
    let (roll, newSeed) = Dice.basicRoll seed
        damage = max 0 (roll + attacker.attack - defender.defense + 5)
        updatedHP = defender.currentHP - damage
        message = attacker.name ++ " attacks " ++ defender.name ++ " for "
                        ++ (toString damage) ++ " damage"
    in (message, { defender | currentHP <- updatedHP }, newSeed)

doPlayerAttack : Attack -> Game -> Game
doPlayerAttack attack model =
    if alive model.player
       then
            let (message, updatedEnemy, newSeed) =
                    doAttack model.seed attack model.player model.enemy
            in { model | enemy <- updatedEnemy
                       , events <- message :: model.events
                       , seed <- newSeed }
       else model

doEnemyAttack : Game -> Game
doEnemyAttack model =
    if alive model.enemy
        then
            let (message, updatedPlayer, newSeed) =
                    doAttack model.seed BasicAttack model.enemy model.player
            in { model | player <- updatedPlayer
                       , events <- message :: model.events
                       , seed <- newSeed }
        else model

trimEvents : Game -> Game
trimEvents game =
    { game | events <- List.take 8 game.events }

-- SIGNALS

game : Signal.Signal Game
game =
    attack.signal
        |> Time.timestamp
        |> Signal.foldp update initGame

attack : Signal.Mailbox Attack
attack = Signal.mailbox BasicAttack

main : Signal Element
main =
    Signal.map view game

-- VIEW

hpBar : Character -> Element
hpBar character =
    -- TODO: actual bar
    Element.show (character.currentHP, character.totalHP)

characterView : Character -> Element
characterView character =
    Element.flow Element.down
        [ Element.show "Picture here"
        , hpBar character
        ]

view : Game -> Element
view game =
    Element.flow Element.down
        [ Element.show (combatState game)
        , Element.flow Element.right
              [ characterView game.enemy
              , Element.flow Element.down (List.map Element.show game.events)
              , characterView game.player
              ]
        , Input.button (Signal.message attack.address BasicAttack) "Attack"
        ]
