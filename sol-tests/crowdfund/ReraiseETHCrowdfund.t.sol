// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "forge-std/Test.sol";

import "../../contracts/crowdfund/ReraiseETHCrowdfund.sol";
import "../../contracts/globals/Globals.sol";
import "../../contracts/utils/Proxy.sol";
import "../../contracts/party/PartyFactory.sol";
import "../../contracts/tokens/ERC721Receiver.sol";

import "../TestUtils.sol";

contract ReraiseETHCrowdfundTest is Test, TestUtils, ERC721Receiver {
    event Transfer(address indexed owner, address indexed to, uint256 indexed tokenId);
    event Contributed(
        address indexed sender,
        address indexed contributor,
        uint256 amount,
        address delegate
    );
    event Refunded(address indexed contributor, uint256 amount);
    event Claimed(address indexed contributor, uint256 indexed tokenId, uint256 votingPower);

    Party party;
    ReraiseETHCrowdfund reraiseETHCrowdfundImpl;

    constructor() {
        Globals globals = new Globals(address(this));

        reraiseETHCrowdfundImpl = new ReraiseETHCrowdfund(globals);

        globals.setAddress(LibGlobals.GLOBAL_PARTY_IMPL, address(new Party(globals)));
        globals.setAddress(LibGlobals.GLOBAL_PARTY_FACTORY, address(new PartyFactory()));
        globals.setAddress(LibGlobals.GLOBAL_RENDERER_STORAGE, address(new MockRendererStorage()));

        Party.PartyInitData memory partyOpts;
        partyOpts.options.governance.voteDuration = 7 days;
        partyOpts.options.governance.executionDelay = 1 days;
        partyOpts.options.governance.passThresholdBps = 0.5e4;
        partyOpts.options.governance.hosts = new address[](1);
        partyOpts.options.governance.hosts[0] = address(this);

        party = Party(
            payable(new Proxy(new Party(globals), abi.encodeCall(Party.initialize, (partyOpts))))
        );
    }

    function _createCrowdfund(
        uint96 initialContribution,
        address payable initialContributor,
        address initialDelegate,
        uint96 minContributions,
        uint96 maxContributions,
        bool disableContributingForExistingCard,
        uint96 minTotalContributions,
        uint96 maxTotalContributions,
        uint40 duration,
        uint16 fundingSplitBps,
        address payable fundingSplitRecipient
    ) private returns (ReraiseETHCrowdfund crowdfund) {
        ETHCrowdfundBase.ETHCrowdfundOptions memory opts;
        opts.party = party;
        opts.initialContributor = initialContributor;
        opts.initialDelegate = initialDelegate;
        opts.minContribution = minContributions;
        opts.maxContribution = maxContributions;
        opts.disableContributingForExistingCard = disableContributingForExistingCard;
        opts.minTotalContributions = minTotalContributions;
        opts.maxTotalContributions = maxTotalContributions;
        opts.duration = duration;
        opts.exchangeRateBps = 1e4;
        opts.fundingSplitBps = fundingSplitBps;
        opts.fundingSplitRecipient = fundingSplitRecipient;

        crowdfund = ReraiseETHCrowdfund(
            payable(
                new Proxy{ value: initialContribution }(
                    reraiseETHCrowdfundImpl,
                    abi.encodeCall(ReraiseETHCrowdfund.initialize, (opts))
                )
            )
        );

        vm.prank(address(party));
        party.addAuthority(address(crowdfund));
    }

    function test_initialization_cannotReinitialize() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 0,
            maxTotalContributions: type(uint96).max,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        ETHCrowdfundBase.ETHCrowdfundOptions memory opts;

        vm.expectRevert(Implementation.OnlyConstructorError.selector);
        crowdfund.initialize(opts);
    }

    function test_initialization_minTotalContributionsGreaterThanMax() public {
        uint96 minTotalContributions = 5 ether;
        uint96 maxTotalContributions = 3 ether;

        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.MinGreaterThanMaxError.selector,
                minTotalContributions,
                maxTotalContributions
            )
        );
        _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: minTotalContributions,
            maxTotalContributions: maxTotalContributions,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });
    }

    function test_initialization_maxTotalContributionsZero() public {
        uint96 maxTotalContributions = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.MaxTotalContributionsCannotBeZeroError.selector,
                maxTotalContributions
            )
        );
        _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 0,
            maxTotalContributions: maxTotalContributions,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });
    }

    function test_initialContribution_works() public {
        address payable initialContributor = payable(_randomAddress());
        address initialDelegate = _randomAddress();
        uint96 initialContribution = 1 ether;

        // Create crowdfund with initial contribution
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: initialContribution,
            initialContributor: initialContributor,
            initialDelegate: initialDelegate,
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        assertEq(initialContributor.balance, 0);
        assertEq(address(crowdfund).balance, initialContribution);
        assertEq(crowdfund.totalContributions(), initialContribution);
        assertEq(crowdfund.pendingVotingPower(initialContributor), initialContribution);
    }

    function test_initialContribution_aboveMaxTotalContribution() public {
        address payable initialContributor = payable(_randomAddress());
        address initialDelegate = _randomAddress();
        uint96 initialContribution = 1 ether;

        // Will fail because initial contribution should trigger crowdfund to
        // try to finalize a win but it will fail because it is not yet set as
        // an authority on the party
        vm.expectRevert(PartyGovernanceNFT.OnlyAuthorityError.selector);
        // Create crowdfund with initial contribution
        _createCrowdfund({
            initialContribution: initialContribution,
            initialContributor: initialContributor,
            initialDelegate: initialDelegate,
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: initialContribution,
            maxTotalContributions: initialContribution,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });
    }

    function test_contribute_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute
        uint256 tokenId = uint256(uint160(member));
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, member, 1 ether, member);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), member, tokenId);
        crowdfund.contribute{ value: 1 ether }(member, "");

        assertEq(member.balance, 0);
        assertEq(address(crowdfund).balance, 1 ether);
        assertEq(crowdfund.totalContributions(), 1 ether);
        assertEq(crowdfund.pendingVotingPower(member), 1 ether);
        assertEq(crowdfund.ownerOf(tokenId), member);
        assertEq(crowdfund.delegationsByContributor(member), member);
    }

    function test_contribute_twiceDoesNotMintAnotherCrowdfundNFT() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 2 ether);

        // Contribute
        vm.startPrank(member);
        crowdfund.contribute{ value: 1 ether }(member, "");
        crowdfund.contribute{ value: 1 ether }(member, "");
        vm.stopPrank();

        assertEq(crowdfund.balanceOf(member), 1);
        assertEq(crowdfund.pendingVotingPower(member), 2 ether);
    }

    function test_contribute_noContribution() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();

        // Contribute, should be allowed to update delegate
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, member, 0, member);
        crowdfund.contribute(member, "");
    }

    function test_contribute_afterLost() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 1 ether,
            maxTotalContributions: 1 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 1);

        skip(7 days);

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Lost);

        // Try to contribute
        vm.prank(member);
        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.WrongLifecycleError.selector,
                ETHCrowdfundBase.CrowdfundLifecycle.Lost
            )
        );
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, member, 1, member);
        crowdfund.contribute{ value: 1 }(member, "");
    }

    function test_contribute_aboveMaxTotalContribution() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 0,
            maxTotalContributions: 1 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 2 ether);

        // Contribute
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, member, 2 ether, member);
        crowdfund.contribute{ value: 2 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        assertEq(address(member).balance, 1 ether); // Check refunded amount
        assertEq(address(party).balance, 1 ether);
        assertEq(crowdfund.totalContributions(), 1 ether);
        assertEq(party.getGovernanceValues().totalVotingPower, 1 ether);
    }

    function test_contribute_aboveMaxContribution() public {
        uint96 maxContribution = 1 ether;
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: maxContribution,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        uint96 contribution = maxContribution + 1;
        vm.deal(member, contribution);

        // Contribute
        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.AboveMaximumContributionsError.selector,
                contribution,
                maxContribution
            )
        );
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, member, contribution, member);
        crowdfund.contribute{ value: contribution }(member, "");
    }

    function test_contribute_belowMinContribution() public {
        uint96 minContribution = 1 ether;
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: minContribution,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        uint96 contribution = minContribution - 1;
        vm.deal(member, contribution);

        // Contribute
        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.BelowMinimumContributionsError.selector,
                contribution,
                minContribution
            )
        );
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, member, contribution, member);
        crowdfund.contribute{ value: contribution }(member, "");
    }

    function test_batchContribute_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 4 ether);

        // Batch contribute
        vm.prank(member);
        uint96[] memory values = new uint96[](3);
        for (uint256 i; i < 3; ++i) {
            values[i] = 1 ether;
        }
        bytes[] memory gateDatas = new bytes[](3);
        uint96[] memory votingPowers = crowdfund.batchContribute{ value: 4 ether }(
            ReraiseETHCrowdfund.BatchContributeArgs({
                delegate: member,
                values: values,
                gateDatas: gateDatas
            })
        );

        assertEq(address(member).balance, 1 ether); // Should be refunded 1 ETH
        assertEq(crowdfund.ownerOf(uint256(uint160(member))), member);
        for (uint256 i; i < values.length; ++i) {
            assertEq(votingPowers[i], 1 ether);
        }
    }

    function test_contributeFor_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });
        crowdfund.party();

        address member = _randomAddress();
        address payable recipient = _randomAddress();
        address delegate = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, recipient, 1 ether, delegate);
        crowdfund.contributeFor{ value: 1 ether }(recipient, delegate, "");

        assertEq(address(recipient).balance, 0);
        assertEq(address(crowdfund).balance, 1 ether);
        assertEq(crowdfund.delegationsByContributor(recipient), delegate);
        assertEq(crowdfund.totalContributions(), 1 ether);
    }

    function test_contributeFor_doesNotUpdateExistingDelegation() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });
        crowdfund.party();

        address member = _randomAddress();
        address payable recipient = _randomAddress();
        address delegate = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute to set initial delegation
        vm.prank(recipient);
        vm.expectEmit(true, false, false, true);
        emit Contributed(recipient, recipient, 0, recipient);
        crowdfund.contribute(recipient, "");

        // Contribute to try update delegation (should not work)
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, recipient, 1 ether, recipient);
        crowdfund.contributeFor{ value: 1 ether }(recipient, delegate, "");

        assertEq(crowdfund.delegationsByContributor(recipient), recipient);
    }

    function test_batchContributeFor_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address sender = _randomAddress();
        vm.deal(sender, 4 ether);

        // Batch contribute for
        vm.prank(sender);
        address payable[] memory recipients = new address payable[](3);
        address[] memory delegates = new address[](3);
        uint96[] memory values = new uint96[](3);
        bytes[] memory gateDatas = new bytes[](3);
        for (uint256 i; i < 3; ++i) {
            recipients[i] = _randomAddress();
            delegates[i] = _randomAddress();
            values[i] = 1 ether;
        }
        uint96[] memory votingPowers = crowdfund.batchContributeFor{ value: 4 ether }(
            ReraiseETHCrowdfund.BatchContributeForArgs({
                recipients: recipients,
                initialDelegates: delegates,
                values: values,
                gateDatas: gateDatas,
                revertOnFailure: true
            })
        );

        assertEq(address(sender).balance, 1 ether); // Should be refunded 1 ETH
        for (uint256 i; i < values.length; ++i) {
            assertEq(votingPowers[i], 1 ether);
            assertEq(crowdfund.delegationsByContributor(recipients[i]), delegates[i]);
        }
        for (uint256 i; i < recipients.length; ++i) {
            assertEq(
                crowdfund.ownerOf(uint256(uint160(address(recipients[i])))),
                address(recipients[i])
            );
        }
    }

    function test_finalize_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 3 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 3 ether }(member, "");

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Active);

        // Finalize
        crowdfund.finalize();

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );
        assertEq(party.getGovernanceValues().totalVotingPower, 3 ether);
        assertEq(address(party).balance, 3 ether);
    }

    function test_finalize_onlyHostCanFinalizeEarlyWhenActive() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 3 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 3 ether }(member, "");

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Active);

        // Try to finalize as non-host
        address nonHost = _randomAddress();
        vm.expectRevert(ETHCrowdfundBase.OnlyPartyHostError.selector);
        vm.prank(nonHost);
        crowdfund.finalize();
    }

    function test_finalize_anyoneCanFinalizeWhenExpired() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 3 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 3 ether }(member, "");

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Active);

        skip(7 days);

        // Try to finalize as rando
        vm.prank(_randomAddress());
        crowdfund.finalize();
    }

    function test_finalize_belowMinTotalContributions() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 2 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 2 ether }(member, "");

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Active);

        // Try to finalize
        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.NotEnoughContributionsError.selector,
                2 ether,
                3 ether
            )
        );
        crowdfund.finalize();
    }

    function test_expiry_won() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 4 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 4 ether }(member, "");

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Active);

        skip(7 days);

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Won);
    }

    function test_expiry_lost() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 2 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 2 ether }(member, "");

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Active);

        skip(7 days);

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Lost);
    }

    function test_claim_mintNewCard() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 5 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 5 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card
        uint256 tokenId = 1;
        vm.expectEmit(true, true, true, true);
        emit Transfer(member, address(0), uint256(uint160(member)));
        vm.expectEmit(true, true, false, true);
        emit Claimed(member, tokenId, 5 ether);
        crowdfund.claim(member);

        // Should have burned the crowdfund NFT
        vm.expectRevert(
            abi.encodeWithSelector(
                CrowdfundNFT.InvalidTokenError.selector,
                uint256(uint160(member))
            )
        );
        crowdfund.ownerOf(uint256(uint160(member)));

        assertEq(party.ownerOf(tokenId), member);
        assertEq(party.votingPowerByTokenId(tokenId), 5 ether);
    }

    function test_claim_aboveMax() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: 2 ether,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 4 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 4 ether);

        // Contribute, twice
        vm.prank(member);
        crowdfund.contribute{ value: 2 ether }(member, "");

        vm.prank(member);
        crowdfund.contribute{ value: 2 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card
        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.AboveMaximumContributionsError.selector,
                4 ether,
                2 ether
            )
        );
        crowdfund.claim(member);
    }

    function test_claim_mintNewCard_withDisableContributingForExistingCard() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: true,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 5 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 5 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card
        uint256 tokenId = 1;
        vm.prank(member);
        vm.expectRevert(ETHCrowdfundBase.ContributingForExistingCardDisabledError.selector);
        crowdfund.claim(tokenId, member);
    }

    function test_claim_addVotingPowerToExistingCard() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 5 ether);

        // Mint (empty) card for member
        vm.prank(address(crowdfund));
        party.mint(member, 0, member);

        uint256 tokenId = 1;
        assertEq(party.ownerOf(tokenId), member);
        assertEq(party.votingPowerByTokenId(tokenId), 0);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 5 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card and add voting power to existing card
        vm.expectEmit(true, true, true, true);
        emit Transfer(member, address(0), uint256(uint160(member)));
        vm.expectEmit(true, true, false, true);
        emit Claimed(member, tokenId, 5 ether);
        crowdfund.claim(tokenId, member);

        // Should have burned the crowdfund NFT
        vm.expectRevert(
            abi.encodeWithSelector(
                CrowdfundNFT.InvalidTokenError.selector,
                uint256(uint160(member))
            )
        );
        crowdfund.ownerOf(uint256(uint160(member)));

        assertEq(party.ownerOf(tokenId), member);
        assertEq(party.votingPowerByTokenId(tokenId), 5 ether);
    }

    function test_batchClaim_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 3 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        // Contribute
        address[] memory members = new address[](3);
        for (uint256 i = 0; i < members.length; i++) {
            members[i] = _randomAddress();
            vm.deal(members[i], 1 ether);
            vm.prank(members[i]);
            crowdfund.contribute{ value: 1 ether }(members[i], "");
        }

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Batch claim
        uint256[] memory tokenIds = new uint256[](3);
        crowdfund.batchClaim(tokenIds, members, true);

        for (uint256 i = 0; i < members.length; i++) {
            uint256 tokenId = i + 1;
            assertEq(party.ownerOf(tokenId), members[i]);
            assertEq(party.votingPowerByTokenId(tokenId), 1 ether);
        }
    }

    function test_claimMultiple_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 5 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 5 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card
        uint96[] memory votingPowerByCard = new uint96[](5);
        for (uint256 i; i < votingPowerByCard.length; ++i) {
            votingPowerByCard[i] = 1 ether;

            vm.expectEmit(true, true, false, true);
            emit Claimed(member, i + 1, 1 ether);
        }

        crowdfund.claimMultiple(votingPowerByCard, member);

        for (uint256 i; i < votingPowerByCard.length; ++i) {
            uint256 tokenId = i + 1;
            assertEq(party.ownerOf(tokenId), member);
            assertEq(party.votingPowerByTokenId(tokenId), 1 ether);
        }
    }

    function test_claimMultiple_cannotClaimMoreThanVotingPower() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 5 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 5 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card
        uint96[] memory votingPowerByCard = new uint96[](6);
        for (uint256 i; i < votingPowerByCard.length; ++i) {
            votingPowerByCard[i] = 1 ether;
        }

        vm.expectRevert(stdError.arithmeticError);
        crowdfund.claimMultiple(votingPowerByCard, member);
    }

    function test_claimMultiple_cannotHaveRemainingVotingPowerAfterClaim() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 5 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 5 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card
        uint96[] memory votingPowerByCard = new uint96[](4);
        for (uint256 i; i < votingPowerByCard.length; ++i) {
            votingPowerByCard[i] = 1 ether;
        }

        vm.expectRevert(
            abi.encodeWithSelector(
                ReraiseETHCrowdfund.RemainingVotingPowerAfterClaimError.selector,
                1 ether // 4 ether of voting power claimed, 1 ether remaining
            )
        );
        crowdfund.claimMultiple(votingPowerByCard, member);
    }

    function test_claimMultiple_votingPowerOfCardBelowMin() public {
        uint96 minContributions = 1 ether;

        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: minContributions,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 5 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 5 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card
        uint96[] memory votingPowerByCard = new uint96[](1);
        votingPowerByCard[0] = minContributions - 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.BelowMinimumContributionsError.selector,
                votingPowerByCard[0],
                minContributions
            )
        );
        crowdfund.claimMultiple(votingPowerByCard, member);
    }

    function test_claimMultiple_votingPowerOfCardAboveMax() public {
        uint96 maxContributions = 1 ether;

        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: maxContributions,
            disableContributingForExistingCard: false,
            minTotalContributions: 1 ether,
            maxTotalContributions: 1 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 1 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Claim card
        uint96[] memory votingPowerByCard = new uint96[](1);
        votingPowerByCard[0] = maxContributions + 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.AboveMaximumContributionsError.selector,
                votingPowerByCard[0],
                maxContributions
            )
        );
        crowdfund.claimMultiple(votingPowerByCard, member);
    }

    function test_batchClaimMultiple_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 6 ether,
            maxTotalContributions: 6 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        // Contribute
        address[] memory members = new address[](3);
        for (uint256 i = 0; i < members.length; i++) {
            members[i] = _randomAddress();
            vm.deal(members[i], 2 ether);
            vm.prank(members[i]);
            crowdfund.contribute{ value: 2 ether }(members[i], "");
        }

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Batch claim cards
        uint96[][] memory votingPowerByCards = new uint96[][](3);
        for (uint256 i = 0; i < votingPowerByCards.length; i++) {
            votingPowerByCards[i] = new uint96[](2);
            votingPowerByCards[i][0] = votingPowerByCards[i][1] = 1 ether;
        }
        crowdfund.batchClaimMultiple(votingPowerByCards, members, true);

        for (uint256 i = 0; i < members.length; i++) {
            for (uint256 j = 1; j < 3; ++j) {
                assertEq(party.ownerOf(i * 2 + j), members[i]);
                assertEq(party.votingPowerByTokenId(i * 2 + j), 1 ether);
            }
        }
    }

    function test_refund_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 2 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 2 ether }(member, "");
        assertEq(address(member).balance, 0);

        skip(7 days);

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Lost);

        // Claim refund
        vm.expectEmit(true, false, false, true);
        vm.expectEmit(true, true, true, true);
        emit Transfer(member, address(0), uint256(uint160(member)));
        emit Refunded(member, 2 ether);
        vm.prank(member);
        crowdfund.refund(payable(member));

        // Should have burned the crowdfund NFT
        vm.expectRevert(
            abi.encodeWithSelector(
                CrowdfundNFT.InvalidTokenError.selector,
                uint256(uint160(member))
            )
        );
        crowdfund.ownerOf(uint256(uint160(member)));

        assertEq(address(member).balance, 2 ether);
    }

    function test_refund_notLost() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 5 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 2 ether }(member, "");

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Active);

        // Try to claim refund
        vm.prank(member);
        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.WrongLifecycleError.selector,
                ETHCrowdfundBase.CrowdfundLifecycle.Active
            )
        );
        crowdfund.refund(payable(member));

        // Contribute again to win
        vm.prank(member);
        crowdfund.contribute{ value: 3 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        // Try to claim refund
        vm.prank(member);
        vm.expectRevert(
            abi.encodeWithSelector(
                ETHCrowdfundBase.WrongLifecycleError.selector,
                ETHCrowdfundBase.CrowdfundLifecycle.Finalized
            )
        );
        crowdfund.refund(payable(member));
    }

    function test_refund_twice() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        address member = _randomAddress();
        vm.deal(member, 2 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 2 ether }(member, "");
        assertEq(address(member).balance, 0);

        skip(7 days);

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Lost);

        // Claim refund
        vm.prank(member);
        crowdfund.refund(payable(member));
        assertEq(address(member).balance, 2 ether);
        assertEq(address(party).balance, 0);

        // Try to claim refund again
        vm.prank(member);
        crowdfund.refund(payable(member));
        // Check balance unchanged
        assertEq(address(member).balance, 2 ether);
        assertEq(address(party).balance, 0);
    }

    function test_batchRefund_works() public {
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 4 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0,
            fundingSplitRecipient: payable(address(0))
        });

        // Contribute
        address payable[] memory members = new address payable[](3);
        for (uint256 i = 0; i < members.length; i++) {
            members[i] = _randomAddress();
            vm.deal(members[i], 1 ether);
            vm.prank(members[i]);
            crowdfund.contribute{ value: 1 ether }(members[i], "");
        }

        skip(7 days);

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Lost);

        // Batch refund
        address sender = _randomAddress();
        vm.prank(sender);
        crowdfund.batchRefund(members, true);

        for (uint256 i = 0; i < members.length; i++) {
            assertEq(address(members[i]).balance, 1 ether);
        }
    }

    function test_fundingSplit_contributionAndRefund() public {
        address payable fundingSplitRecipient = payable(_randomAddress());
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 3 ether,
            maxTotalContributions: 5 ether,
            duration: 7 days,
            fundingSplitBps: 0.2e4,
            fundingSplitRecipient: fundingSplitRecipient
        });

        address member = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 1 ether }(member, "");
        assertEq(address(member).balance, 0);
        assertEq(crowdfund.pendingVotingPower(member), 0.8 ether);

        skip(7 days);

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Lost);

        // Claim refund
        vm.prank(member);
        crowdfund.refund(payable(member));
        assertEq(address(member).balance, 1 ether);
        assertEq(address(party).balance, 0);
    }

    function test_fundingSplit_finalize() public {
        address payable fundingSplitRecipient = payable(_randomAddress());
        ReraiseETHCrowdfund crowdfund = _createCrowdfund({
            initialContribution: 0,
            initialContributor: payable(address(0)),
            initialDelegate: address(0),
            minContributions: 0,
            maxContributions: type(uint96).max,
            disableContributingForExistingCard: false,
            minTotalContributions: 1 ether,
            maxTotalContributions: 1 ether,
            duration: 7 days,
            fundingSplitBps: 0.2e4,
            fundingSplitRecipient: fundingSplitRecipient
        });

        address member = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 1 ether }(member, "");

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );

        assertEq(address(party).balance, 0.8 ether);
        assertEq(fundingSplitRecipient.balance, 0.2 ether);
    }
}

contract MockRendererStorage {
    /// @notice Customization preset used by a crowdfund or party instance.
    mapping(address => uint256) public getPresetFor;
}
