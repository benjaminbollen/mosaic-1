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

    /** EIP-712 domain separator name for ProtoCore is the domain separator of Core. */
    string public constant DOMAIN_SEPARATOR_NAME = "Mosaic-Core";

    /** EIP-712 domain separator typehash for ProtoCore. */
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,bytes32 metachainId,address core)"
    );

    /** EIP-712 type hash for Kernel. */
    bytes32 public constant KERNEL_TYPEHASH = keccak256(
        "Kernel(uint256 height,bytes32 parent,address[] updatedValidators,uint256[] updatedReputation,uint256 gasTarget)"
    );

    /** EIP-712 type hash for a Transition */
    bytes32 public constant TRANSITION_TYPEHASH = keccak256(
        "Transition(bytes32 kernelHash,bytes32 originObservation,uint256 dynasty,uint256 accumulatedGas,bytes32 committeeLock)"
    );

    /** EIP-712 type hash for a Vote Message */
    bytes32 public constant VOTE_MESSAGE_TYPEHASH = keccak256(
        "VoteMessage(bytes32 transitionHash,bytes32 source,bytes32 target,uint256 sourceBlockHeight,uint256 targetBlockHeight)"
    );

    enum FinalisationStatus {
        undefined,
        proposed,
        justified,
        finalised,
        committed
    }


    /* Structs */

    /** Link structure */
    struct Link {
        /** Reference to justified parent vote message to read source checkpoint */
        bytes32 parentVoteMessageHash;

        // /** Kernel hash at source checkpoint */
        // bytes32 sourceKernelHash;

        /** Block hash of target checkpoint */
        bytes32 targetBlockHash;

        /** Block height of target checkpoint */
        uint256 targetBlockHeight;

        // /**
        //  * Block hash of latest finalised
        //  * origin observation at source checkpoint.
        //  */
        // bytes32 sourceOriginObservation;

        // /** Dynasty of source checkpoint */
        // uint256 sourceDynasty;

        // /** Accumulated gas at source checkpoint */
        // uint256 sourceAccumulatedGas;

        // /** CommitteeLock */
        // bytes32 sourceCommitteeLock;

        /** Transition hash of the source checkpoint */
        bytes32 sourceTransitionHash;

        /** Forward validator set vote count */
        uint256 forwardVoteCount;

        /** Rear validator set vote count */
        uint256 rearVoteCount;

        /** Finalisation status of target checkpoint*/
        FinalisationStatus targetFinalisation;
    }

    /* Storage */

    /** EIP-712 domain separator. */
    bytes32 internal domainSeparator;

    /** Chain Id of the meta-blockchain */
    bytes32 public metachainId;

    /** Mapping to store vote messages */
    mapping (bytes32 /* VoteMessage */ => Link) links;


    /* Special functions */

    constructor (
        bytes32 _metachainId,
        address _core,
        uint256 _epochLength,
        uint256 _rootHeight,
        uint256 _gasTarget,
        bytes32 _rootOriginObservation,
        uint256 _rootDynasty,
        uint256 _rootAccumulatedGas,
        bytes20 _rootSource,
        uint256 _rootSourceBlockHeight
    )
        ValidatorSet()
        public
    {
        domainSeparator = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPEHASH,
                DOMAIN_SEPARATOR_NAME,
                DOMAIN_SEPARATOR_VERSION,
                _metachainId,
                _core
            )
        );

        chainId = _chainId;

        // set root
    }


    /* External functions */

    function proposeLink(
        bytes32 _sourceVoteMessage, // ? rename
        bytes32 _targetBlockHash,
        uint256 _targetBlockHeight,
        bytes32 _sourceKernelHash,
        bytes32 _sourceOriginObservation,
        uint256 _sourceDynasty,
        uint256 _sourceAccumulatedGas,
        bytes32 _sourceCommitteeLock
    )
        external
    {
        require(_sourceVoteMessage != bytes32(0),
            "Source reference cannot be null.");
        require(_targetBlockHash != bytes32(0),
            "Target block hash cannot be null.");
        require(_targetBlockHeight % epochLength == 0,
            "Target block height must be a checkpoint.");

        (bytes32 sourceBlockHash,
            uint256 sourceBlockHeight) = assertJustified(_sourceVoteMessage);

        require(_targetBlockHeight > sourceBlockHeight,
            "Target block height must greater than source block height.");

        uint256 linkLength = _targetBlockHeight.sub(sourceBlockHeight);

        // inclusion principle for finalisation vote messages
        if (linkLength == epochLength) {
            require(block.number < _targetBlockHeight.add(epochLength),
                "Vote messages for finalisation must be included before child checkpoint.");
        }

        bytes32 sourceTransitionHash = hashTransition(
            _sourceKernelHash,
            _sourceOriginObservation,
            _sourceDynasty,
            _sourceAccumulatedGas,
            _sourceCommitteeLock
        );

        bytes32 voteMessageHash = hashVoteMessage(
            sourceTransitionHash,
            sourceBlockHash,
            _targetBlockHash,
            sourceBlockHeight,
            _targetBlockHeight
        );

        // TODO: store proposed link under voteMessageHash
        // links[voteMessageHash] = Link{}
        // store as registered

    }

    function registerVote(
        bytes32 _voteMessageHash,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    )
        external
    {
        // inclusion principle for finalisation vote messages
        // if (linkLength == epochLength) {
        //     require(block.number < _targetBlockHeight.add(epochLength),
        //         "Vote messages for finalisation must be included before child checkpoint.");
        // }
        // TODO: count forward and rear validator votes
        // inForwardValidatorSet(_validator) -> add vote
        // inRearValidatorSet(_validator) -> add vote

        // if quorum reached for both forward and rear validator set
        // then targetFinalisation is justified
        // if linkLength == epoch; then mark parentLink as finalised

        // call coconsensus.finaliseCheckpoint
    }



    /* Public view functions */

    function assertJustified(bytes32 _voteMessageHash)
        public
        view
        returns (
            bytes32 sourceBlockHash_,
            uint256 sourceBlockHeight_)
    {
        Link storage sourceLink = links[_voteMessage];

        require(sourceLink.finalisationStatus >= FinalisationStatus.justified,
            "Source checkpoint must be justified or higher.");

        sourceBlockHash_ = sourceLink.targetBlockHash;
        sourceBlockHeight_ = sourceLink.targetBlockHeight;
    }

    /* Internal functions */

    /**
     * @notice Takes the parameters of an transition object and returns the
     *         typed hash of it.
     *
     * @param _kernelHash Kernel hash
     * @param _originObservation Observation of the origin chain.
     * @param _dynasty The dynasty number where the meta-block closes
     *                 on the auxiliary chain.
     * @param _accumulatedGas The total consumed gas on auxiliary within this
     *                        meta-block.
     * @param _committeeLock The committee lock that hashes the transaction
     *                       root on the auxiliary chain.
     * @return hash_ The hash of this transition object.
     */
    function hashTransition(
        bytes32 _kernelHash,
        bytes32 _originObservation,
        uint256 _dynasty,
        uint256 _accumulatedGas,
        bytes32 _committeeLock
    )
        internal
        view
        returns (bytes32 hash_)
    {
        bytes32 typedTransitionHash = keccak256(
            abi.encode(
                TRANSITION_TYPEHASH,
                _kernelHash,
                _originObservation,
                _dynasty,
                _accumulatedGas,
                _committeeLock
            )
        );

        hash_ = keccak256(
            abi.encodePacked(
                byte(0x19),
                byte(0x01),
                domainSeparator,
                typedTransitionHash
            )
        );
    }

    /** @notice takes the VoteMessage parameters and returns
     *          the typed VoteMessage hash
     */
    function hashVoteMessage(
        bytes32 _transitionHash,
        bytes32 _source,
        bytes32 _target,
        uint256 _sourceBlockHeight,
        uint256 _targetBlockHeight
    )
        internal
        view
        returns (bytes32 hash_)
    {
        bytes32 typedVoteMessageHash = keccak256(
            abi.encode(
                VOTE_MESSAGE_TYPEHASH,
                _transitionHash,
                _source,
                _target,
                _sourceBlockHeight,
                _targetBlockHeight
            )
        );

        hash_ = keccak256(
            abi.encodePacked(
                byte(0x19),
                byte(0x01),
                domainSeparator,
                typedVoteMessageHash
            )
        );
    }
}
