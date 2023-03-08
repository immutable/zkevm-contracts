//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Token
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// Access Control
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../access/IERC173.sol";

// Utils
import "@openzeppelin/contracts/utils/Counters.sol";

contract ImmutableERC721PresetMinter is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    AccessControl,
    IERC173
{
    using Counters for Counters.Counter;

    ///     =====   State Variables  =====

    /// @dev Only MINTER_ROLE can invoke permissioned mint.
    bytes32 public constant MINTER_ROLE = bytes32("MINTER_ROLE");

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Common URIs for individual token URIs.
    string public baseURI;

    /// @dev the tokenId of the next NFT to be minted.
    Counters.Counter private nextTokenId;

    /// @dev Owner of the contract (defined for interopability with applications, e.g. storefront marketplace)
    address private _owner;

    ///     =====   Constructor  =====

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner_` address
     *
     * Sets the name and symbol for the collection
     * Sets the default admin to `owner`
     * Sets the `baseURI` and `tokenURI`
     */
    constructor (
        address owner_, 
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_ , 
        string memory contractURI_
        ) ERC721(name_, symbol_){
        // Initialize state variables
        _grantRole(DEFAULT_ADMIN_ROLE, owner_);
        _owner = owner_;
        baseURI = baseURI_;
        contractURI = contractURI_;

        // Increment nextTokenId to start from 1 (default is 0)
        nextTokenId.increment();

        // Emit events
        emit OwnershipTransferred(address(0), _owner);
    }

    ///     =====   View functions  =====

    /// @dev Returns the baseURI
    function _baseURI()
        internal
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return baseURI;
    }

    /// @dev Returns the supported interfaces
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Returns the current owner
    function owner() external view override returns (address) {
        return _owner;
    }

    ///     =====  External functions  =====

    /// @dev Allows admin to set the base URI
    function setBaseURI(string memory baseURI_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseURI = baseURI_;
    }

    /// @dev Allows admin to set the contract URI
    function setContractURI(string memory _contractURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        contractURI = _contractURI;
    }

    /// @dev Allows minter to mint `amount` to `to`
    function permissionedMint(address to, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        for (uint256 i; i < amount; i++) {
            _mintNextToken(to);
        }
    }

    /// @dev Allows admin grant `user` `MINTER` role
    function grantMinterRole(address user)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, user);
    }

    /// @dev Allows admin to update contract owner. Required that new oner has admin role
    function transferOwnership(address newOwner)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, newOwner),
            "New owner does not have default admin role"
        );
        require(_owner != newOwner, "New owner is currently owner");
        require(msg.sender == _owner, "Caller must be current owner");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /// @dev Internal hook implemented in {ERC721Enumerable}, required for totalSupply()
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @dev Internal function to mint a new token with the next token ID
    function _mintNextToken(address to) internal virtual returns (uint256){
        uint256 newTokenId = nextTokenId.current();
        super._mint(to, newTokenId);
        nextTokenId.increment();
        return newTokenId;
    }
}
