module Main.View.Page.Recipe exposing (..)

import Debug
import Html exposing (Html, a, button, code, div, h5, li, main_, nav, span, text, ul)
import Html.Attributes exposing (attribute, class, disabled, href, id, style, title)
import List.Extra as List
import Main.Config exposing (..)
import Main.Config.App exposing (..)
import Main.Helpers.AppUrl exposing (..)
import Main.Helpers.Html exposing (..)
import Main.Helpers.Markdown as Markdown
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
import Tree
import Tuple exposing (first, second)


viewPageRecipeOptionsLink : Html Update
viewPageRecipeOptionsLink =
    let
        onClickRoute =
            Route_RecipeOptions
                defaultRouteRecipeOptions
    in
    a
        [ href (onClickRoute |> Route.toString)
        , style "color" "inherit"
        , style "text-decoration" "none"
        , style "cursor" "pointer"
        , class "nav-link px-0 fw-bold"
        , title "View available recipe options"
        , attribute "aria-label" "View available recipe options"
        , onClick (Update_Route onClickRoute)
        ]
        [ text "Options" ]


viewPageRecipeOptions : Model -> PageRecipeOptions -> Html Update
viewPageRecipeOptions model pageRecipeOptions =
    let
        route =
            pageRecipeOptions.pageRecipeOptions_route

        onClickRoute path =
            Route_RecipeOptions
                { route
                    | routeRecipeOptions_focus = Just <| RouteRecipeOptionsFocus_Option path
                    , routeRecipeOptions_unfolds =
                        if route.routeRecipeOptions_unfolds |> Set.member path then
                            route.routeRecipeOptions_unfolds
                                |> Set.toList
                                |> List.filter (List.isPrefixOf path >> not)
                                |> Set.fromList

                        else
                            route.routeRecipeOptions_unfolds |> Set.insert path
                }

        optionPath node =
            node.recipeOptionNode_ancestors |> List.reverseMap first

        viewOptionPath : List NixName -> Int -> Int -> Html Update
        viewOptionPath path nodeBranches shownBranches =
            a
                [ href (onClickRoute path |> Route.toString)
                , onClick (Update_Route (onClickRoute path))
                , id (path |> joinNixNames)
                , style "color" "inherit"
                , class <|
                    if nodeBranches >= 1 then
                        "text-primary"

                    else
                        ""
                ]
                [ span
                    [ class "fw-bold"
                    , class "text-secondary"
                    , style "white-space" "pre"
                    ]
                    [ text <|
                        if 0 < nodeBranches - shownBranches then
                            "▶ "

                        else if Set.member path pageRecipeOptions.pageRecipeOptions_route.routeRecipeOptions_unfolds then
                            "▼ "

                        else
                            "  "

                    {-
                       case route.routeRecipeOptions_focus of
                           Just (Route.RouteRecipeOptionsFocus_Option focusPath) ->
                               if focusPath == path then
                                   "→ "

                               else
                                   "  "

                           _ ->
                               "  "
                    -}
                    ]
                , text <|
                    if path == [] then
                        "<recipe>"

                    else
                        path |> joinNixNames
                ]

        viewOption : ( RecipeOptionNode, Int ) -> Int -> Html Update
        viewOption ( node, nodeBranches ) shownBranches =
            let
                path =
                    optionPath node
            in
            div
                [ style "font-family" "monospace"
                ]
            <|
                List.concat
                    [ [ span [] <|
                            List.concat
                                [ [ viewOptionPath path nodeBranches shownBranches ]
                                , if nodeBranches - shownBranches <= 0 || Set.member path route.routeRecipeOptions_unfolds then
                                    []

                                  else
                                    [ text <|
                                        String.concat
                                            [ " (+"
                                            , nodeBranches - shownBranches |> String.fromInt
                                            , ")"
                                            ]
                                    ]
                                , node.recipeOptionNode_values
                                    |> List.concatMap
                                        (\option ->
                                            if option.nixModuleOption_type == "submodule" then
                                                []

                                            else
                                                [ span []
                                                    [ span
                                                        [ class "fw-bold"
                                                        , class "text-warning"
                                                        ]
                                                        [ text " :: " ]
                                                    , span
                                                        [ class "text-success"
                                                        ]
                                                        [ text option.nixModuleOption_type
                                                        ]
                                                    ]
                                                ]
                                        )
                                ]
                      ]

                    -- , values
                    --     |> List.concatMap
                    --         (\option ->
                    --             [ div []
                    --                 (option.nixModuleOption_description
                    --                     |> Markdown.render
                    --                 )
                    --             ]
                    --         )
                    ]

        viewOptions : ( RecipeOptionNode, Int ) -> List ( Int, Html Update ) -> ( Int, Html Update )
        viewOptions ( node, nodeBranches ) children =
            let
                path =
                    node.recipeOptionNode_ancestors
                        |> List.reverseMap first

                dropLast =
                    List.reverse >> List.tail >> Maybe.withDefault [] >> List.reverse

                parentPath =
                    path |> dropLast

                shown =
                    Set.member path unfoldAncestors
                        || Set.member parentPath pageRecipeOptions.pageRecipeOptions_unfolds
            in
            ( if shown then
                1

              else
                0
            , div
                [ style "margin-bottom"
                    (if children == [] then
                        "0"

                     else
                        "1rem"
                    )
                ]
              <|
                List.concat
                    [ if shown then
                        [ viewOption ( node, nodeBranches )
                            (children |> List.foldl (\( shownCount, _ ) acc -> acc + shownCount) 0)
                        ]

                      else
                        []
                    , children |> List.map second
                    ]
            )

        unfoldAncestors =
            pageRecipeOptions.pageRecipeOptions_unfolds
                |> Set.toList
                |> List.concatMap List.inits
                |> Set.fromList
    in
    pageRecipeOptions.pageRecipeOptions_trees
        |> List.map Tree.countNodeBranches
        |> Tree.sortTreesBranchesFirst
            (\( x, xBranches ) ( y, yBranches ) ->
                compare x.recipeOptionNode_name y.recipeOptionNode_name
            )
        -- |> Tree.pruneTrees
        --     (\( node, nodeBranches ) ->
        --         let
        --             path =
        --                 node.recipeOptionNode_ancestors
        --                     |> List.reverseMap first
        --         in
        --         Set.member path pageRecipeOptions.pageRecipeOptions_unfolds
        --             || Set.member path ancestors
        --     )
        |> Tree.restructureTrees identity viewOptions
        |> List.map second
        |> div []
