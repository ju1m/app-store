module Main.View.Nix exposing (..)

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
import Main.View.Page.App exposing (..)
import Main.View.Pagination exposing (..)
import Tree exposing (Tree)
import Tuple exposing (first, second)


viewNixLiteralExpression : NixLiteralExpression -> Html Update
viewNixLiteralExpression lit =
    case lit.nixLiteralExpression_type of
        "literalExpression" ->
            code [] [ text lit.nixLiteralExpression_text ]

        _ ->
            text lit.nixLiteralExpression_text
