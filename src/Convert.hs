{- sv2v
 - Author: Zachary Snow <zach@zachjs.com>
 -
 - SystemVerilog to Verilog conversion
 -}

module Convert (convert) where

import Language.SystemVerilog.AST
import qualified Job (Exclude(..))

import qualified Convert.AlwaysKW
import qualified Convert.AsgnOp
import qualified Convert.Enum
import qualified Convert.FuncRet
import qualified Convert.Interface
import qualified Convert.Logic
import qualified Convert.PackedArray
import qualified Convert.Return
import qualified Convert.StarPort
import qualified Convert.Struct
import qualified Convert.Typedef
import qualified Convert.Unique

type Phase = AST -> AST

phases :: [Job.Exclude] -> [Phase]
phases excludes =
    extras ++
    [ Convert.AsgnOp.convert
    , Convert.FuncRet.convert
    , Convert.Enum.convert
    , Convert.PackedArray.convert
    , Convert.StarPort.convert
    , Convert.Struct.convert
    , Convert.Return.convert
    , Convert.Typedef.convert
    , Convert.Unique.convert
    ]
    where
        availableExcludes =
            [ (Job.Interface, Convert.Interface.convert)
            , (Job.Logic    , Convert.Logic.convert)
            , (Job.Always   , Convert.AlwaysKW.convert) ]
        extras = map selectExclude availableExcludes
        selectExclude :: (Job.Exclude, Phase) -> Phase
        selectExclude (exclude, phase) =
            if elem exclude excludes
                then id
                else phase

run :: [Job.Exclude] -> Phase
run excludes = foldr (.) id $ phases excludes

convert :: [Job.Exclude] -> Phase
convert excludes = convert'
    where
        convert' :: Phase
        convert' descriptions =
            if descriptions == descriptions'
                then descriptions
                else convert' descriptions'
            where descriptions' = run excludes descriptions
