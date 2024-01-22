import Browser
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, map2, field, int, string, list)



-- MAIN


main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }



-- MODEL


type Model
  = Failure
  | Loading
  | Success WordDefinition


type alias WordDefinition =
  { word : String
  , meanings : List Meaning
  }

type alias Meaning =
  { partOfSpeech : String
  , definitions : List Def
  }

type alias Def =
  { definition : String}


init : () -> (Model, Cmd Msg)
init _ =
  (Loading, getWordDefinition)



-- UPDATE


type Msg
  = GotWordDefinition (Result Http.Error WordDefinition)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotWordDefinition result ->
      case result of
        Ok definition ->
          (Success definition, Cmd.none)

        Err _ ->
          (Failure, Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ h2 [] [ text "Random Quotes" ]
    , viewWordDefinition model
    ]


viewWordDefinition : Model -> Html Msg
viewWordDefinition model =
  case model of
    Failure ->
      text "I could not load the definition for some reason. "

    Loading ->
      text "Loading..."

    Success definition ->
      div []
        [ h1 [] [ text definition.word ]
        
        ]



-- HTTP


getWordDefinition : Cmd Msg
getWordDefinition =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/with"
    , expect = Http.expectJson GotWordDefinition wordDefinitionDecoder
    }


wordDefinitionDecoder : Decoder WordDefinition
wordDefinitionDecoder =
  map2 WordDefinition
    (field "word" string)
    (field "meanings" (list meaningDecoder))

meaningDecoder : Decoder Meaning
meaningDecoder =
  map2 Meaning
    (field "partOfSpeech" string)
    (field "definitions" (list definitionDecoder))

definitionDecoder : Decoder Def
definitionDecoder =
    Json.Decode.map Def
    (field "definition" string)