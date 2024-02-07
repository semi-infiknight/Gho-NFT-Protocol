import React, { useState, useEffect } from 'react';
import { useAccount, useContractWrite, useSendTransaction, useWaitForTransaction } from 'wagmi';
import { ethers } from 'ethers';
import FacilitatorContractABI from '.././FacilitatorContractABI.json';
import GHOTokenABI from '.././GHOTokenABI.json';
import { Button } from "@/components/ui/button";

const facilitatorContractAddress = '0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7';
const ghoTokenAddress = '0x135512F8864B91015C3Bf913215d91c0317Ae91E';

function Repay({ amount }: { amount: string }) {
  const { address } = useAccount();
  const [transferTxHash, setTransferTxHash] = useState<`0x${string}` | undefined>(undefined);
  const [isRepayInitiated, setIsRepayInitiated] = useState(false);

  const { write: transferGHO, isLoading: isTransferLoading } = useContractWrite({
    address: ghoTokenAddress, 
    abi: GHOTokenABI,
    functionName: 'transfer',
    onSuccess(data) {
      setTransferTxHash(data.hash as `0x${string}`);
    },
  });

  const { data: transferTxData, isLoading: isTransferTxLoading } = useWaitForTransaction({ 
    hash: transferTxHash,
    enabled: !!transferTxHash,
  });

  const { write: repayGHO, isLoading: isRepayLoading } = useContractWrite({
    address: facilitatorContractAddress, 
    abi: FacilitatorContractABI,
    functionName: 'repayGho',
  });

  useEffect(() => {
    if (transferTxData && !isRepayInitiated) {
      const amountInWei = ethers.parseUnits(amount, 18);
      repayGHO({ args: [amountInWei] });
      setIsRepayInitiated(true);
    }
  }, [transferTxData, isRepayInitiated, repayGHO, amount]);

  const handleRepayGHO = async () => {
    if (!amount || isNaN(Number(amount)) || Number(amount) <= 0) {
      console.error("Invalid amount for repayment");
      return;
    }

    const amountInWei = ethers.parseUnits(amount, 18);

    if (!isTransferLoading && !isTransferTxLoading && !isRepayInitiated) {
      await transferGHO({ args: [facilitatorContractAddress, amountInWei] })
    }
  };

  return (
    <Button onClick={handleRepayGHO} disabled={isTransferLoading || isTransferTxLoading || isRepayLoading}>Repay</Button>
  );
}

export default Repay;
