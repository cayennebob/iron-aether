module Main where

{-| Module doc goes here. -}

import Battle
import Signal exposing ( Signal , (<~) , (~) )
import Graphics.Element as Element
import Graphics.Input.Field as Field


-- Signals


main = mainView

foldGame : Signal Metagame
foldGame = Signal.foldp metaUpdate initMetagame metaUpdateSignal

nameBoxMail : Signal.Mailbox Field.Content
nameBoxMail = Signal.mailbox Field.noContent

metaUpdateSignal : Signal MetaUpdate 
metaUpdateSignal = 
    let
    amail = Battle.abilityMail
    in
    Signal.merge  
        ( Signal.map MetaInput nameBoxMail.signal )
        ( Signal.map BattleInput amail.signal )


-- Models

type MetaUpdate = BattleInput Battle.Ability
                | MetaInput Field.Content 


type alias Metagame = 
    { game:Battle.Game 
    , name:Field.Content 
    }

initMetagame : Metagame
initMetagame = 
    { game = Battle.initGame
    , name = initNameContent 
    }    

-- this is what Field.Content looks like!
initNameContent : Field.Content
initNameContent =
    Field.Selection 0 0 Field.Forward 
    |> Field.Content ""

-- Updates

metaUpdate : MetaUpdate -> Metagame -> Metagame
metaUpdate metaupdate metagame = metagame



-- Views

mainView = Battle.main

nameBox : Field.Content -> Element.Element
nameBox name = 
    name |>
    Field.field Field.defaultStyle 
        ( Signal.message nameBoxMail.address ) "Enter Name" 





