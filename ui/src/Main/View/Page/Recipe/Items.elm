module Main.View.Page.Recipe.Items exposing (..)

import Html exposing (Html, article, code, div, section, text)
import Html.Attributes exposing (class, id, style)
import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.List as List
import Main.Helpers.Markdown as Markdown
import Main.Helpers.Nix exposing (..)
import Main.Helpers.Tree as Tree
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route exposing (..)
import Main.Update exposing (..)
import Main.View.Nix exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Pagination exposing (..)
import Tree exposing (Tree)
import Tuple exposing (first, second)


type alias InhItem =
    { inhItem_pathReversed : NixPath
    }


itemPath : InhItem -> Tree NodeNixOptionFiltered -> NixPath
itemPath inh tree =
    let
        name =
            tree |> Tree.label |> nodeNixOptionFiltered_name
    in
    (name :: inh.inhItem_pathReversed) |> List.reverse


viewPageRecipeOptionsItems : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptionsItems _ page =
    let
        _ =
            page.pageRecipeOptions_route

        viewNode : InhItem -> Tree NodeNixOptionFiltered -> List (Html Update)
        viewNode inh tree =
            case tree |> Tree.label of
                NodeNixOptionFiltered_Out _ ->
                    []

                NodeNixOptionFiltered_In ( _, opts ) ->
                    let
                        path =
                            itemPath inh tree
                    in
                    [ section
                        [ id <| "option-" ++ joinNixPath path
                        , style
                            "margin-bottom"
                            "1rem"
                        ]
                        [ code [ class "fs-5" ] [ text (path |> joinNixPath) ]
                        , div
                            [ class "recipe-options-item"
                            , style "margin-left" "2rem"
                            , style "display" "grid"
                            , style "grid-template-columns" "10rem 1fr"
                            , style "gap" "0rem 1rem"
                            ]
                            (opts
                                |> List.concatMap
                                    (\opt ->
                                        List.concatMap
                                            (\kv ->
                                                case kv of
                                                    Nothing ->
                                                        []

                                                    Just ( k, v ) ->
                                                        [ div
                                                            [ class ("recipe-options-item-" ++ k) ]
                                                            [ text k ]
                                                        , v
                                                        ]
                                            )
                                            [ Just
                                                ( "Type"
                                                , code [] [ text opt.nixModuleOption_type ]
                                                )
                                            , opt.nixModuleOption_default
                                                |> Maybe.map
                                                    (\default ->
                                                        ( "Default"
                                                        , default |> viewNixLiteralExpression
                                                        )
                                                    )
                                            , Just
                                                ( "Description"
                                                , opt.nixModuleOption_description
                                                    |> Markdown.render
                                                )
                                            , opt.nixModuleOption_example
                                                |> Maybe.map
                                                    (\example ->
                                                        ( "Example"
                                                        , example |> viewNixLiteralExpression
                                                        )
                                                    )
                                            ]
                                    )
                            )
                        ]
                    ]

        viewNodes : InhItem -> Tree NodeNixOptionFiltered -> List (Html Update)
        viewNodes inh tree =
            let
                name =
                    tree |> Tree.label |> nodeNixOptionFiltered_name

                childrenInh =
                    { inh | inhItem_pathReversed = name :: inh.inhItem_pathReversed }

                ( nodeChildrenLeaves, nodeChildrenBranches ) =
                    tree |> Tree.children |> List.partition (\t -> t |> Tree.children |> List.isEmpty)

                synLeaves =
                    nodeChildrenLeaves |> List.map (viewNodes childrenInh)

                synBranches =
                    nodeChildrenBranches |> List.map (viewNodes childrenInh)
            in
            List.concat
                [ if (synLeaves |> List.isEmpty) && (synBranches |> List.isEmpty) then
                    viewNode inh tree

                  else
                    []
                , synLeaves |> List.concat
                , synBranches |> List.concat
                ]
    in
    page.pageRecipeOptions_scope
        |> List.concatMap (viewNodes { inhItem_pathReversed = [] })
        |> article []
