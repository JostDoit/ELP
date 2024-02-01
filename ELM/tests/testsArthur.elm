import Browser
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, map2, field, int, string, list, at)



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
  | Success Package


type alias Package =
  { word : String
  , meanings : List Meaning
  }

type alias Meaning =
  { partOfSpeech : String
  , definitions : List Definition
  }

type alias Definition =
  { definition : String}


init : () -> (Model, Cmd Msg)
init _ =
  (Loading, getWordDefinition)



-- UPDATE


type Msg
  = GotWordDefinition (Result Http.Error Package)


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
    [ h1 [] [ text "Guess It !" ]
    , viewPackage model
    ]


viewPackage : Model -> Html Msg
viewPackage model =
  case model of
    Failure ->
      text "I could not load the definition for some reason. "

    Loading ->
      text "Loading..."

    Success definition ->
      div []
        [ h1 [] [ text definition.word ]
        , ul []
          [ li [] 
            [ text "Meanings"
            , ul [] (viewMeanings definition.meanings)
            ]
          ]
        ]

viewMeanings : List Meaning -> List (Html Msg)
viewMeanings meanings =
  case meanings of
    [] ->
      [text ""]

    (meaning :: rest) ->      
      
      [ li [] 
        [ text meaning.partOfSpeech
        , ol [] (viewDefinitions meaning.definitions)      
        ]
      ] ++ viewMeanings rest
      
        

viewDefinitions : List Definition -> List (Html Msg)
viewDefinitions definitions =
  List.map (\definition -> li[] [text definition.definition]) definitions

-- HTTP


getWordDefinition : Cmd Msg
getWordDefinition =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/with"
    , expect = Http.expectJson GotWordDefinition mainDecoder
    }

mainDecoder = at["0"](packageDecoder)

packageDecoder : Decoder Package
packageDecoder =
  map2 Package
    (field "word" string)
    (field "meanings" (list meaningDecoder))

meaningDecoder : Decoder Meaning
meaningDecoder =
  map2 Meaning
    (field "partOfSpeech" string)
    (field "definitions" (list definitionDecoder))

definitionDecoder : Decoder Definition
definitionDecoder =
    Json.Decode.map Definition
    (field "definition" string)