// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./NFTDescriptor.sol";

contract GenArtNFT is ERC721 {
    bool public mintable;
    uint16 public dimensionLimits = 0x6166;
    uint24 public totalSupply;
    address public tokenDescriptor;
    address public owner;
    uint128[65535] public tokenData;

    uint256 internal constant MAX_SUPPLY = 3000;

    constructor() ERC721(unicode"███", unicode"███") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setInfo(string calldata _name, string calldata _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;
    }

    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
    }

    function setDimensionLimit(uint16 _dimensionLimits) external onlyOwner {
        dimensionLimits = _dimensionLimits;
    }

    // only in case we need to patch the art logic
    function setTokenDescriptor(address _descriptor) external onlyOwner {
        tokenDescriptor = _descriptor;
    }

    function mint(uint128 data) external {
        require(mintable, "Minting disabled");
        uint256 dimLimits = dimensionLimits;
        uint256 ncol = data & 0x7;
        uint256 nrow = (data & 0x38) >> 3;
        require(
            ncol >= (dimLimits & 0xF) &&
                ncol <= ((dimLimits >> 4) & 0xF) &&
                nrow >= ((dimLimits >> 8) & 0xF) &&
                nrow <= ((dimLimits >> 12) & 0xF),
            "Invalid Data"
        );
        uint256 tokenId = ++totalSupply;
        require(tokenId <= MAX_SUPPLY, "Exceed max supply");
        uint256 rand = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, tokenId))) % 8;
        tokenData[tokenId] = (uint128(rand) << 120) | uint120(data);
        _mint(msg.sender, tokenId);
    }

    function _getData(uint256 tokenId)
        internal
        view
        returns (
            uint256 ncol,
            uint256 nrow,
            uint256 result,
            uint256 salt
        )
    {
        uint256 data = tokenData[tokenId];
        require(data != 0, "Token not exists");
        ncol = data & 0x7;
        nrow = (data & 0x38) >> 3;
        result = uint120(data) >> 6;
        salt = data;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenDescriptor != address(0)) {
            return IERC721Descriptor(tokenDescriptor).tokenURI(tokenId);
        }
        (uint256 ncol, uint256 nrow, uint256 result, uint256 salt) = _getData(tokenId);
        return NFTDescriptor.constructTokenURI(tokenId, result, ncol, nrow, salt, name);
    }

    function imageURI(uint256 tokenId) external view returns (string memory) {
        (uint256 ncol, uint256 nrow, uint256 result, uint256 salt) = _getData(tokenId);
        return NFTDescriptor.makeImageURI(result, ncol, nrow, salt);
    }

    function squares(uint256 tokenId) external view returns (string memory) {
        (uint256 ncol, uint256 nrow, uint256 result, ) = _getData(tokenId);
        return NFTDescriptor.makeSquares(result, ncol, nrow);
    }
}

interface IERC721Descriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
