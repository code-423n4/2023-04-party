// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "../utils/ReadOnlyDelegateCall.sol";
import "../utils/LibSafeCast.sol";
import "openzeppelin/contracts/interfaces/IERC2981.sol";
import "../globals/IGlobals.sol";
import "../tokens/IERC721.sol";
import "../vendor/solmate/ERC721.sol";
import "./PartyGovernance.sol";
import "../renderers/RendererStorage.sol";

/// @notice ERC721 functionality built on top of `PartyGovernance`.
contract PartyGovernanceNFT is PartyGovernance, ERC721, IERC2981 {
    using LibSafeCast for uint256;
    using LibSafeCast for uint96;

    error OnlyAuthorityError();
    error OnlySelfError();
    error UnauthorizedToBurnError();

    event AuthorityAdded(address indexed authority);
    event AuthorityRemoved(address indexed authority);

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice Address with authority to mint cards and update voting power for the party.
    mapping(address => bool) public isAuthority;
    /// @notice The number of tokens that have been minted.
    uint96 public tokenCount;
    /// @notice The total minted voting power.
    ///         Capped to `_governanceValues.totalVotingPower` unless minting
    ///         party cards for initial crowdfund.
    uint96 public mintedVotingPower;
    /// @notice The voting power of `tokenId`.
    mapping(uint256 => uint256) public votingPowerByTokenId;

    modifier onlyAuthority() {
        if (!isAuthority[msg.sender]) {
            revert OnlyAuthorityError();
        }
        _;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert OnlySelfError();
        }
        _;
    }

    // Set the `Globals` contract. The name of symbol of ERC721 does not matter;
    // it will be set in `_initialize()`.
    constructor(IGlobals globals) PartyGovernance(globals) ERC721("", "") {
        _GLOBALS = globals;
    }

    // Initialize storage for proxy contracts.
    function _initialize(
        string memory name_,
        string memory symbol_,
        uint256 customizationPresetId,
        PartyGovernance.GovernanceOpts memory governanceOpts,
        ProposalStorage.ProposalEngineOpts memory proposalEngineOpts,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds,
        address[] memory authorities
    ) internal {
        PartyGovernance._initialize(
            governanceOpts,
            proposalEngineOpts,
            preciousTokens,
            preciousTokenIds
        );
        name = name_;
        symbol = symbol_;
        for (uint256 i; i < authorities.length; ++i) {
            isAuthority[authorities[i]] = true;
        }
        if (customizationPresetId != 0) {
            RendererStorage(_GLOBALS.getAddress(LibGlobals.GLOBAL_RENDERER_STORAGE))
                .useCustomizationPreset(customizationPresetId);
        }
    }

    /// @inheritdoc ERC721
    function ownerOf(
        uint256 tokenId
    ) public view override(ERC721, ITokenDistributorParty) returns (address owner) {
        return ERC721.ownerOf(tokenId);
    }

    /// @inheritdoc EIP165
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(PartyGovernance, ERC721, IERC165) returns (bool) {
        return
            PartyGovernance.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256) public view override returns (string memory) {
        _delegateToRenderer();
        return ""; // Just to make the compiler happy.
    }

    /// @notice Returns a URI for the storefront-level metadata for your contract.
    function contractURI() external view returns (string memory) {
        _delegateToRenderer();
        return ""; // Just to make the compiler happy.
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    function royaltyInfo(uint256, uint256) external view returns (address, uint256) {
        _delegateToRenderer();
        return (address(0), 0); // Just to make the compiler happy.
    }

    /// @inheritdoc ITokenDistributorParty
    function getDistributionShareOf(uint256 tokenId) external view returns (uint256) {
        return (votingPowerByTokenId[tokenId] * 1e18) / _getTotalVotingPower();
    }

    /// @notice Mint a governance NFT for `owner` with `votingPower` and
    ///         immediately delegate voting power to `delegate.` Only callable
    ///         by an authority.
    /// @param owner The owner of the NFT.
    /// @param votingPower The voting power of the NFT.
    /// @param delegate The address to delegate voting power to.
    function mint(
        address owner,
        uint256 votingPower,
        address delegate
    ) external onlyAuthority onlyDelegateCall returns (uint256 tokenId) {
        (uint96 tokenCount_, uint96 mintedVotingPower_) = (tokenCount, mintedVotingPower);
        uint96 totalVotingPower = _governanceValues.totalVotingPower;
        // Cap voting power to remaining unminted voting power supply.
        uint96 votingPower_ = votingPower.safeCastUint256ToUint96();
        // Allow minting past total voting power if minting party cards for
        // initial crowdfund when there is no total voting power.
        if (totalVotingPower != 0 && totalVotingPower - mintedVotingPower_ < votingPower_) {
            votingPower_ = totalVotingPower - mintedVotingPower_;
        }

        // Update state.
        tokenId = tokenCount = tokenCount_ + 1;
        mintedVotingPower += votingPower_;
        votingPowerByTokenId[tokenId] = votingPower_;

        // Use delegate from party over the one set during crowdfund.
        address delegate_ = delegationsByVoter[owner];
        if (delegate_ != address(0)) {
            delegate = delegate_;
        }

        _adjustVotingPower(owner, votingPower_.safeCastUint96ToInt192(), delegate);
        _safeMint(owner, tokenId);
    }

    /// @notice Add voting power to an existing NFT. Only callable by an
    ///         authority.
    /// @param tokenId The ID of the NFT to add voting power to.
    /// @param votingPower The amount of voting power to add.
    function addVotingPower(
        uint256 tokenId,
        uint256 votingPower
    ) external onlyAuthority onlyDelegateCall {
        uint96 mintedVotingPower_ = mintedVotingPower;
        uint96 totalVotingPower = _governanceValues.totalVotingPower;
        // Cap voting power to remaining unminted voting power supply.
        uint96 votingPower_ = votingPower.safeCastUint256ToUint96();
        // Allow minting past total voting power if minting party cards for
        // initial crowdfund when there is no total voting power.
        if (totalVotingPower != 0 && totalVotingPower - mintedVotingPower_ < votingPower_) {
            votingPower_ = totalVotingPower - mintedVotingPower_;
        }

        // Update state.
        mintedVotingPower += votingPower_;
        votingPowerByTokenId[tokenId] += votingPower_;

        _adjustVotingPower(ownerOf(tokenId), votingPower_.safeCastUint96ToInt192(), address(0));
    }

    /// @notice Update the total voting power of the party. Only callable by
    ///         an authority.
    /// @param newVotingPower The new total voting power to add.
    function increaseTotalVotingPower(
        uint96 newVotingPower
    ) external onlyAuthority onlyDelegateCall {
        _governanceValues.totalVotingPower += newVotingPower;
    }

    /// @notice Burn a NFT and remove its voting power.
    /// @param tokenId The ID of the NFT to burn.
    function burn(uint256 tokenId) external onlyDelegateCall {
        address owner = ownerOf(tokenId);
        if (
            msg.sender != owner &&
            getApproved[tokenId] != msg.sender &&
            !isApprovedForAll[owner][msg.sender]
        ) {
            // Allow minter to burn cards if the total voting power has not yet
            // been set (e.g. for initial crowdfunds) meaning the party has not
            // yet started.
            uint96 totalVotingPower = _governanceValues.totalVotingPower;
            if (totalVotingPower != 0 || !isAuthority[msg.sender]) {
                revert UnauthorizedToBurnError();
            }
        }

        uint96 votingPower = votingPowerByTokenId[tokenId].safeCastUint256ToUint96();
        mintedVotingPower -= votingPower;
        delete votingPowerByTokenId[tokenId];

        _adjustVotingPower(owner, -votingPower.safeCastUint96ToInt192(), address(0));

        _burn(tokenId);
    }

    /// @inheritdoc ERC721
    function transferFrom(
        address owner,
        address to,
        uint256 tokenId
    ) public override onlyDelegateCall {
        // Transfer voting along with token.
        _transferVotingPower(owner, to, votingPowerByTokenId[tokenId]);
        super.transferFrom(owner, to, tokenId);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(
        address owner,
        address to,
        uint256 tokenId
    ) public override onlyDelegateCall {
        // super.safeTransferFrom() will call transferFrom() first which will
        // transfer voting power.
        super.safeTransferFrom(owner, to, tokenId);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(
        address owner,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override onlyDelegateCall {
        // super.safeTransferFrom() will call transferFrom() first which will
        // transfer voting power.
        super.safeTransferFrom(owner, to, tokenId, data);
    }

    /// @notice Add a new authority.
    /// @dev Used in `AddAuthorityProposal`. Only the party itself can add
    ///      authorities to prevent it from being used anywhere else.
    function addAuthority(address authority) external onlySelf onlyDelegateCall {
        isAuthority[authority] = true;

        emit AuthorityAdded(authority);
    }

    /// @notice Relinquish the authority role.
    function abdicateAuthority() external onlyAuthority onlyDelegateCall {
        delete isAuthority[msg.sender];

        emit AuthorityRemoved(msg.sender);
    }

    function _delegateToRenderer() private view {
        _readOnlyDelegateCall(
            // Instance of IERC721Renderer.
            _GLOBALS.getAddress(LibGlobals.GLOBAL_GOVERNANCE_NFT_RENDER_IMPL),
            msg.data
        );
        assert(false); // Will not be reached.
    }
}
