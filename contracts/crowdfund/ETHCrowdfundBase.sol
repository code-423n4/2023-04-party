// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/LibAddress.sol";
import "../utils/LibSafeCast.sol";
import "../party/Party.sol";
import "../gatekeepers/IGateKeeper.sol";

contract ETHCrowdfundBase is Implementation {
    using LibSafeCast for uint256;
    using LibAddress for address payable;

    enum CrowdfundLifecycle {
        // In practice, this state is never used. If the crowdfund is ever in
        // this stage, something is wrong (e.g. crowdfund was never initialized).
        Invalid,
        // Ready to accept contributions to reach contribution targets
        // until a deadline or the minimum contribution target is reached and
        // host finalizes.
        Active,
        // Expired and the minimum contribution target was not reached.
        Lost,
        // The crowdfund has expired and reached the minimum contribution
        // target. It is now ready to finalize.
        Won,
        // A won crowdfund has been finalized, with funds transferred to the
        // party and voting power successfully updated.
        Finalized
    }

    // Options to be passed into `initialize()` when the crowdfund is created.
    struct ETHCrowdfundOptions {
        Party party;
        address payable initialContributor;
        address initialDelegate;
        uint96 minContribution;
        uint96 maxContribution;
        bool disableContributingForExistingCard;
        uint96 minTotalContributions;
        uint96 maxTotalContributions;
        uint16 exchangeRateBps;
        uint16 fundingSplitBps;
        address payable fundingSplitRecipient;
        uint40 duration;
        IGateKeeper gateKeeper;
        bytes12 gateKeeperId;
    }

    error WrongLifecycleError(CrowdfundLifecycle lc);
    error NotAllowedByGateKeeperError(
        address contributor,
        IGateKeeper gateKeeper,
        bytes12 gateKeeperId,
        bytes gateData
    );
    error OnlyPartyHostError();
    error NotOwnerError();
    error InvalidDelegateError();
    error NotEnoughContributionsError(uint96 totalContribution, uint96 minTotalContributions);
    error MinGreaterThanMaxError(uint96 min, uint96 max);
    error MaxTotalContributionsCannotBeZeroError(uint96 maxTotalContributions);
    error BelowMinimumContributionsError(uint96 contributions, uint96 minContributions);
    error AboveMaximumContributionsError(uint96 contributions, uint96 maxContributions);
    error ContributingForExistingCardDisabledError();

    event Contributed(
        address indexed sender,
        address indexed contributor,
        uint256 amount,
        address delegate
    );

    /// @notice The address of the `Party` contract instance associated
    ///         with the crowdfund.
    Party public party;
    /// @notice The minimum amount of ETH that a contributor can send to
    ///         participate in the crowdfund.
    uint96 public minContribution;
    /// @notice The maximum amount of ETH that a contributor can send to
    ///         participate in the crowdfund per address.
    uint96 public maxContribution;
    /// @notice A boolean flag that determines whether contributors are allowed
    ///         to increase the voting power of their existing party cards.
    bool public disableContributingForExistingCard;
    /// @notice The minimum amount of total ETH contributions required for the
    ///         crowdfund to be considered successful.
    uint96 public minTotalContributions;
    /// @notice The maximum amount of total ETH contributions allowed for the
    ///         crowdfund.
    uint96 public maxTotalContributions;
    /// @notice The total amount of ETH contributed to the crowdfund so far.
    uint96 public totalContributions;
    /// @notice The timestamp at which the crowdfund will end or ended. If 0, the
    ///         crowdfund has finalized.
    uint40 public expiry;
    /// @notice The exchange rate to use for converting ETH contributions to
    ///         voting power in basis points (e.g. 10000 = 1:1).
    uint16 public exchangeRateBps;
    /// @notice The portion of contributions to send to the funding recipient in
    ///         basis points (e.g. 100 = 1%).
    uint16 public fundingSplitBps;
    /// @notice The address to which a portion of the contributions is sent as a
    ///         fee if set.
    address payable public fundingSplitRecipient;
    /// @notice The gatekeeper contract used to restrict who can contribute to the party.
    IGateKeeper public gateKeeper;
    /// @notice The ID of the gatekeeper to use for restricting contributions to the party.
    bytes12 public gateKeeperId;
    /// @notice The address a contributor is delegating their voting power to.
    mapping(address => address) public delegationsByContributor;

    // Initialize storage for proxy contracts, credit initial contribution (if
    // any), and setup gatekeeper.
    function _initialize(ETHCrowdfundOptions memory opts) internal {
        // Set the minimum and maximum contribution amounts.
        if (opts.minContribution > opts.maxContribution) {
            revert MinGreaterThanMaxError(opts.minContribution, opts.maxContribution);
        }
        minContribution = opts.minContribution;
        maxContribution = opts.maxContribution;
        // Set the min total contributions.
        if (opts.minTotalContributions > opts.maxTotalContributions) {
            revert MinGreaterThanMaxError(opts.minTotalContributions, opts.maxTotalContributions);
        }
        minTotalContributions = opts.minTotalContributions;
        // Set the max total contributions.
        if (opts.maxTotalContributions == 0) {
            // Prevent this because when `maxTotalContributions` is 0 the
            // crowdfund is invalid in `getCrowdfundLifecycle()` meaning it has
            // never been initialized.
            revert MaxTotalContributionsCannotBeZeroError(opts.maxTotalContributions);
        }
        maxTotalContributions = opts.maxTotalContributions;
        // Set the party crowdfund is for.
        party = opts.party;
        // Set the crowdfund start and end timestamps.
        expiry = uint40(block.timestamp + opts.duration);
        // Set the exchange rate.
        exchangeRateBps = opts.exchangeRateBps;
        // Set the funding split and its recipient.
        fundingSplitBps = opts.fundingSplitBps;
        fundingSplitRecipient = opts.fundingSplitRecipient;
        // Set whether to disable contributing for existing card.
        disableContributingForExistingCard = opts.disableContributingForExistingCard;
    }

    /// @notice Get the current lifecycle of the crowdfund.
    function getCrowdfundLifecycle() public view returns (CrowdfundLifecycle lifecycle) {
        if (maxTotalContributions == 0) {
            return CrowdfundLifecycle.Invalid;
        }

        uint256 expiry_ = expiry;
        if (expiry_ == 0) {
            return CrowdfundLifecycle.Finalized;
        }

        if (block.timestamp >= expiry_) {
            if (totalContributions >= minTotalContributions) {
                return CrowdfundLifecycle.Won;
            } else {
                return CrowdfundLifecycle.Lost;
            }
        }

        return CrowdfundLifecycle.Active;
    }

    function _processContribution(
        address payable contributor,
        address delegate,
        uint96 amount
    ) internal returns (uint96 votingPower) {
        address oldDelegate = delegationsByContributor[contributor];
        if (msg.sender == contributor || oldDelegate == address(0)) {
            // Update delegate.
            delegationsByContributor[contributor] = delegate;
        } else {
            // Prevent changing another's delegate if already delegated.
            delegate = oldDelegate;
        }

        emit Contributed(msg.sender, contributor, amount, delegate);

        // OK to contribute with zero just to update delegate.
        if (amount == 0) return 0;

        // Only allow contributions while the crowdfund is active.
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc != CrowdfundLifecycle.Active) {
            revert WrongLifecycleError(lc);
        }

        // Check that the contribution amount is within the allowed range.
        uint96 minContribution_ = minContribution;
        if (amount < minContribution_) {
            revert BelowMinimumContributionsError(amount, minContribution_);
        }
        uint96 maxContribution_ = maxContribution;
        if (amount > maxContribution_) {
            revert AboveMaximumContributionsError(amount, maxContribution_);
        }

        uint96 newTotalContributions = totalContributions + amount;
        uint96 maxTotalContributions_ = maxTotalContributions;
        if (newTotalContributions >= maxTotalContributions_) {
            totalContributions = maxTotalContributions_;

            // Finalize the crowdfund.
            // This occurs before refunding excess contribution to act as a
            // reentrancy guard.
            _finalize(maxTotalContributions_);

            // Refund excess contribution.
            uint96 refundAmount = newTotalContributions - maxTotalContributions;
            if (refundAmount > 0) {
                amount -= refundAmount;
                payable(msg.sender).transferEth(refundAmount);
            }
        } else {
            totalContributions = newTotalContributions;
        }

        // Subtract fee from contribution amount if applicable.
        address payable fundingSplitRecipient_ = fundingSplitRecipient;
        uint16 fundingSplitBps_ = fundingSplitBps;
        if (fundingSplitRecipient_ != address(0) && fundingSplitBps_ > 0) {
            uint96 feeAmount = (amount * fundingSplitBps_) / 1e4;
            amount -= feeAmount;
        }

        // Calculate voting power.
        votingPower = (amount * exchangeRateBps) / 1e4;
    }

    function _calculateRefundAmount(uint96 votingPower) internal view returns (uint96 amount) {
        amount = (votingPower * 1e4) / exchangeRateBps;

        // Add back fee to contribution amount if applicable.
        address payable fundingSplitRecipient_ = fundingSplitRecipient;
        uint16 fundingSplitBps_ = fundingSplitBps;
        if (fundingSplitRecipient_ != address(0) && fundingSplitBps_ > 0) {
            amount = (amount * 1e4) / (1e4 - fundingSplitBps_);
        }
    }

    function finalize() external {
        uint96 totalContributions_ = totalContributions;

        // Check that the crowdfund is not already finalized.
        CrowdfundLifecycle lc = getCrowdfundLifecycle();
        if (lc == CrowdfundLifecycle.Active) {
            // Allow host to finalize crowdfund early if it has reached its minimum goal.
            if (!party.isHost(msg.sender)) revert OnlyPartyHostError();

            // Check that the crowdfund has reached its minimum goal.
            uint96 minTotalContributions_ = minTotalContributions;
            if (totalContributions_ < minTotalContributions_) {
                revert NotEnoughContributionsError(totalContributions_, minTotalContributions_);
            }
        } else {
            // Otherwise only allow finalization if the crowdfund has expired
            // and been won. Can be finalized by anyone.
            if (lc != CrowdfundLifecycle.Won) {
                revert WrongLifecycleError(lc);
            }
        }

        // Finalize the crowdfund.
        _finalize(totalContributions_);
    }

    function _finalize(uint96 totalContributions_) internal {
        // Finalize the crowdfund.
        delete expiry;

        // Update the party's total voting power.
        uint96 newVotingPower = (totalContributions_ * exchangeRateBps) / 1e4;
        party.increaseTotalVotingPower(newVotingPower);

        // Transfer fee to recipient if applicable.
        address payable fundingSplitRecipient_ = fundingSplitRecipient;
        uint16 fundingSplitBps_ = fundingSplitBps;
        if (fundingSplitRecipient_ != address(0) && fundingSplitBps_ > 0) {
            uint96 feeAmount = (totalContributions_ * fundingSplitBps_) / 1e4;
            totalContributions_ -= feeAmount;
            fundingSplitRecipient_.transferEth(feeAmount);
        }

        // Transfer ETH to the party.
        payable(address(party)).transferEth(totalContributions_);
    }
}
