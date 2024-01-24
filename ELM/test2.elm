import Browser
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Events exposing (..)
import Http
import Random
import Array exposing (Array, get, fromList)
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


type alias Model = 
  { wordToGuess : String
  , userInput : String
  , wordsList : List String
  , userFoundword : Bool
  , result : Result Http.Error (List Package)
  , boxChecked : Bool
  }


type alias Package =
  { word : String
  , meanings : List Meaning
  }

type alias Meaning =
  { partOfSpeech : String
  , definitions : List Definition
  }

type alias Definition =
  { definition : String
  , synonyms : List String
  , antonyms : List String
  }


init : () -> (Model, Cmd Msg)
init _ =
  (initModel, getWordsList)

initModel : Model
initModel =
  { wordToGuess = "with"
  , userInput = ""
  , status = Loading
  , wordsList = []
  , result = Ok []
  , boxChecked = False
  }


-- UPDATE


type Msg
  = GotWordsList (Result Http.Error String)
  | GotPackages (Result Http.Error (List Package))
  | UserInput String
  | BoxChecked
  | GetRandomWord
  | RandomNumber Int



update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    
    GotWordsList (Ok words) ->
      ( { model | wordsList = String.split " " words }, GetRandomWord)

    GetRandomWord ->
      case List.length model.wordsList of
        0 ->
          (model, Cmd.none)

        _ ->
          let
            randomNumber =
              Random.generate RandomNumber (Random.int 0 (List.length model.wordsList - 1))
            
          in
            (model, randomNumber)

    RandomNumber rnumber ->
      let
        wordToGuess =
          get rnumber (fromList model.wordsList)
      in
        case wordToGuess of
          Nothing ->
            (model, Cmd.none)

          Just word ->
            ( { model | wordToGuess = wordToGuess }, askApi word)

    GotPackages result ->
      ( { model | result = result }, Cmd.none )

    UserInput input ->
      let
        wordFound =
          case model.wordToGuess of
            Just correctWword ->
              input == correctWword
            
            Nothing ->
              False
      in
        ( { model | userInput = input, userFoundword = wordFound }, Cmd.none )
    
    BoxChecked ->
      ( { model | boxChecked = not model.boxChecked }, Cmd.none )
        


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


-- VIEW


view : Model -> Html Msg
view model =
  div []
    [ h1 [] [ text "Guess It !" ]
    , viewListPackage model
    ]


viewListPackage : Model -> Html Msg
viewListPackage model =
  case model.status of
    Failure ->
      text "I could not load the definition for some reason. "

    Loading ->
      text "Loading..."

    Ok listPackage ->
      div []
        [ h1 [] [ text "With" ]
        , ul [] (viewPackage listPackage)          
        ]

viewPackage : List Package -> List (Html Msg)
viewPackage listPackage =
  case listPackage of
    [] ->
      [text ""]

    (package :: rest) ->
      [ li [] 
        [ text "meaning"
        , ol [] (viewMeanings package.meanings)
        ]
      ] ++ viewPackage rest

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

getWordsList : Cmd Msg
getWordsList =
  Http.get
    { url = "words.txt"
    , expect = Http.expectString GotWordsList
    }

getWordDefinition : Cmd Msg
getWordDefinition =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/with"
    , expect = Http.expectJson GotPackages mainDecoder
    }

mainDecoder : Decoder (List Package)
mainDecoder = 
  list packageDecoder

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