-- @+leo-ver=4-thin
-- @+node:gcross.20100107114651.1450:@thin Thermalize.hs
-- @@language Haskell

module VPI.Thermalize where

-- @<< Import needed modules >>
-- @+node:gcross.20100107114651.1452:<< Import needed modules >>
import Control.Applicative
import Control.Monad

import Data.Function

import System.Random

import VPI.Path
import VPI.Physics
import VPI.Spliceable

-- @-node:gcross.20100107114651.1452:<< Import needed modules >>
-- @nl

-- @+others
-- @+node:gcross.20100111122429.2010:Functions
-- @+node:gcross.20100107114651.1451:decideWhetherToAcceptChange
decideWhetherToAcceptChange :: Double -> Double -> IO Bool
decideWhetherToAcceptChange old_weight new_weight = fmap (< exp (new_weight-old_weight)) randomIO
-- @-node:gcross.20100107114651.1451:decideWhetherToAcceptChange
-- @+node:gcross.20100111122429.2008:thermalize
thermalize ::
    (Path -> IO (Int,Path)) ->
    (Path -> Potential) ->
    (Int -> Configuration -> Double) ->
    (PathSlice -> Double) ->
    Configuration ->
    IO Configuration
thermalize
    generateMove
    computePotential
    computeGreensFunction
    computeTrialWeight
    old_configuration@(Configuration old_path _)
   = do (start_slice,proposed_path) <- generateMove old_path
        let end_slice = start_slice + pathLength proposed_path
            proposed_configuration = Configuration proposed_path (computePotential proposed_path)

            computePathWeight = liftA2 (+) computeFirstSliceWeight computeLastSliceWeight
              where
                computeFirstSliceWeight =
                    if start_slice == 0
                        then computeTrialWeight . firstSlice
                        else const 0
                computeLastSliceWeight =
                    if end_slice == pathLength old_path
                        then computeTrialWeight . lastSlice
                        else const 0

            computePotentialWeight = computeGreensFunction start_slice

            computeConfigurationWeight =
                liftA2 (+)
                    (computePathWeight . configurationPath)
                    computePotentialWeight

        accept <- (decideWhetherToAcceptChange `on` computeConfigurationWeight)
                    (subrange start_slice end_slice old_configuration)
                    proposed_configuration
        return $
            if accept
                then update old_configuration start_slice proposed_configuration
                else old_configuration

-- @-node:gcross.20100111122429.2008:thermalize
-- @+node:gcross.20100111122429.2055:thermalizeRepeatedly
thermalizeRepeatedly ::
    (Path -> IO (Int,Path)) ->
    (Path -> Potential) ->
    (Int -> Configuration -> Double) ->
    (PathSlice -> Double) ->
    Int ->
    Configuration ->
    IO Configuration

thermalizeRepeatedly
    generateMove
    computePotential
    computeGreensFunction
    computeTrialWeight
    = go
  where
    go 0 = return
    go n = 
        thermalize
            generateMove
            computePotential
            computeGreensFunction
            computeTrialWeight
        >=>
        go (n-1) 
-- @-node:gcross.20100111122429.2055:thermalizeRepeatedly
-- @-node:gcross.20100111122429.2010:Functions
-- @-others
-- @-node:gcross.20100107114651.1450:@thin Thermalize.hs
-- @-leo
