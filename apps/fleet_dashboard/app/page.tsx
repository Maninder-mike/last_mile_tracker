'use client';

import dynamic from 'next/dynamic';
import { DeviceReading } from '@/utils/types';
import { useLiveReadings } from '@/hooks/useLiveReadings';
import AlertPanel from '@/components/AlertPanel';
import SidePanel from '@/components/SidePanel';
import { useState, useEffect } from 'react';
import { initSentry } from '@/utils/sentry.config';

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
  const [isDark, setIsDark] = useState<boolean>(true); // default to Dark Mode for premium IoT look

  useEffect(() => {
    // Initialize Sentry logging
    initSentry();
  }, []);

  const handleDeviceSelect = (id: string | null) => {
    setSelectedDeviceId(id);
  };

  return (
    <main className={`${isDark ? 'dark bg-slate-950' : 'bg-slate-50'} flex h-screen w-full overflow-hidden font-sans selection:bg-blue-500/30`}>
      <AlertPanel devices={devices} />

      <SidePanel
        devices={devices}
        selectedDeviceId={selectedDeviceId}
        onSelectDevice={handleDeviceSelect}
        isDark={isDark}
        onToggleTheme={() => setIsDark(!isDark)}
      />

      {/* Map Viewport & Overlay Controls */}
      <div className="flex-1 relative z-10 h-full w-full">
        {/* KPI Dashboard Header Overlay */}
        <div className="absolute top-6 left-6 right-6 flex justify-between items-center pointer-events-none z-20">
          {/* Left spacer so it doesn't overlap sidebar */}
          <div className="w-96" />
          
          {/* KPI Stats Grid */}
          <div className="flex-1 flex gap-4 ml-6 pointer-events-auto">
            {/* Stat 1 */}
            <div className="flex-1 glass p-4 rounded-2xl flex items-center justify-between shadow-lg border border-slate-200/50 dark:border-white/10 bg-white/70 dark:bg-slate-900/70 backdrop-blur-xl">
              <div>
                <span className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-wider block">Total Fleet</span>
                <span className="text-xl font-bold text-slate-800 dark:text-slate-100 font-mono leading-none mt-1 block">{devices.length}</span>
              </div>
              <div className="p-2.5 rounded-xl bg-blue-500/10 text-blue-500">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                </svg>
              </div>
            </div>
            {/* Stat 2 */}
            <div className="flex-1 glass p-4 rounded-2xl flex items-center justify-between shadow-lg border border-slate-200/50 dark:border-white/10 bg-white/70 dark:bg-slate-900/70 backdrop-blur-xl">
              <div>
                <span className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-wider block">Moving</span>
                <span className="text-xl font-bold text-slate-800 dark:text-slate-100 font-mono leading-none mt-1 block">{devices.filter(d => d.speed > 0).length}</span>
              </div>
              <div className="p-2.5 rounded-xl bg-emerald-500/10 text-emerald-500">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
            </div>
            {/* Stat 3 */}
            <div className="flex-1 glass p-4 rounded-2xl flex items-center justify-between shadow-lg border border-slate-200/50 dark:border-white/10 bg-white/70 dark:bg-slate-900/70 backdrop-blur-xl">
              <div>
                <span className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-wider block">Avg Temp</span>
                <span className="text-xl font-bold text-slate-800 dark:text-slate-100 font-mono leading-none mt-1 block">
                  {devices.length > 0 ? (devices.reduce((acc, curr) => acc + curr.temp, 0) / devices.length).toFixed(1) : 0} °C
                </span>
              </div>
              <div className="p-2.5 rounded-xl bg-orange-500/10 text-orange-500">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2m0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
            </div>
            {/* Stat 4 */}
            <div className="flex-1 glass p-4 rounded-2xl flex items-center justify-between shadow-lg border border-slate-200/50 dark:border-white/10 bg-white/70 dark:bg-slate-900/70 backdrop-blur-xl">
              <div>
                <span className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-wider block">Peak Shock</span>
                <span className="text-xl font-bold text-slate-800 dark:text-slate-100 font-mono leading-none mt-1 block">
                  {devices.length > 0 ? Math.max(...devices.map(d => d.shock)) : 0} G
                </span>
              </div>
              <div className="p-2.5 rounded-xl bg-red-500/10 text-red-500">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
              </div>
            </div>
          </div>
        </div>

        <DeckMap
          devices={devices}
          selectedDeviceId={selectedDeviceId}
          onSelectDevice={handleDeviceSelect}
          isDark={isDark}
        />

        {/* Floating Data Overlays */}
        <div className="absolute bottom-10 right-10 flex flex-col gap-3 pointer-events-none z-20">
          <div className="glass px-4 py-2 rounded-xl text-[10px] font-bold text-slate-500 uppercase tracking-widest shadow-lg border border-slate-200/50 dark:border-white/5 bg-white/80 dark:bg-slate-950/80">
            High-Performance Rendering Active
          </div>
          <div className="glass px-6 py-4 rounded-3xl shadow-2xl border border-slate-200/50 dark:border-white/5 bg-white/90 dark:bg-slate-950/90 pointer-events-auto">
            <h4 className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Network Status</h4>
            <div className="flex items-center gap-3">
              <div className="flex gap-1">
                {[1, 2, 3, 4].map(idx => (
                  <div key={idx} className={`w-1 h-3 rounded-full ${idx < 4 ? 'bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.4)]' : 'bg-slate-300 dark:bg-slate-700'}`} />
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
