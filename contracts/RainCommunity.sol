pragma solidity 0.6.7;

import "@openzeppelin/contracts-ethereum-package/contracts/Initializable.sol";
import "hardlydifficult-eth/contracts/proxies/Clone2Factory.sol";
import "./CommunityRoles.sol";

contract RainCommunity is
  Initializable,
  CommunityRoles
{
  using Clone2Factory for address;

  struct Community {
    bool deployed;
  }

  mapping(address => Community) public childCommunities; // this needs to be an array to access communities in graph??

  string private _name;
  string private _symbol;

  address public parentCommunity;

  address public communityTemplate;

  event NewCommunity(address indexed creator, address indexed newCommunityAddress);
  event SetCommunityTemplate(address communityTemplate);

  function initialize(
    address _parentCommunity,
    address _owner,
    string memory name,
    string memory symbol
  ) public
    initializer
  {
    _initializeComunityRoles(_owner);
    _name = name;
    _symbol = symbol;
    parentCommunity = _parentCommunity;
  }

  /**
   * @dev Returns the name of the community.
   */
  function name() public view returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the community.
   */
  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function setCommunityTemplate(
    address payable _communityTemplate
  ) external
    onlyOwner()
  {
    RainCommunity(_communityTemplate).initialize(
      address(this), address(0), "", ""
    );

    communityTemplate = _communityTemplate;

    emit SetCommunityTemplate(_communityTemplate);
  }

  function createCommunity(
    string memory _newName,
    string memory _newSymbol,
    bytes12 _salt
  ) public
  {
    _createCommunity(_newName, _newSymbol, _salt);
  }

  function _createCommunity(
    string memory _newName,
    string memory _newSymbol,
    bytes12 _salt
  ) private
  {
    bytes32 salt;

    assembly {
      let pointer := mload(0x40)
      mstore(pointer, shl(96, caller()))
      mstore(add(pointer, 0x14), _salt)
      salt := mload(pointer)
    }

    address payable newCommunity = address(uint160(address(communityTemplate).createClone2(salt)));
    RainCommunity(newCommunity).initialize(address(this), msg.sender, _newName, _newSymbol);

    childCommunities[newCommunity] = Community({ deployed: true });
    emit NewCommunity(msg.sender, newCommunity);
  }
}
