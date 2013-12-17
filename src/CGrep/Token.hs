--
-- Copyright (c) 2013 Bonelli Nicola <bonelli@antifork.org>
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
--

{-# LANGUAGE FlexibleInstances #-} 

module CGrep.Token where

import qualified Data.ByteString.Char8 as C

import Data.Char


data TokenState = TokenSpace |
                  TokenAlpha |
                  TokenDigit |
                  TokenOther 
                    deriving (Eq, Enum, Show)


type Offset = Int


isCharNumber :: Char -> Bool
isCharNumber c = isHexDigit c || c == '.' || c == 'x' || c == 'X' 


isCompleteToken:: C.ByteString -> (Offset, String) -> Bool
isCompleteToken text (off, tok) = tok `elem` ts
    where ts = tokens $ C.take (2 + length tok) $ C.drop (off - 1) text       
                                 

-- tokens :: C.ByteString -> [(Offset, String)]
-- tokens = tokens' (TokenSpace, 0, "") 
--     where tokens' :: (TokenState, Offset, String) -> C.ByteString -> [(Offset, String)]
--           tokens' (TokenSpace, off, acc) (C.uncons -> Just (x,xs)) =  
--               case () of
--                 _  | isSpace x                ->  tokens' (TokenSpace, off + 1, acc) xs
--                    | isAlpha x || x == '_'    ->  tokens' (TokenAlpha, off + 1, x : acc) xs
--                    | isDigit x                ->  tokens' (TokenDigit, off + 1, x : acc) xs
--                    | otherwise                ->  tokens' (TokenOther, off + 1, x : acc) xs
          
--           tokens' (TokenAlpha, off, acc) (C.uncons -> Just (x,xs)) = 
--               case () of
--                 _  | isSpace x                ->  emit off acc : tokens' (TokenSpace, off + 1, "") xs
--                    | isAlphaNum x || x == '_' ->  tokens' (TokenAlpha, off + 1, x : acc) xs
--                    | otherwise                ->  emit off acc : tokens' (TokenOther, off + 1, [x]) xs
          
--           tokens' (TokenDigit, off, acc) (C.uncons -> Just (x,xs)) = 
--               case () of
--                 _  | isSpace x                ->  emit off acc : tokens' (TokenSpace, off + 1, "") xs
--                    | isCharNumber x           ->  tokens' (TokenDigit, off + 1, x : acc) xs
--                    | isAlpha x || x == '_'    ->  emit off acc : tokens' (TokenAlpha, off + 1, [x]) xs
--                    | otherwise                ->  emit off acc : tokens' (TokenOther, off + 1, [x]) xs
          
--           tokens' (TokenOther, off, acc) (C.uncons -> Just (x,xs)) = 
--               case () of
--                 _  | isSpace x                ->  emit off acc : tokens' (TokenSpace, off + 1, "") xs
--                    | isAlpha x || x == '_'    ->  emit off acc : tokens' (TokenAlpha, off + 1, [x]) xs
--                    | isDigit x                ->  if acc == "." then tokens' (TokenDigit, off + 1, x : ".") xs
--                                                                 else emit off acc : tokens' (TokenDigit, off + 1, [x]) xs
--                    | otherwise                ->  tokens' (TokenOther, off + 1, x : acc) xs
--           tokens' (_, off, acc) _ =  [emit off acc] 
--           emit off acc =  (off - length acc, reverse acc) 


data TokenAccum = TokenAccum TokenState String [String]
    deriving (Show,Eq)


tokens :: C.ByteString -> [String]
tokens xs = (\(TokenAccum _ lacc out) -> if null lacc then out else reverse lacc : out ) $ C.foldl' tokens' (TokenAccum TokenSpace "" []) xs
    where tokens' :: TokenAccum -> Char -> TokenAccum
          tokens' (TokenAccum TokenSpace acc out) x =  
              case () of
                _  | isSpace x                ->  TokenAccum TokenSpace acc out
                   | isAlpha x || x == '_'    ->  TokenAccum TokenAlpha (x : acc) out
                   | isDigit x                ->  TokenAccum TokenDigit (x : acc) out
                   | otherwise                ->  TokenAccum TokenOther (x : acc) out
       
          tokens' (TokenAccum TokenAlpha acc out) x = 
              case () of
                _  | isSpace x                ->  TokenAccum TokenSpace  "" (reverse acc : out)
                   | isAlphaNum x || x == '_' ->  TokenAccum TokenAlpha  (x : acc) out
                   | otherwise                ->  TokenAccum TokenOther  [x] (reverse acc : out) 
       
          tokens' (TokenAccum TokenDigit acc out) x = 
              case () of
                _  | isSpace x                ->  TokenAccum TokenSpace "" (reverse acc : out)
                   | isCharNumber x           ->  TokenAccum TokenDigit (x : acc) out
                   | isAlpha x || x == '_'    ->  TokenAccum TokenAlpha [x] (reverse acc : out) 
                   | otherwise                ->  TokenAccum TokenOther [x] (reverse acc : out) 
       
          tokens' (TokenAccum TokenOther acc out) x = 
              case () of
                _  | isSpace x                ->  TokenAccum TokenSpace ""  (reverse acc : out)   
                   | isAlpha x || x == '_'    ->  TokenAccum TokenAlpha [x] (reverse acc : out)
                   | isDigit x                ->  if acc == "." then TokenAccum TokenDigit (x : ".") out 
                                                                else TokenAccum TokenDigit [x] (reverse acc : out)
                   | otherwise                ->  TokenAccum TokenOther (x : acc) out 



