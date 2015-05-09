module Main where

{-| Module doc goes here. Or does it? -}

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
             | NoAction
             | Retreat
             | Defend
             | Heal

abilityName : Ability -> String
abilityName ability = 
    case ability of
      BasicAttack -> "Basic Attack"
      Retreat -> "Retreat"
      NoAction -> "Do Nothing"
      Defend -> "Defend"
      _ -> "Unknown"


type CombatState = InProgress | Won | Lost

initCharacter : String -> Bool -> Int -> Int -> Int -> Character
initCharacter name friendly hp attack defense =
    { totalHP = hp
    , currentHP = hp
    , attack = attack
    , defense = defense
    , friendly = friendly
    , name = name
    , abilities = [ BasicAttack 
                  , Defend
                  , NoAction 
                  , Retreat 
                  ]
    }

initGame : Game
initGame = { player = initCharacter "Skuld" True 100 10 10
           , enemy = initCharacter "Goblin" False 90 10 10
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
update (time, ability) game =
    game |> Dice.ensureSeed time
         |> doPlayerAbility ability 
         |> doEnemyAbility 
         |> trimEvents


doPlayerAbility : Ability -> Game -> Game
doPlayerAbility ability game =
  if not <| alive game.player then game else
  let
  (seed', message, player', enemy') =
  doAbility game.seed ability game.player game.enemy 
  in
  {game | player <- player'
        , enemy <- enemy'
        , seed <- seed' 
        , events <- message :: game.events
        }

doEnemyAbility : Game -> Game
doEnemyAbility game =
  if not <| alive game.enemy then game else
  let
  (seed', message, enemy', player') =
  doAbility game.seed BasicAttack game.enemy game.player 
  in
  { game | player <- player'
         , enemy <- enemy'
         , seed <- seed'
         , events <- message :: game.events
         }


doAbility : Random.Seed -> Ability -> Character -> Character ->
            (Random.Seed, String, Character, Character)
doAbility seed ability actor target =
  case ability of 
    BasicAttack -> doBasicAttack seed actor target
    _ -> (seed, actor.name ++ " does nothing", actor, target)

doBasicAttack : Random.Seed -> Character -> Character ->
            (Random.Seed, String, Character, Character)     
doBasicAttack seed actor target =
  let 
  (roll, seed') = Dice.basicRoll seed
  damage = max 0 (roll + actor.attack - target.defense + 5)
  actor' = actor
  target' = { target | currentHP <- target.currentHP - damage }
  message = actor.name ++ " attacks " ++ target.name 
            ++ " for " ++ (toString damage) ++ " damage"
  in
  (seed', message , actor' , target')


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
    [ List.map abilityButton (.abilities game.player)
        |> Element.flow Element.right
    , Element.show (combatState game)
    , Element.flow Element.right
      [ characterView game.enemy
      , Element.flow Element.down (List.map Element.show game.events)
      , characterView game.player
      ]
    ]
    |> Element.flow Element.down

abilityButton : Ability -> Element
abilityButton ability = 
    Input.button 
    (Signal.message abilityMail.address ability)
    (abilityName ability)







