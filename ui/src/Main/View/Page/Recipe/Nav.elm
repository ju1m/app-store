module Main.View.Page.Recipe.Nav exposing (..)

import Html exposing (Html, a, div, nav, span, text)
import Html.Attributes exposing (class, href, style)
import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.List as List
import Main.Helpers.Nix exposing (..)
import Main.Helpers.Tree as Tree
import Main.Icons exposing (..)
import Main.Model exposing (..)
import Main.Model.Page exposing (..)
import Main.Model.Preferences exposing (..)
import Main.Route as Route exposing (..)
import Main.Update exposing (..)
import Main.View.Page.App exposing (..)
import Main.View.Pagination exposing (..)
import Set
import Tree exposing (Tree)
import Tuple exposing (first, second)


type alias InhNav =
    { inhNav_pathReversed : NixPath
    , inhNav_unfolded : Bool
    , inhNav_children : List (Tree NodeNixOption)
    }


navPath : InhNav -> Tree NodeNixOption -> NixPath
navPath inh tree =
    let
        name =
            tree |> Tree.label |> first
    in
    (name :: inh.inhNav_pathReversed) |> List.reverse


type alias NodeNav =
    { nodeNav_foldable : Bool
    , nodeNav_unfolded : Bool
    , nodeNav_showable : Bool
    , nodeNav_shown : Bool
    }


viewPageRecipeOptionsNav : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptionsNav _ page =
    let
        route =
            page.pageRecipeOptions_route

        onNodeToggleRoute path =
            Route_RecipeOptions
                { route
                    | routeRecipeOptions_unfolds =
                        if route.routeRecipeOptions_unfolds |> Set.member path then
                            route.routeRecipeOptions_unfolds
                                |> Set.filter (List.isPrefixOf path >> not)
                                |> Set.insert (path |> List.dropLast |> Maybe.withDefault [])

                        else
                            route.routeRecipeOptions_unfolds |> Set.insert path
                }

        onNodeNameRoute path =
            Route_RecipeOptions
                { route
                    | routeRecipeOptions_scope = path
                    , routeRecipeOptions_unfolds = route.routeRecipeOptions_unfolds |> Set.insert path
                }

        nodeNavToggle : InhNav -> Tree NodeNixOption -> NodeNav -> Html Update
        nodeNavToggle inh tree node =
            let
                path =
                    navPath inh tree
            in
            a
                [ href (onNodeToggleRoute path |> Route.toString)
                , onClick (Update_Route (onNodeToggleRoute path))
                , style "color" "inherit"
                , class "text-primary"
                ]
                [ span
                    [ class "fw-bold"
                    , class "text-secondary"
                    , style "white-space" "pre"
                    ]
                    [ text <|
                        if node.nodeNav_foldable then
                            if node.nodeNav_unfolded then
                                "⌄ "

                            else
                                "› "

                        else
                            "  "
                    ]
                ]

        nodeNavName : InhNav -> Tree NodeNixOption -> NodeNav -> Html Update
        nodeNavName inh tree node =
            let
                name =
                    tree |> Tree.label |> first

                path =
                    navPath inh tree
            in
            span []
                [ nodeNavToggle inh tree node
                , a
                    [ href (onNodeNameRoute path |> Route.toString)
                    , onClick (Update_Route (onNodeNameRoute path))
                    , class "text-primary"
                    , style "text-decoration" <|
                        if path == page.pageRecipeOptions_route.routeRecipeOptions_scope then
                            "underline"

                        else
                            "none"
                    ]
                    [ text <|
                        if name == "" then
                            "<recipe>"

                        else
                            name
                    ]
                ]

        viewNode : InhNav -> Tree NodeNixOption -> NodeNav -> Html Update
        viewNode inh tree node =
            div
                [ style "font-family" "monospace"
                ]
            <|
                [ span [ style "white-space" "pre" ] <|
                    [ nodeNavName inh tree node
                    , text <|
                        String.concat
                            [ " ("
                            , if node.nodeNav_showable then
                                "showable,"

                              else
                                ""
                            , if node.nodeNav_foldable then
                                "foldable,"

                              else
                                ""
                            , if node.nodeNav_unfolded then
                                "unfolded,"

                              else
                                ""
                            , if node.nodeNav_shown then
                                "shown,"

                              else
                                ""
                            , "children="
                            , tree |> Tree.children |> List.length |> String.fromInt
                            , ")"
                            ]
                    ]
                ]

        unfoldedAncestorsOrSelf =
            page.pageRecipeOptions_unfolds
                |> Set.toList
                |> List.concatMap List.inits
                |> Set.fromList

        viewNodes : InhNav -> Tree NodeNixOption -> Html Update
        viewNodes inh tree =
            let
                name =
                    nodeNixOption |> first

                childrenInh =
                    { inh
                        | inhNav_pathReversed =
                            (if name == "" then
                                []

                             else
                                [ name ]
                            )
                                ++ inh.inhNav_pathReversed
                        , inhNav_unfolded = unfolded
                        , inhNav_children = tree |> Tree.children
                    }

                synHtml =
                    tree |> Tree.children |> List.map (viewNodes childrenInh)

                nodeNixOption =
                    tree |> Tree.label

                path =
                    navPath inh tree

                nodeBranches =
                    synHtml |> List.length

                showable =
                    0 < nodeBranches

                shown =
                    showable
                        && (unfolded
                                || inh.inhNav_unfolded
                           )

                unfolded =
                    Set.member path unfoldedAncestorsOrSelf
                        || (inh.inhNav_unfolded && List.length inh.inhNav_children == 1)

                foldable =
                    tree
                        |> Tree.children
                        |> List.filter (\t -> 0 < (t |> Tree.children |> List.length))
                        |> List.length
                        |> (<) 0

                node =
                    { nodeNav_showable = showable
                    , nodeNav_foldable = foldable
                    , nodeNav_unfolded = unfolded
                    , nodeNav_shown = shown
                    }
            in
            div
                [ style "margin-left" "1rem"
                ]
            <|
                List.concat
                    [ if shown then
                        [ viewNode inh tree node
                        ]

                      else
                        []
                    , synHtml
                    ]

        initInh =
            { inhNav_pathReversed = []
            , inhNav_unfolded = True
            , inhNav_children = []
            }
    in
    page.pageRecipeOptions_trees
        |> List.map (viewNodes initInh)
        |> (\hs ->
                let
                    h =
                        viewNode
                            { inhNav_pathReversed = []
                            , inhNav_children = page.pageRecipeOptions_trees
                            , inhNav_unfolded = True
                            }
                            (Tree.tree ( "", [] ) page.pageRecipeOptions_trees)
                            { nodeNav_foldable = True
                            , nodeNav_unfolded = True
                            , nodeNav_showable = True
                            , nodeNav_shown = True
                            }
                in
                nav [ class "option-dirs" ]
                    [ div
                        [ style "margin-left" "1rem"
                        ]
                        (h
                            :: hs
                        )
                    ]
           )
