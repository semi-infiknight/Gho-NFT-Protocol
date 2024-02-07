import React, { useState } from 'react';
import { useAccount, useContractWrite } from 'wagmi';
import { ethers } from 'ethers';
import FacilitatorContractABI from '.././FacilitatorContractABI.json';
import { Button } from "@/components/ui/button";

const facilitatorContractAddress = '0x9EA2a6f7D0Ea4Af488aD6962578848e3880FA5d7';

function Borrow({ amount }: { amount: string }) {
  const { address } = useAccount();
  const [isBorrowInitiated, setIsBorrowInitiated] = useState(false);

  const handleBorrowGHO = async () => {
    if (amount && !isBorrowInitiated) {
      const amountInWei = ethers.parseUnits(amount, 18);
      await borrowGHO({ args: [amountInWei] });
      setIsBorrowInitiated(true);
    }
  };

  const { write: borrowGHO, isLoading } = useContractWrite({
    address: facilitatorContractAddress, 
    abi: FacilitatorContractABI,
    functionName: 'borrowGHO',
  });

  return (
    <Button onClick={handleBorrowGHO} disabled={isLoading || isBorrowInitiated}>Borrow</Button>
  );
}

export default Borrow;
