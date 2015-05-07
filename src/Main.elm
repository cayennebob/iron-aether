module Main where

{-| Module doc goes here -}

import Color
import Graphics.Element as Element exposing (Element)
import Graphics.Input as Input
import Random
import Time exposing (Time)
import List

import Dice

-- MODEL

type alias Character = { totalHP : Int
                       , currentHP : Int
                       , attack : Int
                       , defense : Int
                       , friendly : Bool
                       , name : String
                       , abilities : List Ability
                       }

type alias Game = { player : Character
                  , enemy : Character
                  , events : List String
                  , seed : Random.Seed
                  , seedInitialized : Bool
                  }

type Ability = BasicAttack
            | Retreat

abilityName : Ability -> String
abilityName ability = 
    case ability of
      BasicAttack -> "Basic Attack"
      Retreat -> "Retreat"


type CombatState = InProgress | Won | Lost

initCharacter : String -> Bool -> Int -> Int -> Int -> Character
initCharacter name friendly hp attack defense =
    { totalHP = hp
    , currentHP = hp
    , attack = attack
    , defense = defense
    , friendly = friendly
    , name = name
    , abilities = [ BasicAttack , Retreat ]
    }

initGame : Game
initGame = { player = initCharacter "Skuld" True 100 10 10
           , enemy = initCharacter "Goblin" False 50 10 10
           , events = [""]
           , seed = Random.initialSeed 0 -- make types happy; not used
           , seedInitialized = False
           }

alive : Character -> Bool
alive char =
    char.currentHP > 0

combatState : Game -> CombatState
combatState game =
    if | not (alive game.player) -> Lost
       | not (alive game.enemy) -> Won
       | otherwise -> InProgress

-- UPDATE

update : (Time, Ability) -> Game -> Game
update (time, attack) game =
    game |> Dice.ensureSeed time
         |> doPlayerAttack attack
         |> doEnemyAttack
         |> trimEvents

doAttack : Random.Seed -> Ability -> Character -> Character -> 
          (String, Character, Random.Seed)
doAttack seed attack attacker defender =
    let (roll, newSeed) = Dice.basicRoll seed
        damage = max 0 (roll + attacker.attack - defender.defense + 5)
        updatedHP = defender.currentHP - damage
        message = attacker.name ++ " attacks " ++ defender.name ++ " for "
                        ++ (toString damage) ++ " damage"
    in (message, { defender | currentHP <- updatedHP }, newSeed)

doPlayerAttack : Ability -> Game -> Game
doPlayerAttack attack game =
    if alive game.player
       then
            let (message, updatedEnemy, newSeed) =
                    doAttack game.seed attack game.player game.enemy
            in { game | enemy <- updatedEnemy
                      , events <- message :: game.events
                      , seed <- newSeed }
       else game

doEnemyAttack : Game -> Game
doEnemyAttack game =
    if alive game.enemy
        then
            let (message, updatedPlayer, newSeed) =
                    doAttack game.seed BasicAttack game.enemy game.player
            in { game | player <- updatedPlayer
                      , events <- message :: game.events
                      , seed <- newSeed }
        else game

trimEvents : Game -> Game
trimEvents game =
    { game | events <- List.take 8 game.events }

-- SIGNALS

game : Signal.Signal Game
game =
    abilityMail.signal
        |> Time.timestamp
        |> Signal.foldp update initGame

abilityMail : Signal.Mailbox Ability
abilityMail = Signal.mailbox BasicAttack

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
    List.concat
    [
        [ Element.show (combatState game)
        , Element.flow Element.right
            [ characterView game.enemy
            , Element.flow Element.down (List.map Element.show game.events)
            , characterView game.player
            ]
        ]
    ,
        List.map abilityButton (.abilities game.player)
    ]
    |> Element.flow Element.down

abilityButton : Ability -> Element
abilityButton ability = 
    Input.button 
    (Signal.message abilityMail.address ability)
    (abilityName ability)







