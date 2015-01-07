module Data.Tempus.Internal
  ( daysToYearMonthDay
  , yearMonthDayToDays
  ) where


import Control.Monad

yearMonthDayToDays :: MonadPlus m => (Int, Int, Int) -> m Int
yearMonthDayToDays (year,month,day)
  = do -- count of days of the "finalised" years
       let daysY = yearToDays (year - 1)
       -- count of days of the "finalised" months
       let daysM = case month - 1 of
                     1  -> 31
                     2  -> 31 + 28 + leapDay
                     3  -> 31 + 28 + 31 + leapDay
                     4  -> 31 + 28 + 31 + 30 + leapDay
                     5  -> 31 + 28 + 31 + 30 + 31 + leapDay
                     6  -> 31 + 28 + 31 + 30 + 31 + 30 + leapDay
                     7  -> 31 + 28 + 31 + 30 + 31 + 30 + 31 + leapDay
                     8  -> 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + leapDay
                     9  -> 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + leapDay
                     10 -> 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + leapDay
                     11 -> 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30 + leapDay
                     _  -> 0
       -- count of the "finalised" days
       let daysD = day - 1
       return (daysY + daysM + daysD)
  where

    yearToDays :: Int -> Int
    yearToDays y 
      | y    >= 0 = ((y + 1) * 365) + (y `div` 4) - (y `div` 100) + (y `div` 400) + 1
      | otherwise = 0

    leapDay :: Int
    leapDay
      | (year `mod` 4 == 0) && ((year `mod` 400 == 0) || (year `mod` 100 /= 0)) = 1
      | otherwise                                                               = 0

-- | Influenced by an ingenious solution from @caf found here:
--   https://stackoverflow.com/questions/1274964/how-to-decompose-unix-time-in-c
daysToYearMonthDay :: MonadPlus m => Int -> m (Int, Int, Int)
daysToYearMonthDay d
  | d < 0       = mzero -- 0000-01-01
  | d > 3652424 = mzero -- 9999-12-31
  | otherwise   =  do let days                      = d + 146068 -- 400 years and 2 months
                      yearMarFeb                   <- shrinkYearMarFeb days 399 10400
                      let remainingDays             = days - (yearToDays yearMarFeb)
                      let monthMarFeb               = selectMonthMarFeb remainingDays
                      let (yearJanDec, monthJanDec) = if monthMarFeb > 10
                                                        then (yearMarFeb + 1, monthMarFeb - 10)
                                                        else (yearMarFeb,     monthMarFeb + 2)
                      return (yearJanDec - 400, monthJanDec, remainingDays - (367 * monthMarFeb `div` 12))
  where

    shrinkYearMarFeb :: MonadPlus m => Int -> Int -> Int -> m Int
    shrinkYearMarFeb days lower upper
      -- we found the year satifying the condition
      | lower == upper                      = return lower
      -- just a fail-safe recursion breaker
      | lower > upper                       = mzero
      -- the tested year has more or equally many days than what we are looking for
      -- induction guarantee: unless 'lower == upper' (catched above) it always holds 'mid < upper'
      | days <= yearToDays (mid   + 1) + 30 = shrinkYearMarFeb days lower mid
      -- the tested year has less days than what we are looking for
      -- induction guarantee: it always holds 'mid + 1 > lower'
      | days >  yearToDays (mid   + 1) + 30 = shrinkYearMarFeb days (mid + 1) upper
      -- should not happen
      | otherwise                           = mzero
      where
        mid = (lower + upper) `div` 2

    selectMonthMarFeb :: Int -> Int
    selectMonthMarFeb days
          | days <= 367 *  2 `div` 12 = 1
          | days <= 367 *  3 `div` 12 = 2
          | days <= 367 *  4 `div` 12 = 3
          | days <= 367 *  5 `div` 12 = 4
          | days <= 367 *  6 `div` 12 = 5
          | days <= 367 *  7 `div` 12 = 6
          | days <= 367 *  8 `div` 12 = 7
          | days <= 367 *  9 `div` 12 = 8
          | days <= 367 * 10 `div` 12 = 9
          | days <= 367 * 11 `div` 12 = 10
          | days <= 367               = 11
          | otherwise              = 12

    yearToDays :: Int -> Int
    yearToDays year
      = (year * 365) + (year `div` 4) - (year `div` 100) + (year `div` 400)