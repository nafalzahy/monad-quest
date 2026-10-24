// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @title Monad Quest - game level-up dengan NFT badge on-chain
contract MonadQuest is ERC721 {
    using Strings for uint256;

    mapping(address => uint256) public xp;
    mapping(address => mapping(uint8 => uint256)) public badgeOf; // pemain => level => tokenId
    mapping(uint256 => uint8) public badgeLevel;
    mapping(address => bool) private registered;
    address[] private players;
    uint256 public totalClicks;
    uint256 private nextId = 1;

    event Clicked(address indexed player, uint256 xp);
    event LevelUp(address indexed player, uint8 level, uint256 tokenId);

    constructor() ERC721("Monad Quest Badge", "MQB") {}

    function levelOf(uint256 _xp) public pure returns (uint8) {
        if (_xp >= 35) return 5;
        if (_xp >= 20) return 4;
        if (_xp >= 10) return 3;
        if (_xp >= 3) return 2;
        return 1;
    }

    /// XP untuk level berikutnya (0 = sudah level maksimal)
    function nextLevelXp(uint256 _xp) public pure returns (uint256) {
        if (_xp < 3) return 3;
        if (_xp < 10) return 10;
        if (_xp < 20) return 20;
        if (_xp < 35) return 35;
        return 0;
    }

    function click() external {
        if (!registered[msg.sender]) {
            registered[msg.sender] = true;
            players.push(msg.sender);
        }
        uint256 oldXp = xp[msg.sender];
        uint256 newXp = oldXp + 1;
        xp[msg.sender] = newXp;
        totalClicks++;
        emit Clicked(msg.sender, newXp);

        uint8 lvl = levelOf(newXp);
        if (lvl > levelOf(oldXp)) {
            uint256 id = nextId++;
            badgeLevel[id] = lvl;
            badgeOf[msg.sender][lvl] = id;
            _mint(msg.sender, id);
            emit LevelUp(msg.sender, lvl, id);
        }
    }

    function totalPlayers() external view returns (uint256) {
        return players.length;
    }

    /// 5 pemain dengan XP tertinggi
    function getLeaderboard() external view returns (address[5] memory addrs, uint256[5] memory scores) {
        for (uint256 i = 0; i < players.length; i++) {
            address p = players[i];
            uint256 s = xp[p];
            for (uint256 j = 0; j < 5; j++) {
                if (s > scores[j]) {
                    for (uint256 k = 4; k > j; k--) {
                        scores[k] = scores[k - 1];
                        addrs[k] = addrs[k - 1];
                    }
                    scores[j] = s;
                    addrs[j] = p;
                    break;
                }
            }
        }
    }

    // ===== NFT: metadata dan gambar dibuat langsung on-chain =====

    function tierName(uint8 l) public pure returns (string memory) {
        if (l == 2) return "Bronze";
        if (l == 3) return "Silver";
        if (l == 4) return "Gold";
        return "Diamond";
    }

    function _colors(uint8 l) internal pure returns (string memory, string memory) {
        if (l == 2) return ("#cd7f32", "#8c4f14");
        if (l == 3) return ("#e5e7eb", "#8b93a1");
        if (l == 4) return ("#ffd700", "#d18b00");
        return ("#7df9ff", "#836ef9");
    }

    function _svg(uint256 id, uint8 l) internal pure returns (string memory) {
        (string memory c1, string memory c2) = _colors(l);
        string memory defs = string.concat(
            '<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="',
            c1, '"/><stop offset="1" stop-color="', c2, '"/></linearGradient></defs>'
        );
        string memory body = string.concat(
            '<rect width="400" height="400" rx="28" fill="#14101f"/>',
            '<circle cx="200" cy="170" r="105" fill="url(#g)"/>',
            '<text x="200" y="198" font-size="80" font-weight="bold" text-anchor="middle" fill="#14101f" font-family="Arial">L',
            uint256(l).toString(), "</text>"
        );
        string memory footer = string.concat(
            '<text x="200" y="330" font-size="34" font-weight="bold" text-anchor="middle" fill="#fff" font-family="Arial">',
            tierName(l), ' Badge</text><text x="200" y="368" font-size="18" text-anchor="middle" fill="#a79bd6" font-family="Arial">Monad Quest #',
            id.toString(), "</text>"
        );
        return string.concat('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">', defs, body, footer, "</svg>");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        uint8 l = badgeLevel[tokenId];
        string memory head = string.concat(
            '{"name":"Monad Quest ', tierName(l), " Badge #", tokenId.toString(),
            '","description":"Badge on-chain dari game Monad Quest. Level ', uint256(l).toString(), '.",'
        );
        string memory attrs = string.concat(
            '"attributes":[{"trait_type":"Tier","value":"', tierName(l),
            '"},{"trait_type":"Level","value":', uint256(l).toString(), "}],"
        );
        string memory image = string.concat(
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(_svg(tokenId, l))), '"}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(string.concat(head, attrs, image))));
    }
}