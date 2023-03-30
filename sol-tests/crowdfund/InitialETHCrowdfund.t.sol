// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "forge-std/Test.sol";

import "../../contracts/crowdfund/InitialETHCrowdfund.sol";
import "../../contracts/globals/Globals.sol";
import "../../contracts/utils/Proxy.sol";
import "../../contracts/party/PartyFactory.sol";
import "../../contracts/tokens/ERC721Receiver.sol";

import "../TestUtils.sol";

contract InitialETHCrowdfundTest is Test, TestUtils, ERC721Receiver {
    event Contributed(
        address indexed sender,
        address indexed contributor,
        uint256 amount,
        address delegate
    );
    event Refunded(address indexed contributor, uint256 indexed tokenId, uint256 amount);

    InitialETHCrowdfund initialETHCrowdfundImpl;
    Globals globals;
    Party partyImpl;
    PartyFactory partyFactory;

    constructor() {
        globals = new Globals(address(this));
        partyImpl = new Party(globals);
        partyFactory = new PartyFactory();

        initialETHCrowdfundImpl = new InitialETHCrowdfund();
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
    ) private returns (InitialETHCrowdfund crowdfund) {
        InitialETHCrowdfund.InitialETHCrowdfundOptions memory crowdfundOpts;
        crowdfundOpts.initialContributor = initialContributor;
        crowdfundOpts.initialDelegate = initialDelegate;
        crowdfundOpts.minContribution = minContributions;
        crowdfundOpts.maxContribution = maxContributions;
        crowdfundOpts.disableContributingForExistingCard = disableContributingForExistingCard;
        crowdfundOpts.minTotalContributions = minTotalContributions;
        crowdfundOpts.maxTotalContributions = maxTotalContributions;
        crowdfundOpts.duration = duration;
        crowdfundOpts.exchangeRateBps = 1e4;
        crowdfundOpts.fundingSplitBps = fundingSplitBps;
        crowdfundOpts.fundingSplitRecipient = fundingSplitRecipient;

        InitialETHCrowdfund.ETHPartyOptions memory partyOpts;
        partyOpts.governanceOpts.partyImpl = partyImpl;
        partyOpts.governanceOpts.partyFactory = partyFactory;
        partyOpts.governanceOpts.voteDuration = 7 days;
        partyOpts.governanceOpts.executionDelay = 1 days;
        partyOpts.governanceOpts.passThresholdBps = 0.5e4;
        partyOpts.governanceOpts.hosts = new address[](1);
        partyOpts.governanceOpts.hosts[0] = address(this);

        crowdfund = InitialETHCrowdfund(
            payable(
                new Proxy{ value: initialContribution }(
                    initialETHCrowdfundImpl,
                    abi.encodeCall(InitialETHCrowdfund.initialize, (crowdfundOpts, partyOpts))
                )
            )
        );
    }

    function test_initialization_cannotReinitialize() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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

        InitialETHCrowdfund.InitialETHCrowdfundOptions memory crowdfundOpts;
        InitialETHCrowdfund.ETHPartyOptions memory partyOpts;

        vm.expectRevert(Implementation.OnlyConstructorError.selector);
        crowdfund.initialize(crowdfundOpts, partyOpts);
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
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        assertEq(initialContributor.balance, 0);
        assertEq(address(crowdfund).balance, initialContribution);
        assertEq(crowdfund.totalContributions(), initialContribution);
        assertEq(party.tokenCount(), 1);
        assertEq(party.ownerOf(1), initialContributor);
        assertEq(party.votingPowerByTokenId(1), initialContribution);
        assertEq(
            party.getVotingPowerAt(initialDelegate, uint40(block.timestamp)),
            initialContribution
        );
    }

    function test_initialContribution_aboveMaxTotalContribution() public {
        address payable initialContributor = payable(_randomAddress());
        address initialDelegate = _randomAddress();
        uint96 initialContribution = 1 ether;

        // Create crowdfund with initial contribution
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        assertTrue(
            crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Finalized
        );
        assertEq(party.getGovernanceValues().totalVotingPower, initialContribution);
        assertEq(address(party).balance, initialContribution);
    }

    function test_contribute_mintNewCard() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        address member = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, member, 1 ether, member);
        crowdfund.contribute{ value: 1 ether }(member, "");

        uint256 tokenId = 1;
        assertEq(party.ownerOf(tokenId), member);
        assertEq(party.votingPowerByTokenId(tokenId), 1 ether);

        assertEq(address(member).balance, 0);
        assertEq(address(crowdfund).balance, 1 ether);
        assertEq(crowdfund.totalContributions(), 1 ether);
        assertEq(crowdfund.delegationsByContributor(member), member);
    }

    function test_contribute_mintNewCard_withDisableContributingForExistingCard() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        vm.deal(member, 1 ether);

        // Contribute
        uint256 tokenId = 1;
        vm.prank(member);
        vm.expectRevert(ETHCrowdfundBase.ContributingForExistingCardDisabledError.selector);
        crowdfund.contribute{ value: 1 ether }(tokenId, member, "");
    }

    function test_contribute_addVotingPowerToExistingCard() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        address member = _randomAddress();
        vm.deal(member, 2 ether);

        // Contribute
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, member, 1 ether, member);
        crowdfund.contribute{ value: 1 ether }(member, "");

        uint256 tokenId = 1;
        assertEq(party.ownerOf(tokenId), member);
        assertEq(party.votingPowerByTokenId(tokenId), 1 ether);

        // Contribute again
        vm.prank(member);
        crowdfund.contribute{ value: 1 ether }(tokenId, member, "");
        assertEq(party.votingPowerByTokenId(tokenId), 2 ether);
    }

    function test_contribute_noContribution() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        crowdfund.contribute{ value: 1 }(member, "");
    }

    function test_contribute_aboveMaxTotalContribution() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        address member = _randomAddress();
        vm.deal(member, 2 ether);

        // Contribute
        vm.prank(member);
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
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        crowdfund.contribute{ value: contribution }(member, "");
    }

    function test_contribute_belowMinContribution() public {
        uint96 minContribution = 1 ether;
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        crowdfund.contribute{ value: contribution }(member, "");
    }

    function test_batchContribute_works() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        address member = _randomAddress();
        vm.deal(member, 4 ether);

        // Batch contribute
        vm.prank(member);
        uint256[] memory tokenIds = new uint256[](3);
        uint96[] memory values = new uint96[](3);
        for (uint256 i; i < 3; ++i) {
            values[i] = 1 ether;
        }
        bytes[] memory gateDatas = new bytes[](3);
        uint96[] memory votingPowers = crowdfund.batchContribute{ value: 4 ether }(
            InitialETHCrowdfund.BatchContributeArgs({
                tokenIds: tokenIds,
                delegate: member,
                values: values,
                gateDatas: gateDatas
            })
        );

        assertEq(address(member).balance, 1 ether); // Should be refunded 1 ETH
        for (uint256 i; i < values.length; ++i) {
            assertEq(votingPowers[i], 1 ether);
        }
        for (uint256 i = 1; i < 4; ++i) {
            assertEq(party.ownerOf(i), member);
            assertEq(party.votingPowerByTokenId(i), 1 ether);
        }
    }

    function test_contributeFor_works() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        address member = _randomAddress();
        address payable recipient = _randomAddress();
        address delegate = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute
        vm.prank(member);
        vm.expectEmit(true, false, false, true);
        emit Contributed(member, recipient, 1 ether, delegate);
        crowdfund.contributeFor{ value: 1 ether }(0, recipient, delegate, "");

        uint256 tokenId = 1;
        assertEq(party.ownerOf(tokenId), recipient);
        assertEq(party.votingPowerByTokenId(tokenId), 1 ether);

        assertEq(address(recipient).balance, 0);
        assertEq(address(crowdfund).balance, 1 ether);
        assertEq(crowdfund.delegationsByContributor(recipient), delegate);
        assertEq(crowdfund.totalContributions(), 1 ether);
    }

    function test_contributeFor_doesNotUpdateExistingDelegation() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        crowdfund.contributeFor{ value: 1 ether }(0, recipient, delegate, "");

        assertEq(crowdfund.delegationsByContributor(recipient), recipient);
    }

    function test_batchContributeFor_works() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        address sender = _randomAddress();
        vm.deal(sender, 4 ether);

        // Batch contribute for
        vm.prank(sender);
        uint256[] memory tokenIds = new uint256[](3);
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
            InitialETHCrowdfund.BatchContributeForArgs({
                tokenIds: tokenIds,
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
        for (uint256 i = 1; i < 4; ++i) {
            assertEq(party.ownerOf(i), recipients[i - 1]);
            assertEq(party.votingPowerByTokenId(i), 1 ether);
        }
    }

    function test_finalize_works() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

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
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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

    function test_refund_works() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

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
        uint256 tokenId = 1;
        vm.expectEmit(true, true, false, true);
        emit Refunded(member, tokenId, 2 ether);
        crowdfund.refund(tokenId);
        vm.expectRevert("NOT_MINTED"); // Check token burned
        party.ownerOf(tokenId);
        assertEq(address(member).balance, 2 ether);
    }

    function test_refund_notLost() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        uint256 tokenId = 1;
        crowdfund.refund(tokenId);

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
        crowdfund.refund(tokenId);
    }

    function test_refund_twice() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

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
        uint256 tokenId = 1;
        crowdfund.refund(tokenId);
        assertEq(address(member).balance, 2 ether);
        assertEq(address(party).balance, 0);

        // Try to claim refund again
        vm.prank(member);
        crowdfund.refund(tokenId);
        // Check balance unchanged
        assertEq(address(member).balance, 2 ether);
        assertEq(address(party).balance, 0);
    }

    function test_batchRefund_works() public {
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        address[] memory members = new address[](3);
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
        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenIds[i] = i + 1;
        }
        vm.prank(sender);
        crowdfund.batchRefund(tokenIds, true);

        for (uint256 i = 0; i < members.length; i++) {
            assertEq(address(members[i]).balance, 1 ether);
        }
    }

    function test_fee_contributionAndRefund() public {
        address payable fundingSplitRecipient = payable(_randomAddress());
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

        address member = _randomAddress();
        vm.deal(member, 1 ether);

        // Contribute
        vm.prank(member);
        crowdfund.contribute{ value: 1 ether }(member, "");
        uint256 tokenId = 1;
        assertEq(address(member).balance, 0);
        assertEq(party.votingPowerByTokenId(tokenId), 0.8 ether);

        skip(7 days);

        assertTrue(crowdfund.getCrowdfundLifecycle() == ETHCrowdfundBase.CrowdfundLifecycle.Lost);

        // Claim refund
        vm.prank(member);
        crowdfund.refund(tokenId);
        assertEq(address(member).balance, 1 ether);
        assertEq(address(party).balance, 0);
    }

    function test_fee_finalize() public {
        address payable fundingSplitRecipient = payable(_randomAddress());
        InitialETHCrowdfund crowdfund = _createCrowdfund({
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
        Party party = crowdfund.party();

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
