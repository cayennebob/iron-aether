module Battle where

{-| Module doc goes here. Or does it? -}

import Color
import Graphics.Element as Element exposing (Element)
import Graphics.Input as Input
import Random
import Time exposing (Time)
import List

import Dice



-- MODEL

type alias Character = { hpMax : Int
                       , hp : Int
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
                  , combatState : CombatState
                  }

type Ability = BasicAttack
             | NoAction
             | Retreat
             | Defend
             | Heal
             | FightAgain

abilityName : Ability -> String
abilityName ability = 
    case ability of
      BasicAttack -> "Basic Attack"
      Retreat -> "Retreat"
      NoAction -> "Do Nothing"
      Defend -> "Defend"
      Heal -> "Heal"
      FightAgain -> "Fight Again!"
      _ -> "Unknown"

abilityAvailable : Game -> Ability -> Bool
abilityAvailable game ability =
    case ability of
      FightAgain -> game.combatState /= InProgress 
          && (.hp game.player > 0)
      BasicAttack -> game.combatState == InProgress 
      Retreat -> game.combatState == InProgress 
      Heal -> True
      _ -> False


type CombatState = InProgress | Won | Lost | Draw

initCharacter : String -> Bool -> Int -> Int -> Int -> Character
initCharacter name friendly hp attack defense =
    { hpMax = hp
    , hp = hp
    , attack = attack
    , defense = defense
    , friendly = friendly
    , name = name
    , abilities = [ BasicAttack 
                  , Defend
                  , Heal
                  , Retreat 
                  , NoAction 
                  , FightAgain
                  ]
    }

initGame : Game
initGame = { player = initCharacter "Skuld" True 100 10 10
           , enemy = initCharacter "Goblin" False 70 10 10
           , events = ["Begin!"]
           , seed = Random.initialSeed 0 -- make types happy; not used
           , seedInitialized = False
           , combatState = InProgress
           }

alive : Character -> Bool
alive char =
    char.hp > 0

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
         |> updateCombatState 
         |> trimEvents


doPlayerAbility : Ability -> Game -> Game
doPlayerAbility ability game =
  if abilityAvailable game ability |> not then game else
  let
  (game', message, player', enemy') =
  doAbility game ability game.player game.enemy 
  in
  { game' | player <- player'
        , enemy <- enemy'
        , events <- message :: game.events
        }

doEnemyAbility : Game -> Game
doEnemyAbility game =
  if game.combatState /= InProgress then game else
  let
  (game', message, enemy', player') =
  doAbility game BasicAttack game.enemy game.player 
  in
  { game' | player <- player'
         , enemy <- enemy'
         , events <- message :: game.events
         }


doAbility : Game -> Ability -> Character -> Character ->
            (Game, String, Character, Character)
doAbility game ability actor target =
  case ability of 
    BasicAttack -> doBasicAttack game actor target
    FightAgain -> doFightAgain game
    Heal -> doHeal game actor target
    _ -> (game, actor.name ++ " does nothing", actor, target)

doBasicAttack : Game -> Character -> Character ->
            (Game, String, Character, Character)     
doBasicAttack game actor target =
  let 
  (roll, seed') = Dice.basicRoll game.seed
  damage = max 0 (roll + actor.attack - target.defense + 5)
  actor' = actor
  target' = { target | hp <- target.hp - damage }
  message = actor.name ++ " attacks " ++ target.name 
            ++ " for " ++ (toString damage) ++ " damage"
  in
  ({game|seed<-seed'}, message , actor' , target')

doFightAgain : Game -> (Game, String, Character, Character)
doFightAgain game =
    let 
    state' = InProgress
    enemy' = initCharacter "Goblin" False 70 10 10
    in
    ({game|combatState <- state'}, "A new combat begins!", game.player, enemy')

doHeal : Game -> Character -> Character ->
         (Game, String, Character, Character)
doHeal game actor target =
    let 
    healAmt = 10
    actor' = {actor| hp <- min (actor.hp+healAmt) actor.hpMax}
    message = actor.name ++ " heals " ++ (toString healAmt) ++ " damage"
    in
    (game , message , actor', target)

updateCombatState : Game -> Game
updateCombatState game = 
    if game.combatState /= InProgress then game else
    let 
    pcDead = .hp game.player < 0
    npcDead = .hp game.enemy < 0
    state' = if | pcDead && npcDead -> Draw
                | pcDead -> Lost
                | npcDead -> Won
                | otherwise -> InProgress
    in
    {game| combatState <- state'}


trimEvents : Game -> Game
trimEvents game =
    { game | events <- List.take 12 game.events }



-- SIGNALS

game : Signal.Signal Game
game =
    abilityMail.signal
        |> Time.timestamp
        |> Signal.foldp update initGame

abilityMail : Signal.Mailbox Ability
abilityMail = Signal.mailbox BasicAttack  -- BasicAttack is the default

main : Signal Element
main =
    Signal.map view game



-- VIEW


view : Game -> Element
view game =
    Element.flow Element.down
    [ menuButtons game
    , Element.show game.combatState
    , Element.flow Element.right
      [ characterView game.player
      , Element.flow Element.down (List.map Element.show game.events)
      , characterView game.enemy
      ]
    ]

menuButtons : Game -> Element
menuButtons game =
    List.filterMap (maybeAbilityButton game) (.abilities game.player)
        |> Element.flow Element.right

maybeAbilityButton : Game -> Ability -> Maybe Element
maybeAbilityButton game ability = 
    if abilityAvailable game ability then
    Input.button 
    (Signal.message abilityMail.address ability)
    (abilityName ability) |> Just
    else Nothing

characterView : Character -> Element
characterView character =
    Element.flow Element.down
        [ Element.show "Picture here"
        , hpBar character
        ]

hpBar : Character -> Element
hpBar character =
    -- TODO: actual bar
    Element.show (character.hp, character.hpMax)






