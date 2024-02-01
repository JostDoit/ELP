module JsonDecoder exposing (Meaning, PartOfSpeach, Definition, mainDecoder)

import Json.Decode exposing (Decoder, map2, map3, field, int, string, list, at)


-- TYPES

type alias Meaning =
  { word : String
  , meanings : List PartOfSpeach
  }

type alias PartOfSpeach =
  { partOfSpeech : String
  , definitions : List Definition
  }

type alias Definition =
  { definition : String
  , synonyms : List String
  , antonyms : List String
  }


-- JSON

mainDecoder : Decoder (List Meaning)
mainDecoder = 
  list meaningDecoder

meaningDecoder : Decoder Meaning
meaningDecoder =
  map2 Meaning
    (field "word" string)
    (field "meanings" (list partOfSpeachDecoder))

partOfSpeachDecoder : Decoder PartOfSpeach
partOfSpeachDecoder =
  map2 PartOfSpeach
    (field "partOfSpeech" string)
    (field "definitions" (list definitionDecoder))

definitionDecoder : Decoder Definition
definitionDecoder =
    map3 Definition
    (field "definition" string)
    (field "synonyms" (list string))
    (field "antonyms" (list string))