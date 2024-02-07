import React, { useState } from 'react';
import { useAccount, useContractWrite, useWaitForTransaction } from 'wagmi';
import FacilitatorContractABI from '.././FacilitatorContractABI.json';
import { Button } from "@/components/ui/button";

const facilitatorContractAddress = '0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7';

interface NFT {
  collectionName: string,
  name: string,
  description: string,
  symbol: string,
  image: string,
  contractAddress: string,
  tokenId: string,
  tokenType: string
}

function NFTDeposited({ nft }: { nft: NFT}) {
  const { address } = useAccount();
  const [isWithdrawInitiated, setIsWithdrawInitiated] = useState(false);

  const { write: withdrawNFT, isLoading: isWithdrawLoading } = useContractWrite({
    address: facilitatorContractAddress, 
    abi: FacilitatorContractABI,
    functionName: 'withdrawNFT',
    args: [nft.contractAddress, nft.tokenId]
  });

  const handleWithdraw = async () => {
    console.log("Withdrawing NFT: ", nft);
    if (!isWithdrawInitiated) {
      await withdrawNFT();
      setIsWithdrawInitiated(true);
    }
  };

  const isButtonDisabled = isWithdrawLoading || isWithdrawInitiated;

  return (
    <Button variant='outline' onClick={handleWithdraw} disabled={isButtonDisabled}>Withdraw</Button>
  );
}

export default NFTDeposited;
