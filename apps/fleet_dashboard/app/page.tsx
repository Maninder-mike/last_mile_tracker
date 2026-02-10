'use client';

import dynamic from 'next/dynamic';
import { DeviceReading } from '@/utils/types';
import { useLiveReadings } from '@/hooks/useLiveReadings';
import AlertPanel from '@/components/AlertPanel';
import SidePanel from '@/components/SidePanel';
import { useState } from 'react';

// Dynamically import map (no SSR)
// Dynamically import map (no SSR)
const DeckMap = dynamic(() => import('@/components/DeckMap'), {
  ssr: false,
  loading: () => <div className="h-full w-full bg-slate-50 dark:bg-slate-950 animate-pulse" />
});

// Mock Initial Data (will be replaced by initial fetch)
const INITIAL_DEVICES: DeviceReading[] = [];

export default function Home() {
  const devices = useLiveReadings(INITIAL_DEVICES);
  const [selectedDeviceId, setSelectedDeviceId] = useState<string | null>(null);

  const handleDeviceSelect = (id: string) => {
    setSelectedDeviceId(id);
  };

  return (
    <main className="flex h-screen w-full bg-slate-50 dark:bg-slate-950 overflow-hidden font-sans selection:bg-accent/30">
      <AlertPanel devices={devices} />

      <SidePanel
        devices={devices}
        selectedDeviceId={selectedDeviceId}
        onSelectDevice={handleDeviceSelect}
      />

      {/* Map Viewport */}
      <div className="flex-1 relative z-10 h-full w-full">
        <DeckMap
          devices={devices}
          selectedDeviceId={selectedDeviceId}
          onSelectDevice={handleDeviceSelect}
        />

        {/* Floating Data Overlays */}
        <div className="absolute bottom-10 right-10 flex flex-col gap-3 pointer-events-none">
          <div className="glass px-4 py-2 rounded-xl text-xs font-bold text-slate-500 uppercase tracking-widest shadow-lg">
            High-Performance Rendering Active
          </div>
          <div className="glass px-6 py-4 rounded-3xl shadow-2xl border-white/20 pointer-events-auto">
            <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Network Status</h4>
            <div className="flex items-center gap-3">
              <div className="flex gap-1">
                {[1, 2, 3, 4].map(idx => (
                  <div key={idx} className={`w-1 h-3 rounded-full ${idx < 4 ? 'bg-accent shadow-[0_0_8px_rgba(59,130,246,0.4)]' : 'bg-slate-300 dark:bg-slate-700'}`} />
                ))}
              </div>
              <span className="text-xs font-black text-slate-900 dark:text-slate-100 tracking-tighter italic">SUPABASE_SECURE_LINK</span>
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
