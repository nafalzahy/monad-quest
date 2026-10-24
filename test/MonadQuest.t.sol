// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MonadQuest} from "../src/MonadQuest.sol";

contract MonadQuestTest is Test {
    MonadQuest q;
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        q = new MonadQuest();
    }

    function _clicks(address p, uint256 n) internal {
        vm.startPrank(p);
        for (uint256 i = 0; i < n; i++) q.click();
        vm.stopPrank();
    }

    function test_LevelUpMintsBadge() public {
        _clicks(alice, 2);
        assertEq(q.balanceOf(alice), 0);
        _clicks(alice, 1);
        assertEq(q.balanceOf(alice), 1);
        assertEq(q.ownerOf(q.badgeOf(alice, 2)), alice);
    }

    function test_FullRunGivesFourBadges() public {
        _clicks(alice, 35);
        assertEq(q.balanceOf(alice), 4);
        assertGt(bytes(q.tokenURI(q.badgeOf(alice, 5))).length, 0);
    }

    function test_Leaderboard() public {
        _clicks(alice, 4);
        _clicks(bob, 6);
        (address[5] memory a, uint256[5] memory s) = q.getLeaderboard();
        assertEq(a[0], bob);
        assertEq(s[1], 4);
    }
}