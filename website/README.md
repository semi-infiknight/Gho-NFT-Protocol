# Ghost NFT Protocol

## NFT Deposits
Collateral Utilization: Users can deposit their NFTs from approved collections. These NFTs serve as collateral, enabling users to engage in various financial activities within the protocol.
Dynamic Collection Support: The protocol supports multiple NFT collections, which are whitelisted and managed through smart contract functions.
GHO Token Integration
Token Minting and Borrowing: Users can borrow/mint GHO tokens against their NFT collateral. This feature positions the protocol as a facilitator in the Aave ecosystem, providing a novel source of GHO liquidity.
Real-Time Borrow Power Calculation: Borrow power is dynamically calculated based on the current market value of the deposited NFTs using Chainlink's NFT Price Feed, ensuring a responsive and fair borrowing system.
## Risk Management and Liquidation
Liquidation Process: To manage risk effectively, the protocol includes a liquidation process. If a user's borrow power falls below a certain threshold due to market fluctuations, their NFTs can be liquidated to cover the deficit, and in return the user will be given borrow power to mint additional GHO tokens, and this borrow power will be calculated by subtracting the debt from the price of the NFT and deducting additional 20% as penalty.
Aave Treasury Integration: Liquidated NFTs are transferred to the Aave Treasury, ensuring a secure and compliant risk management process. Additionally, any accrued interest from the borrowed GHO tokens is transferred to the Aave Treasury, ensuring a balanced and sustainable ecosystem.

### LFGHO Submission: [Ghost NFT Protocol](https://ethglobal.com/showcase/ghost-nft-protocol-sy40u)
