{-# LANGUAGE NamedFieldPuns #-}
module Env.Help
  ( helpDoc
  ) where

import           Data.List (intercalate)
import qualified Data.Map as Map
import           Data.Maybe (catMaybes)
import           Data.Monoid ((<>))

import           Env.Free
import           Env.Parse


helpDoc :: Mod Info a -> Parser a -> [Error] -> String
helpDoc (Mod f) p fs = intercalate "\n\n" . catMaybes $
  [ infoHeader
  , fmap (intercalate "\n" . splitEvery 50) infoDesc
  , Just "Available environment variables:"
  , Just (intercalate "\n" (helpParserDoc p))
  , fmap (intercalate "\n" . splitEvery 50) infoFooter
  ] ++ map Just (helpFailuresDoc fs)
 where
  Info { infoHeader, infoDesc, infoFooter } = f defaultInfo

helpParserDoc :: Parser a -> [String]
helpParserDoc = concat . Map.elems . foldAlt (\v -> Map.singleton (varfName v) (helpVarfDoc v)) . unParser

helpVarfDoc :: VarF a -> [String]
helpVarfDoc VarF { varfName, varfHelp, varfHelpDef } =
  case varfHelp of
    Nothing -> [indent 2 varfName]
    Just h
      | k > 15    -> indent 2 varfName : map (indent 25 . stripl) (splitEvery 30 t)
      | otherwise ->
          case zipWith indent (23 - k : repeat 25) (map stripl (splitEvery 30 t)) of
            (x : xs) -> (indent 2 varfName ++ x) : xs
            []       -> [indent 2 varfName]
     where k = length varfName
           t = maybe h (\s -> h ++ " (default: " ++ s ++")") varfHelpDef

helpFailuresDoc :: [Error] -> [String]
helpFailuresDoc [] = []
helpFailuresDoc fs = ["Parsing errors:", intercalate "\n" (map helpFailureDoc fs)]

helpFailureDoc :: Error -> String
helpFailureDoc (ParseError n e)  = "  " ++ n ++ " cannot be parsed: " ++ e
helpFailureDoc (ENoExistError n) = "  " ++ n ++ " is missing"

stripl :: String -> String
stripl (' ' : xs) = stripl xs
stripl xs = xs

splitEvery :: Int -> String -> [String]
splitEvery _ "" = []
splitEvery n xs = case splitAt n xs of ~(ys, zs) -> ys : splitEvery n zs

indent :: Int -> String -> String
indent n s = replicate n ' ' <> s