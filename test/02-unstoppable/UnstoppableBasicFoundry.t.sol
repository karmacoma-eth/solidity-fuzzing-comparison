// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../../src/02-unstoppable/UnstoppableLender.sol";
import "../../src/02-unstoppable/ReceiverUnstoppable.sol";
import "../../src/TestToken.sol";

import "forge-std/Test.sol";

// run from base project directory with:
// forge test --match-contract UnstoppableBasicFoundry
contract UnstoppableBasicFoundry is Test {

    // initial tokens in pool
    uint256 constant INIT_TOKENS_POOL     = 1000000e18;
    // initial tokens attacker
    uint256 constant INIT_TOKENS_ATTACKER = 100e18;

    // contracts required for test
    ERC20               token;
    UnstoppableLender   pool;
    ReceiverUnstoppable receiver;
    address             attacker = address(0x1337);

    function setUp() public virtual {
        // setup contracts to be tested
        token    = new TestToken(INIT_TOKENS_POOL + INIT_TOKENS_ATTACKER, 18);
        console2.log("TestToken is", address(token));

        pool     = new UnstoppableLender(address(token));
        console2.log("UnstoppableLender is", address(pool));

        receiver = new ReceiverUnstoppable(payable(address(pool)));
        console2.log("ReceiverUnstoppable is", address(receiver));

        // transfer deposit initial tokens into pool
        token.approve(address(pool), INIT_TOKENS_POOL);
        pool.depositTokens(INIT_TOKENS_POOL);

        // transfer remaining tokens to the attacker
        token.transfer(attacker, INIT_TOKENS_ATTACKER);

        // only one attacker
        targetSender(attacker);

        // basic test with no advanced guiding of the fuzzer
        // Foundry can occasionally break the second easier invariant
        // but never the first in basic unguided mode
    }

    // invariant #1 very generic, harder to break
    function invariant_receiver_can_take_flash_loan() public {
        receiver.executeFlashLoan(10);
        assert(true);
    }

    // invariant #2 more specific, should be easier to break
    function invariant_pool_bal_equal_token_pool_bal() public view {
        assert(pool.poolBalance() == token.balanceOf(address(pool)));
    }
}
