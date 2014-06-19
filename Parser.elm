module Parser where

{-| A simple parser combinator library.
#Running the parser
@docs parse, parseString

#Core functions
@docs (<*>), (<$>), (<|>), (<*), (*>), (<$)

#Combinators
@docs succeed, satisfy, empty, symbol, token, choice, option, many, some, seperatedBy, end
-}

import String
import Either (..)

type Parser a b = [a] -> [(b, [a])]

{-| Parse a list using a parser -}
parse : Parser a b -> [a] -> Either String b
parse p xs =
  case p xs of
    ((e, _)::_) -> Right e
    _           -> Left "Parse Error"

{-| Parse a `String` using a Char parser  -}
parseString : Parser Char b -> String -> Either String b
parseString p = parse p . String.toList

{-| Parser that always succeeds -}
succeed : b -> Parser a b
succeed b xs = [(b,xs)]

{-| Parser that satisfies a given predicate -}
satisfy : (a -> Bool) -> Parser a a
satisfy p xs = 
  case xs of
    [] -> []
    (x::xs') -> if p x then [(x, xs')] else []

{-| Parser that always fails -}
empty : Parser s a
empty = always []

{-| Parses a symbol -}
symbol : comparable -> Parser comparable comparable
symbol x = satisfy (\r -> r == x)

{-| Parses a token of symbols -}
token : [comparable] -> Parser comparable [comparable]
token xs     =
    case xs of
        []      -> succeed []
        (x::xs) -> (::) <$> symbol x <*> token xs

{-| Combine a list of parsers -}
choice : [Parser s a] -> Parser s a
choice = foldr (<|>) empty

{-| Parses an optional element -}
option : Parser s a -> a -> Parser s a
option p x = p <|> succeed x

{-| Parses zero or more occurences of a parser -}
many : Parser s a -> Parser s [a]
many p xs = --(::) <$> p <*> many p <|> succeed [] (lazy version)
    case p xs of
        [] -> succeed [] xs
        _ -> ((::) <$> p <*> many p) xs

{-| Parses one or more occurences of a parser -}
some : Parser s a -> Parser s [a]
some p = (::) <$> p <*> many p

{-| Choice between two parsers -}
(<|>) : Parser a b -> Parser a b -> Parser a b
(<|>) p q xs = p xs ++ q xs

{-| Map a function over the result of the parser -}
(<$>) : (b -> c) -> Parser a b -> Parser a c
(<$>) f p = map (\(r,ys) -> (f r, ys)) . p

{-| Sequence two parsers 

    data Date = Date Int Int Int
    Date <$> year <*> month <*> day

-}
(<*>) : Parser a (b -> c) -> Parser a b -> Parser a c
(<*>) p q xs = 
    let a = p xs
        b = concat <| map (\(_,ys) -> q ys) a
    in zipWith (\(f, ys) (b, zs) -> (f b, zs)) a b

{-| Variant of `<$>` that ignores the result of the parser -}
(<$) : b -> Parser s a -> Parser s b
f <$ p = always f <$> p

{-| Variant of `<*>` that ignores the result of the parser at the right -}
(<*) : Parser s a -> Parser s b -> Parser s a
p <* q = always <$> p <*> q

{-| Variant of `<*>` that ignores the result of the parser at the right -}
(*>) : Parser s a -> Parser s b -> Parser s b
p *> q = flip always <$> p <*> q

{-| Parses a sequence of the first parser, seperated by the second parser -} 
seperatedBy : Parser s a -> Parser s b -> Parser s [a]
seperatedBy p s = (::) <$> p <*> many (s *> p)

{-| Succeeds when input is empty -}
end : Parser s ()
end xs = case xs of
    [] -> succeed () xs
    _  -> []

infixl 4 <*>
infixr 3 <|>
infixl 4 <$>
infixl 4 <$
infixl 4 <*
infixl 4 *>
