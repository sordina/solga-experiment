{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Solga
import Solga.Swagger
import Data.Text
import GHC.Generics
import Network.Wai.Handler.Warp
import Data.Proxy
import Data.Aeson
import GHC.TypeLits
import Network.Wai
import Data.Swagger
import Network.HTTP.Types.Status
import qualified Data.ByteString.Char8 as B
import qualified Data.ByteString.Lazy.Char8 as L

main :: IO ()
main = run 8888 server

foo :: Either (Text, Context) Swagger
foo = genSwagger (Proxy :: Proxy MyAPI)

bar = either (toJSON . show) toJSON foo

data FOF
  = FOF
  { message :: Text
  }
  deriving Generic

instance ToJSON FOF
instance ToSchema FOF

data MyAPI = MyAPI
  { root          :: End               :> Method "GET"                :> JSON Text
  , doesItWork    :: "does-it-work"    /> Method "GET"                :> JSON Text
  , whatAboutThis :: "what-about-this" /> Method "GET"                :> JSON Text
  , fun           :: "fun"             /> Method "GET"                :> Capture Text :> JSON Text
  , apischema     :: "apischema"       /> Method "GET"                :> JSON Value
  , missing       :: Method "GET"      :> FixedStatus 404 "Not Found" :> JSON FOF
  } deriving (Generic)

instance Router MyAPI
instance RouterSwagger MyAPI
instance ToSchema Value where
  declareNamedSchema v = declareNamedSchema (Proxy :: Proxy Text)

myAPI :: MyAPI
myAPI = MyAPI
  { root          = brief "Home!"
  , doesItWork    = brief "It works!"
  , whatAboutThis = brief "It also works!"
  , fun           = brief (\x -> x <> "!!!")
  , missing       = brief $ FOF "lolz"
  , apischema     = brief bar
  }

server :: Network.Wai.Application
server = serve myAPI

-- Experimenting with creatng a new router to add arbitrary statuses to responses

newtype FixedStatus status message next = FixedStatus { unStatus :: next }

instance Abbreviated next => Abbreviated (FixedStatus n m next) where
  type Brief (FixedStatus n m next) = Brief next
  brief = FixedStatus . brief

instance (Router next, KnownNat s, KnownSymbol m) => Router (FixedStatus s m next) where
  tryRoute req = do
    nextRouter <- tryRoute req
    return $ \(FixedStatus next) cont -> do
      nextRouter next $ \response ->
        cont $ mapResponseStatus (const (mkStatus n m)) response

    where
    n = fromIntegral $ natVal    (Proxy :: Proxy s)
    m = B.pack       $ symbolVal (Proxy :: Proxy m)

instance RouterSwagger next => RouterSwagger (FixedStatus s m next) where
  genPaths _ c = genPaths (Proxy :: Proxy next) c

