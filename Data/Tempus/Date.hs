module Data.Tempus.Date
  ( Date ()
  ) where

import Data.Ratio

import Data.Tempus.Class.HasEpoch
import Data.Tempus.Class.HasDate
import Data.Tempus.Class.HasUnixTime
import Data.Tempus.Internal

data Date
   = Date
     { dYear           :: Integer
     , dMonth          :: Integer
     , dDay            :: Integer
     } deriving (Eq, Ord)

instance HasEpoch Date where
  epoch
    = Date
      { dYear           = 1970
      , dMonth          = 1
      , dDay            = 1
      }

instance HasUnixTime Date where
  unixSeconds t
    = (days       * secsPerDay    % 1)
    - deltaUnixEpochCommonEpoch
    where
      days = yearMonthDayToDays (year t, month t, day t)
  fromUnixSeconds u
    = return
    $ Date
      { dYear           = y
      , dMonth          = m
      , dDay            = d
      }
    where
      s         = u + deltaUnixEpochCommonEpoch
      (y, m, d) = daysToYearMonthDay (truncate s `div` secsPerDay)

instance HasDate Date where
  year
    = dYear
  month
    = dMonth
  day
    = dDay
  setYear x t
    = if isValidDate (x, month t, day t)
      then return $ t { dYear  = x }
      else fail   $ "Dated.setYear "  ++ show x
  setMonth x t
    = if isValidDate (year t, x, day t)
      then return $ t { dMonth = x }
      else fail   $ "Dated.setMonth " ++ show x
  setDay x t
    = if isValidDate (year t, month t, x)
      then return $ t { dDay   = x }
      else fail   $ "Dated.setDay "   ++ show x
