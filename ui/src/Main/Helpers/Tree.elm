module Main.Helpers.Tree exposing (..)

import Main.Helpers.List as List
import Tree exposing (Tree)


type alias Trees a =
    List (Tree a)


lookupSubTrees : (a -> k) -> List k -> Trees a -> Trees a
lookupSubTrees keyOf path ts =
    case path of
        [] ->
            ts

        p :: ps ->
            case
                ts
                    |> List.filterMap
                        (\t ->
                            if p == keyOf (Tree.label t) then
                                Just t

                            else
                                Nothing
                        )
                    |> List.head
            of
                Just t ->
                    t |> Tree.children |> lookupSubTrees keyOf ps

                Nothing ->
                    []


type alias AssocPath key value =
    List.Assoc (List key) value


unflattenChart : AssocPath key a -> List (Tree ( key, List a ))
unflattenChart name2opt =
    name2opt
        |> groupChart
        |> unfoldTrees
            (\( key, keyGroup ) ->
                let
                    seeds =
                        keyGroup |> groupChart
                in
                ( ( key
                  , keyGroup
                        |> List.concatMap
                            (\( k, v ) ->
                                if k == [] then
                                    [ v ]

                                else
                                    []
                            )
                  )
                , seeds
                )
            )


unfoldTrees : (seed -> ( a, List seed )) -> List seed -> List (Tree a)
unfoldTrees f =
    List.map (Tree.unfold f)


groupChart : AssocPath key a -> List.Assoc key (AssocPath key a)
groupChart xs =
    xs
        |> List.concatMap
            (\( path, value ) ->
                case path of
                    [] ->
                        []

                    keyHead :: keyTail ->
                        [ ( keyHead, ( keyTail, value ) ) ]
            )
        |> List.group
