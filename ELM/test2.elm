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
  | Success String


init : () -> (Model, Cmd Msg)
init _ =
  (Loading, getWordDefinition)



-- UPDATE


type Msg
  = GotWordDefinition (Result Http.Error List String)


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
        [ h1 [] [ text definition ]]



-- HTTP


getWordDefinition : Cmd Msg
getWordDefinition =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/with"
    , expect = Http.expectJson GotWordDefinition wordDefinitionListDecoder
    }

wordDefinitionListDecoder : Decoder (List String)
wordDefinitionListDecoder = list wordDefinitionDecoder

wordDefinitionDecoder : Decoder String
wordDefinitionDecoder =  
    (field "word" string)