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

contract ValidatorSet {

    /* Usings */

    using SafeMath for uint256;


    /* Constants */

    /** Sentinel pointer for marking end of linked-list of validators */
    address public constant SENTINEL_VALIDATORS = address(0x1);

    /** Maximum future end height, set for all active validators */
    uint256 public constant MAX_FUTURE_END_HEIGHT = uint256(
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);


    /* Structs */

    /** Validator begin height assigned to this set
     * zero - not registered to this set, or started at height 0
     * bigger than zero - begin height for active validators (given endHeight >= metablock height)
     */
    mapping(address => uint256) public validatorBeginHeight;

    /** Validator end height assigned to this set
     * zero - not registered to this set
     * MAX_FUTURE_END_HEIGHT - for active validators (assert beginHeight <= metablock height)
     * less than MAX_FUTURE_END_HEIGHT - for logged out validators
     */
    mapping(address => uint256) public validatorEndHeight;

    /** Validator count in set */
    uint256 public countValidators;

    /** Validator minimum count required */
    uint256 public minimumValidatorCount;

    /** Join limit for number of validators */
    uint256 public joinLimit;

    /** Count of join messages */
    uint256 public countJoinMessages;

    /** Count of log out messages */
    uint256 public countLogOutMessages;

    /** Quorum of validator set */
    uint256 public quorum;

    /** Quorum of forward validator set */
    uint256 public forwardQuorum;

    /** Quorum of rear validator set */
    uint256 public rearQuorum;


    /* Special functions */

    constructor (
        uint256 _minValidators,
        uint256 _joinLimit
    )
        public
    {
        minimumValidatorCount = _minValidators;
        joinLimit = _joinLimit;
    }


    /* Internal functions */

    /**
     * insert validator in the validator set
     * sets begin height and end height of validator
     */
    function insertValidator(address _validator, uint256 _beginHeight)
        internal
    {
        require(_validator != address(0),
            "Validator must not be null address.");
        require(validatorEndHeight[_validator] == 0,
            "Validator must not already be part of this core.");
        require(validatorBeginHeight[_validator] == 0,
            "Validator must not have a non-zero begin height");
        validatorBeginHeight[_validator] = _beginHeight;
        validatorEndHeight[_validator] = MAX_FUTURE_END_HEIGHT;
        // update validator count upon new metablock opening
    }

    function removeValidator(address _validator, uint256 _endHeight)
        internal
    {
        require(_validator != address(0),
            "Validator must not be null address.");
        require(validatorBeginHeight[_validator] < _endHeight,
            "Validator must not have a non-zero begin height");
        require(validatorEndHeight[_validator] == MAX_FUTURE_END_HEIGHT,
            "Validator must be active.");
        validatorEndHeight[_validator] = _endHeight;
        // update validator count upon new metablock opening
    }


    /* Public view functions */

    /** */
    function inValidatorSet(address _validator, uint256 _height)
        public
        view
        returns (bool)
    {
        return validatorBeginHeight[_validator] <= _height &&
            validatorEndHeight[_validator] >= _height;
    }

    /** */
    function inForwardValidatorSet(address _validator, uint256 _height)
        public
        view
        returns (bool)
    {
        return validatorBeginHeight[_validator] <= _height &&
            validatorEndHeight[_validator] > _height;
    }

    /** */
    function inRearValidatorSet(address _validator, uint256 _height)
        public
        view
        returns (bool)
    {
        return validatorBeginHeight[_validator] < _height &&
            validatorEndHeight[_validator] >= _height;
    }
}