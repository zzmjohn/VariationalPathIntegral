-- @+leo-ver=4-thin
-- @+node:gcross.20091216150502.2169:@thin test.hs
-- @@language Haskell

-- @<< Language extensions >>
-- @+node:gcross.20091216150502.2170:<< Language extensions >>
-- @-node:gcross.20091216150502.2170:<< Language extensions >>
-- @nl

-- @<< Import needed modules >>
-- @+node:gcross.20091216150502.2171:<< Import needed modules >>
import Control.Applicative.Infix
import Control.Applicative

import Data.NDArray
import qualified Data.NDArray.Listlike as N
import Data.Vec((:.)(..))


import Debug.Trace

import Test.HUnit
import Test.Framework
import Test.Framework.Providers.HUnit
import Test.Framework.Providers.QuickCheck2
import Test.QuickCheck

import System.IO.Unsafe

import VPI.Fortran.Path
import VPI.Path
-- @-node:gcross.20091216150502.2171:<< Import needed modules >>
-- @nl

-- @+others
-- @+node:gcross.20091226065853.2232:Classes
-- @+node:gcross.20091226065853.2234:AlmostEq
infix 4 ~=

class AlmostEq a where
    (~=) :: a -> a -> Bool

instance AlmostEq Double where
    x ~= y = abs (x-y) < 1e-7

instance (AlmostEq a) => AlmostEq [a] where
    x ~= y = all (uncurry (~=)) $ zip x y

-- @+at
--  instance (AlmostEq a, RealFloat a) => AlmostEq (Complex a) where
--      (a :+ b) ~= (c :+ d) = (a ~= c) && (b ~= d)
-- @-at
-- @@c

x /~ y = not (x ~= y)
-- @-node:gcross.20091226065853.2234:AlmostEq
-- @-node:gcross.20091226065853.2232:Classes
-- @+node:gcross.20091225065853.1430:Functions
-- @+node:gcross.20091225065853.1431:echo
echo x = trace (show x) x
-- @-node:gcross.20091225065853.1431:echo
-- @+node:gcross.20091226065853.1311:echoWithHeading
echoWithHeading heading x = trace (heading ++ show x) x
-- @-node:gcross.20091226065853.1311:echoWithHeading
-- @+node:gcross.20091226065853.1465:verifyCorrectSeparations
verifyCorrectSeparations particle_positions particle_separations =
    and [   sqrt (sum [(particle_positions ! i3 i j1 k - particle_positions ! i3 i j2 k)**2
                      | k <- [0..number_of_dimensions-1]
                      ]
                 )
            ==
            particle_separations ! i3 i j1 j2
        | i <- [0..number_of_slices-1]
        , j1 <- [0..number_of_particles-1]
        , j2 <- [0..number_of_particles-1]
        ]
  where
    number_of_slices :. number_of_particles :. number_of_dimensions :. () = ndarrayShape particle_positions
-- @-node:gcross.20091226065853.1465:verifyCorrectSeparations
-- @-node:gcross.20091225065853.1430:Functions
-- @+node:gcross.20091216150502.2182:Generators
-- @+node:gcross.20091216150502.2183:UnderTenInt
newtype UnderTenInt = UTI Int deriving (Show,Eq)
instance Arbitrary UnderTenInt where
    arbitrary = choose (1,10) >>= return.UTI
-- @-node:gcross.20091216150502.2183:UnderTenInt
-- @+node:gcross.20091216150502.2186:PhysicalDimensionInt
newtype PhysicalDimensionInt = PDI Int deriving (Show,Eq)
instance Arbitrary PhysicalDimensionInt where
    arbitrary = choose (2,4) >>= return.PDI
-- @-node:gcross.20091216150502.2186:PhysicalDimensionInt
-- @-node:gcross.20091216150502.2182:Generators
-- @-others

main = defaultMain
    -- @    << Tests >>
    -- @+node:gcross.20091216150502.2172:<< Tests >>
    -- @+others
    -- @+node:gcross.20091226065853.1624:VPI.Fortran
    [testGroup "VMPS.Fortran"
        -- @    @+others
        -- @+node:gcross.20091226065853.1629:VMPS.Fortran.Path
        [testGroup "VMPS.Fortran.Path"
            -- @    @+others
            -- @+node:gcross.20091226065853.2237:compute_separations
            [testGroup "compute_separations"
                -- @    @+others
                -- @+node:gcross.20091226065853.1631:correct shape
                [testProperty "correct shape" $
                    \(UTI number_of_slices) (UTI number_of_particles) (UTI number_of_dimensions) ->
                        arbitraryNDArray (shape3 number_of_slices number_of_particles number_of_dimensions) (arbitrary :: Gen Double) >>=
                        \particle_positions ->
                            return $ ndarrayShape (compute_separations particle_positions) == shape3 number_of_slices number_of_particles number_of_particles
                -- @-node:gcross.20091226065853.1631:correct shape
                -- @+node:gcross.20091226065853.2236:correct values
                ,testProperty "correct values" $
                    \(UTI number_of_slices) (UTI number_of_particles) (UTI number_of_dimensions) ->
                        arbitraryNDArray (shape3 number_of_slices number_of_particles number_of_dimensions) (arbitrary :: Gen Double) >>=
                        \particle_positions ->
                            return $ verifyCorrectSeparations particle_positions (compute_separations particle_positions)
                -- @-node:gcross.20091226065853.2236:correct values
                -- @-others
                ]
            -- @-node:gcross.20091226065853.2237:compute_separations
            -- @-others
            ]
        -- @-node:gcross.20091226065853.1629:VMPS.Fortran.Path
        -- @-others
        ]
    -- @-node:gcross.20091226065853.1624:VPI.Fortran
    -- @+node:gcross.20091216150502.2173:VPI.Path
    ,testGroup "VMPS.Path"
        -- @    @+others
        -- @+node:gcross.20091216150502.2174:createInitialPath
        [testGroup "createInitialPath"
            -- @    @+others
            -- @+node:gcross.20091226065853.1313:correct shape
            [testProperty "correct shape" $
                \(UTI number_of_slices) (UTI number_of_particles) unprocessed_bounds -> (not.null) unprocessed_bounds ==>
                let bounds = [if bound_1 < bound_2 then (bound_1,bound_2) else (bound_2,bound_1) | (bound_1,bound_2) <- unprocessed_bounds]
                    number_of_dimensions = length bounds
                in unsafePerformIO $
                    createInitialPath
                        number_of_slices
                        number_of_particles
                        bounds
                    >>=
                    return
                    .
                    \Path
                    {   pathLength = path_number_of_slices
                    ,   pathNumberOfParticles = path_number_of_particles
                    ,   pathNumberOfDimensions = path_number_of_dimensions
                    ,   pathParticlePositions = particle_positions
                    ,   pathParticleSeparations = particle_separations
                    } ->
                        and [path_number_of_slices == number_of_slices
                            ,path_number_of_particles == number_of_particles
                            ,path_number_of_dimensions == number_of_dimensions
                            ,ndarrayShape particle_positions == number_of_slices :. number_of_particles :. number_of_dimensions :. ()
                            ,ndarrayShape particle_separations == number_of_slices :. number_of_particles :. number_of_particles :. ()
                            ]
            -- @-node:gcross.20091226065853.1313:correct shape
            -- @+node:gcross.20091226065853.1317:within specified range
            ,testProperty "within specified range" $
                \(UTI number_of_slices) (UTI number_of_particles) unprocessed_bounds -> (not.null) unprocessed_bounds ==>
                let bounds = [if bound_1 < bound_2 then (bound_1,bound_2) else (bound_2,bound_1) | (bound_1,bound_2) <- unprocessed_bounds]
                in unsafePerformIO $
                    createInitialPath
                        number_of_slices
                        number_of_particles
                        bounds
                    >>=
                    \Path { pathParticlePositions = particle_positions } ->
                        return
                        .
                        any (
                            \(index,(lower_bound,upper_bound)) ->
                                N.all ((>= lower_bound) <^(&&)^> (<= upper_bound) )
                                .
                                cut (All :. All :. Index index :. ())
                                $
                                particle_positions
                        )
                        $
                        zip [0..] bounds
            -- @-node:gcross.20091226065853.1317:within specified range
            -- @+node:gcross.20091226065853.1315:correct separations
            ,testProperty "correct separations" $
                \(UTI number_of_slices) (UTI number_of_particles) unprocessed_bounds -> (not.null) unprocessed_bounds ==>
                let bounds = [if bound_1 < bound_2 then (bound_1,bound_2) else (bound_2,bound_1) | (bound_1,bound_2) <- unprocessed_bounds]
                in unsafePerformIO $
                    createInitialPath
                        number_of_slices
                        number_of_particles
                        bounds
                    >>=
                    return
                    .
                    liftA2 verifyCorrectSeparations pathParticlePositions pathParticleSeparations
            -- @-node:gcross.20091226065853.1315:correct separations
            -- @-others
            ]
        -- @-node:gcross.20091216150502.2174:createInitialPath
        -- @-others
        ]
    -- @-node:gcross.20091216150502.2173:VPI.Path
    -- @-others
    -- @-node:gcross.20091216150502.2172:<< Tests >>
    -- @nl
    ]
-- @-node:gcross.20091216150502.2169:@thin test.hs
-- @-leo
