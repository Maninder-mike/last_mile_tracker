'use client';

import dynamic from 'next/dynamic';
import { DeviceReading } from '@/utils/types';
import { useLiveReadings } from '@/hooks/useLiveReadings';
import AlertPanel from '@/components/AlertPanel';

// Dynamically import map (no SSR)
const FleetMap = dynamic(() => import('@/components/FleetMap'), {
  ssr: false,
  loading: () => (
    <div className="flex h-full items-center justify-center bg-slate-100 dark:bg-slate-900 animate-pulse">
      <span className="text-slate-500 font-medium">Initializing Map...</span>
    </div>
  ),
});

// Mock Initial Data (will be replaced by initial fetch)
const INITIAL_DEVICES: DeviceReading[] = [];

export default function Home() {
  const devices = useLiveReadings(INITIAL_DEVICES);
  const activeCount = devices.filter(d => d.speed > 0).length;

  return (
    <main className="flex h-screen w-full bg-slate-50 dark:bg-slate-950 overflow-hidden font-sans selection:bg-accent/30">
      <AlertPanel devices={devices} />

      {/* Sidebar Panel */}
      <aside className="w-96 flex flex-col glass border-r z-20 shadow-2xl transition-all duration-300">
        <header className="p-8 space-y-2 border-b border-white/10">
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 rounded-full bg-accent animate-pulse shadow-[0_0_12px_rgba(59,130,246,0.5)]" />
            <h1 className="text-2xl font-black tracking-tight text-slate-900 dark:text-white uppercase italic">
              Fleet <span className="text-accent">Live</span>
            </h1>
          </div>
          <div className="flex justify-between items-end">
            <p className="text-slate-500 dark:text-slate-400 text-xs font-bold uppercase tracking-widest">Global Surveillance</p>
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-accent/10 text-accent font-bold">
              {activeCount}/{devices.length} MOVING
            </span>
          </div>
        </header>

        <section className="flex-1 overflow-y-auto custom-scrollbar p-4 space-y-4">
          <h2 className="px-2 text-[10px] font-black text-slate-400 uppercase tracking-tighter">Active Assets</h2>
          <div className="space-y-3">
            {devices.map((device) => (
              <div
                key={device.id}
                className="group relative p-5 rounded-2xl bg-white/50 dark:bg-white/5 border border-white/20 hover:border-accent/40 transition-all duration-300 cursor-pointer overflow-hidden shadow-sm hover:shadow-md active:scale-[0.98]"
              >
                {/* Background Glow on Hover */}
                <div className="absolute inset-0 bg-gradient-to-br from-accent/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />

                <div className="relative flex justify-between items-start">
                  <div>
                    <h3 className="font-bold text-slate-900 dark:text-slate-100 tracking-tight group-hover:text-accent transition-colors">
                      {device.id}
                    </h3>
                    <p className="text-[10px] text-slate-400 font-mono mt-0.5 italic">
                      {new Date(device.timestamp).toLocaleTimeString()}
                    </p>
                  </div>
                  <div className={`px-2 py-1 rounded-lg text-[9px] font-black tracking-widest uppercase transition-all duration-300 ${device.speed > 0
                    ? 'bg-green-500/10 text-green-500 border border-green-500/20 shadow-[0_0_10px_rgba(34,197,94,0.1)]'
                    : 'bg-slate-500/10 text-slate-500 border border-slate-500/20'
                    }`}>
                    {device.speed > 0 ? 'Tracking' : 'Standby'}
                  </div>
                </div>

                <div className="relative mt-5 grid grid-cols-2 gap-4">
                  <div className="space-y-1">
                    <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Velocity</p>
                    <p className="text-sm font-black text-slate-700 dark:text-slate-300">
                      {device.speed} <span className="text-[10px] font-normal text-slate-400 tracking-normal">km/h</span>
                    </p>
                  </div>
                  <div className="space-y-1">
                    <p className="text-[9px] font-bold text-slate-400 uppercase tracking-widest">Ambient Temp</p>
                    <p className="text-sm font-black text-slate-700 dark:text-slate-300">
                      {device.temp} <span className="text-[10px] font-normal text-slate-400">°C</span>
                    </p>
                  </div>
                </div>

                {device.shock > 500 && (
                  <div className="relative mt-4 pt-3 border-t border-red-500/20 flex items-center gap-2 text-red-500">
                    <div className="w-1.5 h-1.5 rounded-full bg-red-500 animate-ping" />
                    <span className="text-[10px] font-black uppercase tracking-widest italic">Critical Stress: {device.shock}g</span>
                  </div>
                )}
              </div>
            ))}
          </div>
        </section>

        <footer className="p-6 border-t border-white/10 bg-black/5 dark:bg-white/5">
          <p className="text-[9px] text-center text-slate-500 font-bold uppercase tracking-[0.2em]">
            Precision Telemetry v1.0.4
          </p>
        </footer>
      </aside>

      {/* Map Viewport */}
      <div className="flex-1 relative z-10">
        <FleetMap devices={devices} />

        {/* Floating Data Overlays */}
        <div className="absolute bottom-10 right-10 flex flex-col gap-3 pointer-events-none">
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
