module Main.Helpers.Tree exposing (..)

import Main.Helpers.List as List
import Tree exposing (Tree)
import Tuple exposing (first, second)


type alias Trees a =
    List (Tree a)


restructureTrees : (a -> b) -> (b -> List c -> c) -> List (Tree a) -> List c
restructureTrees mkLabel mkNode =
    List.map (Tree.restructure mkLabel mkNode)


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


countTreeLeaves : Tree a -> Tree ( a, Int )
countTreeLeaves =
    Tree.restructure identity
        (\k ts ->
            Tree.tree
                ( k
                , if ts == [] then
                    1

                  else
                    ts |> List.foldl (\t acc -> acc + (t |> Tree.label |> second)) 0
                )
                ts
        )


countNodes : Tree a -> Tree ( a, Int )
countNodes =
    Tree.restructure identity
        (\k ts ->
            Tree.tree
                ( k
                , if ts == [] then
                    1

                  else
                    ts |> List.foldl (\t acc -> acc + (t |> Tree.label |> second)) 1
                )
                ts
        )


countNodeBranches : Tree a -> Tree ( a, Int )
countNodeBranches =
    Tree.restructure identity
        (\k ts -> Tree.tree ( k, ts |> List.length ) ts)


pruneTrees : (a -> Bool) -> List (Tree a) -> List (Tree a)
pruneTrees test ts =
    let
        filter =
            List.filter (Tree.label >> test)
    in
    ts
        |> List.map
            (Tree.restructure identity
                (\k cs ->
                    Tree.tree k (cs |> filter)
                )
            )
        |> filter


pruneTree : (a -> Bool) -> Tree a -> Tree a
pruneTree continue =
    let
        loop : Tree a -> Tree a
        loop t =
            Tree.tree
                (t |> Tree.label)
                (if t |> Tree.label |> continue then
                    t |> Tree.children |> List.map loop

                 else
                    []
                )
    in
    loop


absoluteTrees : List (Tree ( k, a )) -> List (Tree ( List k, k, a ))
absoluteTrees =
    List.map absoluteTree


absoluteTree : Tree ( k, a ) -> Tree ( List k, k, a )
absoluteTree root =
    let
        loop : List k -> Tree ( List k, k, a ) -> Tree ( List k, k, a )
        loop ancestors t =
            let
                ( path, name, value ) =
                    Tree.label t

                prefix =
                    ancestors ++ path
            in
            Tree.tree
                ( prefix, name, value )
                (t |> Tree.children |> List.map (loop prefix))
    in
    loop [] <|
        Tree.map (\( n, x ) -> ( [ n ], n, x )) root


ancestorsTree : Tree a -> Tree ( List a, a )
ancestorsTree root =
    let
        loop : List a -> Tree ( List a, a ) -> Tree ( List a, a )
        loop ancestors t =
            let
                ( path, value ) =
                    Tree.label t

                prefix =
                    value :: ancestors
            in
            Tree.tree
                ( prefix, value )
                (t |> Tree.children |> List.map (loop prefix))
    in
    loop [] <|
        Tree.map (\x -> ( [ x ], x )) root


sortTrees : (a -> a -> Order) -> Trees a -> Trees a
sortTrees ord ts =
    let
        sorting =
            List.sortWith (\x y -> ord (Tree.label x) (Tree.label y))
    in
    ts
        |> List.map (Tree.restructure identity (\k cs -> Tree.tree k (cs |> sorting)))
        |> sorting


sortTreesBranchesFirst : (a -> a -> Order) -> Trees a -> Trees a
sortTreesBranchesFirst ord ts =
    let
        sorting =
            List.sortWith (\x y -> ord (Tree.label x) (Tree.label y))
    in
    ts
        |> List.map
            (Tree.restructure identity
                (\k cs ->
                    let
                        ( leaves, branches ) =
                            cs |> List.partition (\t -> t |> Tree.children |> (==) [])
                    in
                    Tree.tree k <|
                        List.concat
                            [ branches |> sorting
                            , leaves |> sorting
                            ]
                )
            )
        |> sorting
