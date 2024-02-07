'use client'
import * as React from 'react';
import Link from 'next/link';

import { Button } from '@/components/ui/button'; // Importing Button component
import { Sidebar } from '@/components/sidebar';
import { SidebarFooter } from '@/components/sidebar-footer';
import { ThemeToggle } from '@/components/theme-toggle';
import { ConnectKitButton } from "connectkit";

export function Header() {
  return (
    <header className="sticky top-0 z-50 flex items-center justify-between w-full h-16 px-4 border-b shrink-0 bg-gradient-to-b from-background/10 via-background/50 to-background/80 backdrop-blur-xl">
      <div className="flex items-center">
        <Sidebar>
          <React.Suspense fallback={<div className="flex-1 overflow-auto" />}>
            {/* @ts-ignore */}
          </React.Suspense>
          <SidebarFooter>
            <ThemeToggle />
          </SidebarFooter>
        </Sidebar>
      </div>
      {/* Centered Buttons */}
      <div className="flex-1 flex justify-center items-center space-x-2">
        <Link href="/dashboard" passHref>
          <Button>Dashboard</Button>
        </Link>
        <Link href="/governance" passHref>
          <Button>Governance</Button>
        </Link>
        <Link href="/market" passHref>
          <Button>Market</Button>
        </Link>
        <Link href="/stake" passHref>
          <Button>Stake</Button>
        </Link>
        {/* Assuming 'More' does not navigate to a specific page but might open a dropdown or perform another action */}
        <Button>More</Button>
      </div>
      <div className="flex items-center justify-end space-x-2">
        <ConnectKitButton />
      </div>
    </header>
  );
}
