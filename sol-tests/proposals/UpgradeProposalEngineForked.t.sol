// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "forge-std/Test.sol";

import "../../contracts/proposals/ProposalExecutionEngine.sol";
import "../../contracts/globals/Globals.sol";
import "../../contracts/globals/LibGlobals.sol";
import "../../contracts/distribution/ITokenDistributor.sol";

import "../TestUtils.sol";

contract UpgradeProposalEngineForkedTest is Test, TestUtils {
    event ProposalEngineImplementationUpgraded(address oldImpl, address newImpl);

    Globals globals = Globals(0x1cA20040cE6aD406bC2A6c89976388829E7fbAde);
    // Try upgrading from party with old proposal engine implementation
    Party party = Party(payable(0x548D125A34aA3b242659aA0A424e85f34D2a7016));
    ProposalExecutionEngine oldEngine;
    ProposalExecutionEngine newEngine;

    address voter = 0xba5f2ffb721648Ee6a6c51c512A258ec62f1D6af;

    IERC721[] preciousTokens = [IERC721(0xde721B3C38cbFaBCdFcC29f0bC320efeB5c245ef)];
    uint256[] preciousTokenIds = [218];

    function setUp() public onlyForked {
        oldEngine = ProposalExecutionEngine(address(party.getProposalExecutionEngine()));
        newEngine = new ProposalExecutionEngine(
            IGlobals(_randomAddress()),
            IOpenseaExchange(_randomAddress()),
            IOpenseaConduitController(_randomAddress()),
            IZoraAuctionHouse(_randomAddress()),
            IFractionalV1VaultFactory(_randomAddress())
        );

        // Update ProposalExecutionEngine
        vm.prank(globals.multiSig());
        globals.setAddress(LibGlobals.GLOBAL_PROPOSAL_ENGINE_IMPL, address(newEngine));
    }

    receive() external payable {}

    function testForked_upgradeProposalEngine() public onlyForked {
        PartyGovernance.Proposal memory proposal = PartyGovernance.Proposal({
            maxExecutableTime: type(uint40).max,
            cancelDelay: 0,
            proposalData: abi.encodeWithSelector(
                bytes4(uint32(ProposalExecutionEngine.ProposalType.UpgradeProposalEngineImpl)),
                address(newEngine),
                ""
            )
        });

        vm.prank(voter);
        uint256 proposalId = party.propose(proposal, 0);

        (PartyGovernance.ProposalStatus status, ) = party.getProposalStateInfo(proposalId);
        assertTrue(status == PartyGovernance.ProposalStatus.Ready);

        skip(7 days);

        vm.prank(voter);
        vm.expectEmit(false, false, false, true);
        emit ProposalEngineImplementationUpgraded(address(oldEngine), address(newEngine));
        party.execute(proposalId, proposal, preciousTokens, preciousTokenIds, "", "");
    }

    function testForked_upgradeProposalEngine_canExecuteOperatorProposal() public onlyForked {
        testForked_upgradeProposalEngine();

        address[] memory allowedExecutors = new address[](1);
        allowedExecutors[0] = voter;

        PartyGovernance.Proposal memory proposal = PartyGovernance.Proposal({
            maxExecutableTime: type(uint40).max,
            cancelDelay: 0,
            proposalData: abi.encodeWithSelector(
                bytes4(uint32(ProposalExecutionEngine.ProposalType.Operator)),
                OperatorProposal.OperatorProposalData({
                    allowedExecutors: allowedExecutors,
                    operator: IOperator(address(new MockOperator())),
                    operatorValue: 0,
                    operatorData: ""
                })
            )
        });

        vm.prank(voter);
        uint256 proposalId = party.propose(proposal, 0);

        (PartyGovernance.ProposalStatus status, ) = party.getProposalStateInfo(proposalId);
        assertTrue(status == PartyGovernance.ProposalStatus.Ready);

        skip(7 days);

        vm.prank(voter);
        party.execute(
            proposalId,
            proposal,
            preciousTokens,
            preciousTokenIds,
            "",
            abi.encode(0, "")
        );
    }

    function testForked_upgradeProposalEngine_cannotExecuteDistributeProposal() public onlyForked {
        testForked_upgradeProposalEngine();

        // Create a distribution proposal.
        PartyGovernance.Proposal memory proposal = PartyGovernance.Proposal({
            maxExecutableTime: type(uint40).max,
            cancelDelay: 0,
            proposalData: abi.encodeWithSelector(
                bytes4(uint32(ProposalExecutionEngine.ProposalType.Distribute)),
                DistributeProposal.DistributeProposalData({
                    amount: 100,
                    tokenType: ITokenDistributor.TokenType.Native,
                    token: address(0),
                    tokenId: 0
                })
            )
        });

        vm.prank(voter);
        uint256 proposalId = party.propose(proposal, 0);

        (PartyGovernance.ProposalStatus status, ) = party.getProposalStateInfo(proposalId);
        assertTrue(status == PartyGovernance.ProposalStatus.Ready);

        skip(7 days);

        // Try to execute the distribution proposal.
        vm.prank(voter);
        vm.expectRevert();
        party.execute(proposalId, proposal, preciousTokens, preciousTokenIds, "", "");
    }

    function testForked_upgradeProposalEngine_cannotSpendPartyETHWithArbitraryCallProposal()
        public
        onlyForked
    {
        testForked_upgradeProposalEngine();

        vm.deal(address(party), 1e18);

        ArbitraryCallsProposal.ArbitraryCall[]
            memory calls = new ArbitraryCallsProposal.ArbitraryCall[](1);
        calls[0] = ArbitraryCallsProposal.ArbitraryCall({
            target: payable(address(this)),
            value: 1e18,
            data: "",
            expectedResultHash: bytes32(0)
        });
        PartyGovernance.Proposal memory proposal = PartyGovernance.Proposal({
            maxExecutableTime: type(uint40).max,
            cancelDelay: 0,
            proposalData: abi.encodeWithSelector(
                bytes4(uint32(ProposalExecutionEngine.ProposalType.ArbitraryCalls)),
                calls
            )
        });

        vm.prank(voter);
        uint256 proposalId = party.propose(proposal, 0);

        (PartyGovernance.ProposalStatus status, ) = party.getProposalStateInfo(proposalId);
        assertTrue(status == PartyGovernance.ProposalStatus.Ready);

        skip(7 days);

        vm.prank(voter);
        vm.expectRevert(
            abi.encodeWithSelector(
                ArbitraryCallsProposal.NotEnoughEthAttachedError.selector,
                1e18,
                0
            )
        );
        party.execute(proposalId, proposal, preciousTokens, preciousTokenIds, "", "");
    }

    function testForked_upgradeProposalEngine_cannotExecuteAddAuthorityProposal()
        public
        onlyForked
    {
        testForked_upgradeProposalEngine();

        PartyGovernance.Proposal memory proposal = PartyGovernance.Proposal({
            maxExecutableTime: type(uint40).max,
            cancelDelay: 0,
            proposalData: abi.encodeWithSelector(
                bytes4(uint32(ProposalExecutionEngine.ProposalType.AddAuthority)),
                AddAuthorityProposal.AddAuthorityProposalData({
                    target: address(this),
                    callData: ""
                })
            )
        });

        vm.prank(voter);
        uint256 proposalId = party.propose(proposal, 0);

        (PartyGovernance.ProposalStatus status, ) = party.getProposalStateInfo(proposalId);
        assertTrue(status == PartyGovernance.ProposalStatus.Ready);

        skip(7 days);

        vm.expectRevert();
        vm.prank(voter);
        party.execute(proposalId, proposal, preciousTokens, preciousTokenIds, "", "");
    }
}

contract MockOperator is IOperator {
    function execute(bytes memory operatorData, bytes memory executionData) external payable {}
}
