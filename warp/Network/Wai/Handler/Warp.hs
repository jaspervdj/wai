{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -fno-warn-deprecations #-}

---------------------------------------------------------
--
-- Module        : Network.Wai.Handler.Warp
-- Copyright     : Michael Snoyman
-- License       : BSD3
--
-- Maintainer    : Michael Snoyman <michael@snoyman.com>
-- Stability     : Stable
-- Portability   : portable
--
-- A fast, light-weight HTTP server handler for WAI.
--
---------------------------------------------------------

-- | A fast, light-weight HTTP server handler for WAI.
module Network.Wai.Handler.Warp (
    -- * Run a Warp server
    run
  , runSettings
  , runSettingsSocket
  , runSettingsConnection
  , runSettingsConnectionMaker
  , runSettingsConnectionMakerSecure
    -- * Settings
  , Settings
  , defaultSettings
    -- ** Setters
  , setPort
  , setHost
  , setOnException
  , setOnExceptionResponse
  , setOnOpen
  , setOnClose
  , setTimeout
  , setManager
  , setFdCacheDuration
  , setBeforeMainLoop
  , setNoParsePath
  , setInstallShutdownHandler
    -- ** Getters
  , getPort
  , getHost
    -- ** Accessors
    -- | Note: these accessors are deprecated, please use the @set@ versions instead.
  , settingsPort
  , settingsHost
  , settingsOnException
  , settingsOnExceptionResponse
  , settingsOnOpen
  , settingsOnClose
  , settingsTimeout
  , settingsManager
  , settingsFdCacheDuration
  , settingsBeforeMainLoop
  , settingsNoParsePath
    -- ** Debugging
  , exceptionResponseForDebug
  , defaultShouldDisplayException
    -- * Data types
  , HostPreference (..)
  , Port
  , InvalidRequest (..)
  , ConnSendFileOverride (..)
    -- * Connection
  , Connection (..)
  , socketConnection
    -- * Internal
    -- ** Version
  , warpVersion
    -- ** Data types
  , InternalInfo (..)
  , HeaderValue
  , IndexedHeader
  , requestMaxIndex
    -- ** Time out manager
  , module Network.Wai.Handler.Warp.Timeout
    -- ** File descriptor cache
  , module Network.Wai.Handler.Warp.FdCache
    -- ** Date
  , module Network.Wai.Handler.Warp.Date
    -- ** Request and response
  , recvRequest
  , sendResponse
  ) where

import Network.Wai.Handler.Warp.Date
import Network.Wai.Handler.Warp.FdCache
import Network.Wai.Handler.Warp.Header
import Network.Wai.Handler.Warp.Request
import Network.Wai.Handler.Warp.Response
import Network.Wai.Handler.Warp.Run
import Network.Wai.Handler.Warp.Settings
import Network.Wai.Handler.Warp.Timeout
import Network.Wai.Handler.Warp.Types
import Control.Exception (SomeException)
import Network.Wai (Request, Response)
import Network.Socket (SockAddr)
import Data.Streaming.Network (HostPreference)

-- | Port to listen on. Default value: 3000
--
-- Since 2.1.0
setPort :: Int -> Settings -> Settings
setPort x y = y { settingsPort = x }

-- | Interface to bind to. Default value: HostIPv4
--
-- Since 2.1.0
setHost :: HostPreference -> Settings -> Settings
setHost x y = y { settingsHost = x }

-- | What to do with exceptions thrown by either the application or server.
-- Default: ignore server-generated exceptions (see 'InvalidRequest') and print
-- application-generated applications to stderr.
--
-- Since 2.1.0
setOnException :: (Maybe Request -> SomeException -> IO ()) -> Settings -> Settings
setOnException x y = y { settingsOnException = x }

-- | A function to create a `Response` when an exception occurs.
--
-- Default: 500, text/plain, \"Something went wrong\"
--
-- Since 2.1.0
setOnExceptionResponse :: (SomeException -> Response) -> Settings -> Settings
setOnExceptionResponse x y = y { settingsOnExceptionResponse = x }

-- | What to do when a connection is opened. When 'False' is returned, the
-- connection is closed immediately. Otherwise, the connection is going on.
-- Default: always returns 'True'.
--
-- Since 2.1.0
setOnOpen :: (SockAddr -> IO Bool) -> Settings -> Settings
setOnOpen x y = y { settingsOnOpen = x }

-- | What to do when a connection is closed. Default: do nothing.
--
-- Since 2.1.0
setOnClose :: (SockAddr -> IO ()) -> Settings -> Settings
setOnClose x y = y { settingsOnClose = x }

-- | Timeout value in seconds. Default value: 30
--
-- Since 2.1.0
setTimeout :: Int -> Settings -> Settings
setTimeout x y = y { settingsTimeout = x }

-- | Use an existing timeout manager instead of spawning a new one. If used,
-- 'settingsTimeout' is ignored.
--
-- Since 2.1.0
setManager :: Manager -> Settings -> Settings
setManager x y = y { settingsManager = Just x }

-- | Cache duration time of file descriptors in seconds. 0 means that the cache mechanism is not used. Default value: 10
setFdCacheDuration :: Int -> Settings -> Settings
setFdCacheDuration x y = y { settingsFdCacheDuration = x }

-- | Code to run after the listening socket is ready but before entering
-- the main event loop. Useful for signaling to tests that they can start
-- running, or to drop permissions after binding to a restricted port.
--
-- Default: do nothing.
--
-- Since 2.1.0
setBeforeMainLoop :: IO () -> Settings -> Settings
setBeforeMainLoop x y = y { settingsBeforeMainLoop = x }

-- | Perform no parsing on the rawPathInfo.
--
-- This is useful for writing HTTP proxies.
--
-- Default: False
--
-- Since 2.1.0
setNoParsePath :: Bool -> Settings -> Settings
setNoParsePath x y = y { settingsNoParsePath = x }

-- | Get the listening port.
--
-- Since 2.1.1
getPort :: Settings -> Int
getPort = settingsPort

-- | Get the interface to bind to.
--
-- Since 2.1.1
getHost :: Settings -> HostPreference
getHost = settingsHost

-- | A code to install shutdown handler.
--
-- For instance, this code should set up a UNIX signal
-- handler. The handler should call the first argument,
-- which close the listen socket, at shutdown.
--
-- Default: does not install any code.
--
-- Since 3.0.1
setInstallShutdownHandler :: (IO () -> IO ()) -> Settings -> Settings
setInstallShutdownHandler x y = y { settingsInstallShutdownHandler = x }
