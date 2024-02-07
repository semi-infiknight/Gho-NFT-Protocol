// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IGhoToken.sol";

contract FacilitatorContractWithInterest is AccessControl {

  bytes32 public constant NFT_MANAGER_ROLE = keccak256("NFT_MANAGER_ROLE");

  IGhoToken public ghoToken;
  AggregatorV3Interface internal nftFloorPriceFeed;
  AggregatorV3Interface internal ETHdataFeed;

  uint256 constant LOAN_TO_VALUE_PERCENT = 80;
  uint256 constant LIQUIDATION_BORROW_PERCENT = 80;
  uint256 public ANNUAL_INTEREST_RATE = 2;

  address public AaveTreasuryAddress;

  struct NFT {
    address nftContract;
    uint256 tokenId;
  }

  mapping(address => NFT[]) public nftDeposits; // Mapping of depositor addresses to lists of NFTDeposit structs
  mapping(address => uint256) public borrowedAmount; // Mapping of depositor addresses to amount borrowed
  mapping(address => address) public collections; // Mapping of Whitelisted Testnet NFT Collections to corresponding data feed contracts
  mapping(address => uint256) public liquidatedBorrowPower; // Mapping of depositor addresses to amount liquidated which is given as borrow power
  mapping(address => uint256) public accruedInterest; // Mapping of depositor addresses to amount of interest accrued
  mapping(address => uint256) public lastInterestUpdateTime; // Mapping of depositor addresses to last time interest was updated

  constructor(address _ghoToken, address admin) {
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setupRole(NFT_MANAGER_ROLE, admin);
    ghoToken = IGhoToken(_ghoToken);

    ETHdataFeed = AggregatorV3Interface(
      0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    );
  }

  function depositNFT(address nftContract, uint256 tokenId) external {
    require(collections[nftContract] != address(0), "NFT contract not whitelisted!");

    nftDeposits[msg.sender].push(NFT(nftContract, tokenId));
    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
  }

  function borrowGHO(uint256 amount)external {
    require(amount > 0, "Borrow amount must be greater than 0!");
    require(amount <= borrowPower(msg.sender), "Insufficient borrow power!");

    updateAccruedInterest(msg.sender);
    ghoToken.mint(msg.sender, amount);
    borrowedAmount[msg.sender] += amount;
  }

  function repayGho(uint256 amount) external {
    require(amount > 0, "Repayment amount must be greater than 0!");

    updateAccruedInterest(msg.sender);
    uint256 totalRepaymentNeeded = borrowedAmount[msg.sender] + accruedInterest[msg.sender];
    require(totalRepaymentNeeded >= amount, "Repayment exceeds total debt");

    uint256 interestPart = accruedInterest[msg.sender];
    if (amount >= interestPart) {
      // Send interest to Aave Treasury and adjust amount
      if (interestPart > 0) {
        ghoToken.transferFrom(address(this), AaveTreasuryAddress, interestPart);
        accruedInterest[msg.sender] = 0;
        amount -= interestPart;
      }

      // Now repay the principal
      if (amount > 0) {
        ghoToken.burn(amount);
        borrowedAmount[msg.sender] -= amount;
      }
    } else {
      // If the amount is less than the accrued interest, pay only the interest
      ghoToken.transferFrom(msg.sender, AaveTreasuryAddress, amount);
      accruedInterest[msg.sender] -= amount;
    }
  }

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

  function removeNFTFromDeposits(address user, uint256 index) internal {
    NFT[] storage userDeposits = nftDeposits[user];
    require(index < userDeposits.length, "Invalid index");

    userDeposits[index] = userDeposits[userDeposits.length - 1];
    userDeposits.pop();
  }

  function whitelistCollection(address nftAddress, address priceFeedAddress) public {
    require(hasRole(NFT_MANAGER_ROLE, msg.sender), "Caller does not have NFT_MANAGER_ROLE");
    collections[nftAddress] = priceFeedAddress;
  }

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
    uint256 interestAmount = calculateInterest(user);
    totalBorrowPower -= (borrowedAmount[user] + interestAmount);
    return totalBorrowPower;
  }

  function setTreasuryAddress(address aaveTreasuryAddress) public {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller does not have DEFAULT_ADMIN_ROLE");
    AaveTreasuryAddress = aaveTreasuryAddress;
  }

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

  function updateAccruedInterest(address borrower) internal {
    uint256 interestAmount = calculateInterest(borrower);
    accruedInterest[borrower] += interestAmount;
    lastInterestUpdateTime[borrower] = block.timestamp;
  }

  function calculateInterest(address borrower) internal view returns (uint256) {
    if (lastInterestUpdateTime[borrower] == 0) {
      return 0;
    }
    uint256 timeElapsed = block.timestamp - lastInterestUpdateTime[borrower];
    uint256 interestAmount = borrowedAmount[borrower] * ANNUAL_INTEREST_RATE * timeElapsed / (365 days * 100);
    return interestAmount;
  }

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
