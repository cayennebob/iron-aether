import Graphics.Element as Element
import Graphics.Input as Input

-- MODEL

type alias Character = { totalHP : Int
                       , currentHP : Int
                       , attack : Int
                       }

type alias Game = { player : Character
                  , enemy : Character
                  }

initCharacter : Int -> Int -> Character
initCharacter hp attack =
    { totalHP = hp
    , currentHP = hp
    , attack = attack
    }

initGame : Game
initGame = { player = initCharacter 100 10
           , enemy = initCharacter 100 9
           }

-- UPDATE

type Attack = BasicAttack

update : Attack -> Game -> Game
update attack model =
    model |> doPlayerAttack attack
          |> doEnemyAttack

doPlayerAttack : Attack -> Game -> Game
doPlayerAttack attack model =
    let enemy = model.enemy
        player = model.player
        updatedHP = (enemy.currentHP - player.attack)
        updatedEnemy = { enemy | currentHP <- updatedHP }
    in { model | enemy <- updatedEnemy }

doEnemyAttack : Game -> Game
doEnemyAttack model =
    let player = model.player
        enemy = model.enemy
        updatedHP = player.currentHP - enemy.attack
        updatedPlayer = { player | currentHP <- updatedHP }
    in { model | player <- updatedPlayer }

-- SIGNALS

game : Signal.Signal Game
game =
    Signal.foldp update initGame attack.signal

-- VIEW

attack : Signal.Mailbox Attack
attack = Signal.mailbox BasicAttack

main : Signal Element.Element
main =
    Signal.map view game

view : Game -> Element.Element
view game =
    Element.flow Element.down
        [ Element.show game
        , Input.button (Signal.message attack.address BasicAttack) "Attack"
        ]
