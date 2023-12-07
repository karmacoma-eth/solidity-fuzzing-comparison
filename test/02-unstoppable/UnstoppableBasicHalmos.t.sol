// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../../src/02-unstoppable/UnstoppableLender.sol";
import "../../src/02-unstoppable/ReceiverUnstoppable.sol";
import "../../src/TestToken.sol";
import {console2} from "forge-std/console2.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

import {UnstoppableBasicFoundry} from "./UnstoppableBasicFoundry.t.sol";

// run from base project directory with:
// halmos --contract UnstoppableBasicHalmos
contract UnstoppableBasicHalmos is UnstoppableBasicFoundry, SymTest {
    // invariant #1 very generic, harder to break
    function check_receiver_can_take_flash_loan(address target) public {
        doAnythingNow(attacker, target);

        try receiver.executeFlashLoan(10) {
            // ignore successful calls
        } catch {
            // look for any revert
            assert(false);
        }
    }

    // invariant #2 more specific, should be easier to break
    function check_pool_bal_eqtoken_pool_bal(address target) public {
        doAnythingNow(attacker, target);
        assertEq(pool.poolBalance(), token.balanceOf(address(pool)));
    }

    function doAnythingNow(address from, address to) internal {
        doAnythingNow(from, to, svm.createBytes(120, "targetCallData"));
    }

    function doAnythingNow(address from, address to, bytes memory data) internal {
        // give halmos a hint for valid targets
        if (to == address(pool)
            || to == address(receiver)
            || to == address(token))
        {
            vm.prank(from);
            (bool succ, ) = to.call(data); succ;  // silence unused var warning
        }
    }

    function test_validate() public {
        bytes memory data = hex"dd49757e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
        address target = address(token);

        doAnythingNow(attacker, target, data);
        receiver.executeFlashLoan(10);
    }
}

contract NonReentrant is ReentrancyGuard {
    function setUp() public {
        // nothing to do
    }

    function reverts() external nonReentrant {
        require(false, "I revert, that's what I do");
    }

    function doesNotRevert() external nonReentrant {
        // nothing to do
    }
}

contract NonReentrantTest is SymTest {
    NonReentrant c;

    function setUp() public {
        c = new NonReentrant();
    }

    function test_reentrancy(bool a) public {
        if (!a) {
            c.reverts();
        } else {
            try c.doesNotRevert() {
                // ignore successful calls
            } catch {
                // it should never revert
                assert(false);
            }
        }
    }
}
