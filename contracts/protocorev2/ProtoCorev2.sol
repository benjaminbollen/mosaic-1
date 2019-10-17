pragma solidity >=0.5.0 <0.6.0;

// Copyright 2019 OpenST Ltd.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "../block/Block.sol";
import "../version/MosaicVersion.sol";
import "../validator-set/ValidatorSet.sol";

contract ProtoCorev2 is MosaicVersion, ValidatorSet {

    /* Usings */

    using SafeMath for uint256;


    /* Constants */


    /* Structs */

    /** Vote structure */
    struct VoteMessage {
        /** Reference to justified source checkpoint */
        bytes32 sourceVoteMessage;

        /** Block hash of target checkpoint */
        bytes32 targetBlockHash;

        /** Block height of target checkpoint */
        uint256 targetBlockHeight;

        /** Kernel hash at source checkpoint */
        bytes32 sourceKernelHash;

        /** Dynasty of source checkpoint */
        uint256 sourceDynasty;

        /**
         * Block hash of latest finalised
         * origin observation at source checkpoint.
         */
        bytes32 sourceOriginObservation;

        /** Accumulated gas at source checkpoint */
        uint256 sourceAccumulatedGas;

        /** CommitteeLock */
        bytes32 sourceCommitteeLock;

        /** Forward validator set vote count */
        uint256 forwardVoteCount;

        /** Rear validator set vote count */
        uint256 rearVoteCount;
    }

    /* Storage */

    /** Mapping to store vote messages */
    mapping (bytes32 /* VoteMessageHash */ => VoteMessage) voteMessages;
}