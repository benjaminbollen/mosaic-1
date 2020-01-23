// Copyright 2020 OpenST Ltd.
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

'use strict';

const BN = require('bn.js');
const { AccountProvider } = require('../test_lib/utils.js');

const CoReputation = artifacts.require('CoreputationTest');

contract('Coreputation::getReputation', (accounts) => {
  let accountProvider;
  let coReputation;
  let validatorInfo;

  beforeEach(async () => {
    accountProvider = new AccountProvider(accounts);
    coReputation = await CoReputation.new();
    validatorInfo = {
      validator: accountProvider.get(),
      reputation: new BN('10'),
    };
    await coReputation.upsertValidator(
      validatorInfo.validator,
      validatorInfo.reputation,
    );
  });

  it('should return correct reputation for a known validator', async () => {
    const reputationValue = await coReputation.getReputation.call(validatorInfo.validator);
    assert.strictEqual(
      reputationValue.toString(10),
      validatorInfo.reputation.toString(10),
      `Expected reputation is ${validatorInfo.reputation.toString(10)} but found ${reputationValue.toString(10)}`,
    );
  });
});