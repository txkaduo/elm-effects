module RandomGifList where

import Components as C exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import Task
import RandomGif as Gif


app =
  C.start
    { init = init
    , update = update
    , view = view
    }


main =
  app.html


port tasks : Signal (Task.Task Never ())
port tasks =
  app.tasks


-- MODEL

type alias Model =
    { topic : String
    , gifList : List (Int, Gif.Model)
    , uid : Int
    }


init : Transaction Message Model
init =
  done { topic = "", gifList = [], uid = 0 }


-- UPDATE

type Message
    = Topic String
    | Create
    | SubMsg Int Gif.Message


update : Message -> Model -> Transaction Message Model
update message model =
  case message of
    Topic topic ->
      done { model | topic <- topic }

    Create ->
      with
        (tag (SubMsg model.uid) (Gif.init model.topic))
        (\newRandomGif ->
            done { model |
                topic <- "",
                uid <- model.uid + 1,
                gifList <- model.gifList ++ [(model.uid, newRandomGif)]
            }
        )

    SubMsg msgId msg ->
      let subUpdate (id, randomGif) =
            if id == msgId then
                with
                  (tag (SubMsg id) (Gif.update msg randomGif))
                  (\newRandomGif -> done (id, newRandomGif))
            else
                done (id, randomGif)
      in
        with
          (C.list (List.map subUpdate model.gifList))
          (\gifList -> done { model | gifList <- gifList })


-- VIEW

(=>) = (,)


view : Signal.Address Message -> Model -> Html
view address model =
  div []
    [ input
        [ placeholder "What kind of gifs do you want?"
        , value model.topic
        , onEnter address Create
        , on "input" targetValue (Signal.message address << Topic)
        , inputStyle
        ]
        []
    , div [ style [ "display" => "flex", "flex-wrap" => "wrap" ] ]
        (List.map (elementView address) model.gifList)
    ]


elementView : Signal.Address Message -> (Int, Gif.Model) -> Html
elementView address (id, model) =
  Gif.view (Signal.forwardTo address (SubMsg id)) model


inputStyle : Attribute
inputStyle =
  style
    [ ("width", "100%")
    , ("height", "40px")
    , ("padding", "10px 0")
    , ("font-size", "2em")
    , ("text-align", "center")
    ]


onEnter : Signal.Address a -> a -> Attribute
onEnter address value =
    on "keydown"
      (Json.customDecoder keyCode is13)
      (\_ -> Signal.message address value)


is13 : Int -> Result String ()
is13 code =
  if code == 13 then Ok () else Err "not the right key code"