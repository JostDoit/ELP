module Main exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (placeholder, value, type_, checked)
import Html.Events exposing (..)
import Http
import Random
import Array exposing (Array, get, fromList)
import Json.Decode exposing (Decoder, map2, map3, field, int, string, list, at)



-- MAIN

main : Program () Model Msg
main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }



-- MODEL


type alias Model = 
  { wordToGuess : Maybe String
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
  { wordToGuess = Nothing
  , userInput = ""
  , wordsList = []
  , result = Ok []
  , userFoundword = False
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
      let
        wordsList =
          String.split " " words
        
        randomNumber =
          Random.generate RandomNumber (Random.int 0 (List.length wordsList - 1))
      in
        ( { model | wordsList = wordsList }, randomNumber)
    
    GotWordsList (Err _) ->
      (model, Cmd.none)

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
  case model.result of
    Ok packages ->
      div []
        [ 
          h1 [] [ text (if model.boxChecked then Maybe.withDefault "No word to guess !" model.wordToGuess else "Guess it !") ]
          ,div []
            [
              ul[] (viewPackage packages)
            ]
          ,div []
            [ 
              label [] [ text (if model.userFoundword then ("Got it! It is indeed " ++ (Maybe.withDefault ""model.wordToGuess)) else "Give it a try !") ]
              ,input [ value model.userInput, onInput UserInput ] []
            ]
          ,div []
            [ label []
              [ input [ type_ "checkbox", checked model.boxChecked, onClick BoxChecked ] []
              ,span [] [ text "Show it" ]
              ]
            ]
        ]
    Err _ ->
      text "Communication error with the API"

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
    { url = "mots.txt"
    , expect = Http.expectString GotWordsList
    }

getWordDefinition : Cmd Msg
getWordDefinition =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/with"
    , expect = Http.expectJson GotPackages mainDecoder
    }

askApi : String -> Cmd Msg
askApi word =
  Http.get
    { url = "https://api.dictionaryapi.dev/api/v2/entries/en/" ++ word
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
    map3 Definition
    (field "definition" string)
    (field "synonyms" (list string))
    (field "antonyms" (list string))