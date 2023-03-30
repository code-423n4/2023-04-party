# Party DAO

## Overview

Party Protocol aims to be a standard for group coordination, providing on-chain functionality for essential group behaviors:

1. **Formation:** Assembling a group and combining resources.

1. **Coordination:** Making decisions and taking action together.

1. **Distribution:** Sharing resources with group members.

Rather than pursuing a generic approach to start, we released the first version of the Party Protocol with a focus on NFTs, largely inspired by our initial work on PartyBid. This next release will expand the protocol past that, introducing the new concept of parties that can hold and use ETH.

Unlike previous version of parties, the initial crowdfund to raise ETH is created at the same time as the party. With this new crowdfund, users are minted a party card upon contributing instead of having to wait until the party is won like with past crowdfunds. Governance is activated once the crowdfund is won, and the party can vote on what to do with the raised funds.

Additional key new feature and updates include:

- Introduction of a new class of "operator" contracts, which are standalone contracts designed to execute specific actions on behalf of the party, possibly using resources sent to it by the party to complete the action. This starts with the addition of a new CollectionBatchBuyOperator that enables parties to buy NFTs.
- A new crowdfund type allows parties to re-raise funds, and a new proposal type enables parties to vote to perform a re-raise.
- Proposal execution engine that is now configurable. This was partly due to the necessity of enabling new parties with additional features while maintaining the same security guarantees for old parties. The update includes the addition of boolean flags set upon party initialization, providing more flexibility and control over party functionality.

## Contest Details

- Total Prize Pool: $56,500 USDC
  - HM awards: $37,400 USDC
  - QA report awards: $4,400 USDC
  - Gas report awards: $2,200 USDC
  - Judge awards: $12,000 USDC
  - Scout awards: $500 USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-04-party-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts April 3, 2023 20:00 UTC
- Ends April 14, 2023 20:00 UTC

## Scoping Details

```
- If you have a public code repo, please share it here: There's a private internal PR covering the new features, but the protocol is here: https://github.com/PartyDAO/party-protocol
- How many contracts are in scope?:   14
- Total SLoC for these contracts?:  2570
- How many external imports are there?: 2
- How many separate interfaces and struct definitions are there for the contracts within scope?:  23
- Does most of your code generally use composition or inheritance?:   inheritance
- How many external calls?:   1
- What is the overall line coverage percentage provided by your tests?:  80
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?:   true
- Please describe required context:   While there are new features under scope, most of focus in this contest will be on code refactored on an existing protocol to allow the new features added  to work (e.g. ability to crowdfund ETH for parties and reraise). Although not all aspects of the protocol were refactored, an understanding of the protocol's purpose as a whole and the reasoning behind specific functionality will be helpful. This context is well-explained in our documentation.
- Does it use an oracle?:  No
- Does the token conform to the ERC20 standard?:  No
- Are there any novel or unique curve logic or mathematical models?:
- Does it use a timelock function?:
- Is it an NFT?: true
- Does it have an AMM?: false
- Is it a fork of a popular project?:  false
- Does it use rollups?: false
- Is it multi-chain?: false
- Does it use a side-chain?: false
```

## Scope

| Contract                                                                                                 | SLOC | Purpose                                                                                                | Libraries used                                                                                                                                                                                                                                                                                                   |
| -------------------------------------------------------------------------------------------------------- | ---- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [contracts/party/PartyGovernance.sol](contracts/party/PartyGovernance.sol)                               | 725  | Handles the governance of a party, including configuration options                                     | [contracts/utils/ReadOnlyDelegateCall.sol](contracts/utils/ReadOnlyDelegateCall.sol), [contracts/utils/LibERC20Compat.sol](contracts/utils/LibERC20Compat.sol), [contracts/utils/LibRawResult.sol](contracts/utils/LibRawResult.sol), [contracts/utils/LibSafeCast.sol](contracts/utils/LibSafeCast.sol)         |
| [contracts/crowdfund/InitialETHCrowdfund.sol](contracts/crowdfund/InitialETHCrowdfund.sol)               | 274  | Crowdfund contract to raise initial funds for new ETH parties                                          | [contracts/utils/LibAddress.sol](contracts/utils/LibAddress.sol), [contracts/utils/LibRawResult.sol](contracts/utils/LibRawResult.sol), [contracts/utils/LibSafeCast.sol](contracts/utils/LibSafeCast.sol)                                                                                                       |
| [contracts/crowdfund/ReraiseETHCrowdfund.sol](contracts/crowdfund/ReraiseETHCrowdfund.sol)               | 273  | Crowdfund contract to re-raise funds for existing ETH parties                                          | [contracts/utils/LibAddress.sol](contracts/utils/LibAddress.sol), [contracts/utils/LibRawResult.sol](contracts/utils/LibRawResult.sol), [contracts/utils/LibSafeCast.sol](contracts/utils/LibSafeCast.sol)                                                                                                       |
| [contracts/proposals/ProposalExecutionEngine.sol](contracts/proposals/ProposalExecutionEngine.sol)       | 215  | Executes proposals and handles proposal logic                                                          | [contracts/utils/LibRawResult.sol](contracts/utils/LibRawResult.sol)                                                                                                                                                                                                                                             |
| [contracts/proposals/ArbitraryCallsProposal.sol](contracts/proposals/ArbitraryCallsProposal.sol)         | 199  | Handles arbitrary calls proposals, allowing spending of party's ETH if configured                      | [contracts/utils/LibSafeERC721.sol](contracts/utils/LibSafeERC721.sol), [contracts/utils/LibAddress.sol](contracts/utils/LibAddress.sol)                                                                                                                                                                         |
| [contracts/crowdfund/ETHCrowdfundBase.sol](contracts/crowdfund/ETHCrowdfundBase.sol)                     | 189  | Base contract for ETH crowdfunds, inherited by `InitialETHCrowdfund` and `ReraiseETHCrowdfund`         | [contracts/utils/LibAddress.sol](contracts/utils/LibAddress.sol), [contracts/utils/LibSafeCast.sol](contracts/utils/LibSafeCast.sol)                                                                                                                                                                             |
| [contracts/party/PartyGovernanceNFT.sol](contracts/party/PartyGovernanceNFT.sol)                         | 188  | Handles the governance of a party's NFTs, allows multiple authorities, and supports new ETH crowdfunds | [openzeppelin/contracts/interfaces/IERC2981.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/IERC2981.sol), [contracts/utils/ReadOnlyDelegateCall.sol](contracts/utils/ReadOnlyDelegateCall.sol), [contracts/utils/LibSafeCast.sol](contracts/utils/LibSafeCast.sol) |
| [contracts/crowdfund/CrowdfundFactory.sol](contracts/crowdfund/CrowdfundFactory.sol)                     | 177  | Factory contract for creating new ETH crowdfunds and allowing custom implementation addresses          | [contracts/utils/LibRawResult.sol](contracts/utils/LibRawResult.sol)                                                                                                                                                                                                                                             |
| [contracts/operators/CollectionBatchBuyOperator.sol](contracts/operators/CollectionBatchBuyOperator.sol) | 144  | Operator contract allowing parties to buy NFTs through proposals                                       | [contracts/utils/LibRawResult.sol](contracts/utils/LibRawResult.sol), [contracts/utils/LibAddress.sol](contracts/utils/LibAddress.sol), [contracts/utils/LibSafeERC721.sol](contracts/utils/LibSafeERC721.sol)                                                                                                   |
| [contracts/proposals/VetoProposal.sol](contracts/proposals/VetoProposal.sol)                             | 45   | Handles proposals to veto other proposals                                                              | -                                                                                                                                                                                                                                                                                                                |
| [contracts/proposals/OperatorProposal.sol](contracts/proposals/OperatorProposal.sol)                     | 39   | Handles proposals to add/remove operators                                                              | -                                                                                                                                                                                                                                                                                                                |
| [contracts/party/PartyFactory.sol](contracts/party/PartyFactory.sol)                                     | 37   | Factory contract for creating new parties                                                              | -                                                                                                                                                                                                                                                                                                                |
| [contracts/proposals/AddAuthorityProposal.sol](contracts/proposals/AddAuthorityProposal.sol)             | 35   | Handles proposals to add authorities to a party's NFT                                                  | [contracts/utils/LibRawResult.sol](contracts/utils/LibRawResult.sol)                                                                                                                                                                                                                                             |
| [contracts/proposals/DistributeProposal.sol](contracts/proposals/DistributeProposal.sol)                 | 30   | Handles distribution proposals, allowing party members to claim their share of the party's assets      | -                                                                                                                                                                                                                                                                                                                |
| Total (over 14 files):                                                                                   | 2570 |                                                                                                        |                                                                                                                                                                                                                                                                                                                  |

## All-in-one Command

Here's an example one-liner to immediately get started with the codebase. It will clone the project, build it, run every test, and display gas reports:

```bash
export ETH_RPC_URL='<your_alchemy_mainnet_url_here>' && git clone https://github.com/code-423n4/2022-09-party && cd 2022-09-party && foundryup && forge install && yarn install && forge test -f $ETH_RPC_URL --gas-report
```

## Slither Issue

Note that slither does not seem to be working with the repo as-is 🤷, resulting in an enum type not found error:

```
slither.solc_parsing.exceptions.ParsingError: Type not found enum Crowdfund.CrowdfundLifecycle
```
