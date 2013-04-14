module CGrep.CppTokenizer (cgrepCppTokenizer) where

import Data.ByteString.Lazy.Search as LC

import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy.Char8 as LC

import CGrep.Function
import CGrep.Output
import CGrep.Options 

import qualified CGrep.Cpp.Filter as Cpp
import qualified CGrep.Cpp.Token  as Cpp

cgrepCppTokenizer :: CgrepFunction
cgrepCppTokenizer opt ps f = do
    source <- LC.readFile f
    let filtered =  Cpp.filter Cpp.ContextFilter { Cpp.getCode = code opt, Cpp.getComment = comment opt, Cpp.getLiteral = string opt } source
    let content = zip [1..] $ LC.lines filtered
    let xxx = Cpp.tokens filtered
    print xxx
    return $ concat $ map (if (word opt) then simpleWordGrep opt f lps
                                         else simpleLineGrep opt f ps) content
        where lps = map LC.fromChunks (map (:[]) ps)



simpleLineGrep :: Options -> FilePath -> [C.ByteString] -> (Int, LC.ByteString) -> [Output]
simpleLineGrep opt f ps (n, l) = 
   if ((null tks) `xor` (invert_match opt)) 
     then []
     else [LazyOutput f n l (map C.unpack tks)]
   where tks  = filter (\p -> not . null $ LC.indices p l) ps   



simpleWordGrep :: Options -> FilePath -> [LC.ByteString] -> (Int, LC.ByteString) -> [Output]
simpleWordGrep opt f ps (n, l) = 
   if ((null tks) `xor` (invert_match opt)) 
     then []
     else [LazyOutput f n l (map LC.unpack tks)]
   where tks  = filter (`elem` (LC.words l)) ps   


