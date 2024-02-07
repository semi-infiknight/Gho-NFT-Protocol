// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IGhoToken.sol";

contract FacilitatorContract is AccessControl {

  bytes32 public constant NFT_MANAGER_ROLE = keccak256("NFT_MANAGER_ROLE");

  // Interface for GHO token and Chainlink oracles for price feeds
  IGhoToken public ghoToken;
  AggregatorV3Interface internal nftFloorPriceFeed;
  AggregatorV3Interface internal ETHdataFeed;

  uint256 constant LOAN_TO_VALUE_PERCENT = 80;
  uint256 constant LIQUIDATION_BORROW_PERCENT = 80;

  // Address of the Aave Treasury for liquidation handling
  address public AaveTreasuryAddress;

  struct NFT {
    address nftContract;
    uint256 tokenId;
  }

  mapping(address => NFT[]) public nftDeposits; // Mapping of depositor addresses to lists of NFTDeposit structs
  mapping(address => uint256) public borrowedAmount; // Mapping of depositor addresses to amount borrowed
  mapping(address => address) public collections; // Mapping of Whitelisted Testnet NFT Collections to corresponding data feed contracts
  mapping(address => uint256) public liquidatedBorrowPower; // Mapping of depositor addresses to amount liquidated which is given as borrow power

  // Constructor to initialize GHO token, roles, and price feeds
  constructor(address _ghoToken, address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(NFT_MANAGER_ROLE, admin);
    ghoToken = IGhoToken(_ghoToken);

    ETHdataFeed = AggregatorV3Interface(
      0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    );
  }

  // Function for users to deposit their NFTs as collateral
  function depositNFT(address nftContract, uint256 tokenId) external {
    require(collections[nftContract] != address(0), "NFT contract not whitelisted!");

    nftDeposits[msg.sender].push(NFT(nftContract, tokenId));
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
  }

  // Function to borrow GHO tokens against the NFT collateral
  function borrowGHO(uint256 amount)external {
    require(amount > 0, "Borrow amount must be greater than 0!");
    require(amount <= borrowPower(msg.sender), "Insufficient borrow power!");

    ghoToken.mint(msg.sender, amount);
    borrowedAmount[msg.sender] += amount;
  }

  // Function to repay borrowed GHO tokens
  function repayGho(uint256 amount) external {
    require(amount > 0, "Repayment amount must be greater than 0!");
    require(borrowedAmount[msg.sender] >= amount, "Cannot repay more than borrowed!");

    ghoToken.burn(amount);
    borrowedAmount[msg.sender] -= amount;
  }

  // Function to withdraw deposited NFTs from the contract
  function withdrawNFT(address nftContract, uint256 tokenId) external {
    uint256 nftValueEth = uint256(getNFTPrice(nftContract));
    uint256 ethUsdPrice = uint256(getETHDataFeed());
    uint256 nftValueGho = (nftValueEth * ethUsdPrice) / 1e8;
    uint256 loanedAmountGho = (nftValueGho * LOAN_TO_VALUE_PERCENT) / 100;
    require(borrowPower(msg.sender) >= loanedAmountGho, "Insufficient BorrowPower after withdrawal");

    bool isNFTDeposited = false;
    uint256 nftIndex;
    NFT[] storage userDeposits = nftDeposits[msg.sender];
    for (uint256 i = 0; i < userDeposits.length; i++) {
      if (userDeposits[i].nftContract == nftContract && userDeposits[i].tokenId == tokenId) {
        isNFTDeposited = true;
        nftIndex = i;
        break;
      }
    }

    require(isNFTDeposited, "NFT not deposited by user");

    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    removeNFTFromDeposits(msg.sender, nftIndex);
  }

  // Internal function to remove an NFT from a user's deposit list
  function removeNFTFromDeposits(address user, uint256 index) internal {
    NFT[] storage userDeposits = nftDeposits[user];
    require(index < userDeposits.length, "Invalid index");

    userDeposits[index] = userDeposits[userDeposits.length - 1];
    userDeposits.pop();
  }

  // Function to whitelist a new NFT collection and its corresponding price feed
  function whitelistCollection(address nftAddress, address priceFeedAddress) public {
    require(hasRole(NFT_MANAGER_ROLE, msg.sender), "Caller does not have NFT_MANAGER_ROLE");
    collections[nftAddress] = priceFeedAddress;
  }

  // Function to calculate the current borrow power of a user
  function borrowPower(address user) public view returns (uint256) {
    uint256 totalBorrowPower = liquidatedBorrowPower[user];
    for (uint256 i = 0; i < nftDeposits[user].length; i++) {
      NFT storage nft = nftDeposits[user][i];
      uint256 nftValueEth = uint256(getNFTPrice(nft.nftContract));
      uint256 ethUsdPrice = uint256(getETHDataFeed());
      uint256 nftValueGho = (nftValueEth * ethUsdPrice) / 1e8;
      uint256 loanAmountGho = (nftValueGho * LOAN_TO_VALUE_PERCENT) / 100;
      totalBorrowPower += loanAmountGho;
    }
    totalBorrowPower -= borrowedAmount[user];
    return totalBorrowPower;
  }

  // Function to set the Aave Treasury address by the admin
  function setTreasuryAddress(address aaveTreasuryAddress) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller does not have DEFAULT_ADMIN_ROLE");
    AaveTreasuryAddress = aaveTreasuryAddress;
  }

  // Function to liquidate a user's NFT in case of borrow power deficiency
  function liquidateUser(address user) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller does not have DEFAULT_ADMIN_ROLE");
    require(borrowPower(user) < 0, "User's borrow power is not negative");

    if(nftDeposits[user].length > 0) {
      NFT storage nft = nftDeposits[user][0];

      uint256 nftValueEth = uint256(getNFTPrice(nft.nftContract));
      uint256 ethUsdPrice = uint256(getETHDataFeed());
      uint256 nftValueGho = (nftValueEth * ethUsdPrice) / 1e8;
      uint256 loanAmountGho = (nftValueGho * LIQUIDATION_BORROW_PERCENT) / 100;

      liquidatedBorrowPower[user] += loanAmountGho;

      IERC721(nft.nftContract).transferFrom(address(this), AaveTreasuryAddress, nft.tokenId);
      removeNFTFromDeposits(user, 0);
    }
  }

  // Public view functions to get the current NFT price
  function getNFTPrice(address nftContract) public view returns (int) {
    require(collections[nftContract] != address(0), "NFT contract not whitelisted!");

    AggregatorV3Interface nftPriceFeed = AggregatorV3Interface(collections[nftContract]);
    (
      /* uint80 roundID */,
      int nftFloorPrice,
      /* uint startedAt */,
      /* uint timeStamp */,
      /* uint80 answeredInRound */
    ) = nftPriceFeed.latestRoundData();
    return nftFloorPrice;
  }

  // Public view function to get the current ETH price in USD
  function getETHDataFeed() public view returns (int) {
    (
      /* uint80 roundID */,
      int answer,
      /*uint startedAt*/,
      /*uint timeStamp*/,
      /*uint80 answeredInRound*/
    ) = ETHdataFeed.latestRoundData();
    return answer;
  }
}
