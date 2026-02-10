'use client';

import { DeviceReading } from '@/utils/types';
import { useState, useMemo } from 'react';

interface SidePanelProps {
    devices: DeviceReading[];
    selectedDeviceId: string | null;
    onSelectDevice: (id: string) => void;
}

export default function SidePanel({ devices, selectedDeviceId, onSelectDevice }: SidePanelProps) {
    const [search, setSearch] = useState('');

    const filteredDevices = useMemo(() => {
        if (!search) return devices;
        return devices.filter(d => d.id.toLowerCase().includes(search.toLowerCase()));
    }, [devices, search]);

    const activeCount = devices.filter(d => d.speed > 0).length;

    return (
        <aside className="w-96 flex flex-col glass border-r z-20 shadow-2xl transition-all duration-300 bg-white/80 dark:bg-slate-950/80 backdrop-blur-xl">
            {/* Header */}
            <header className="p-6 space-y-4 border-b border-slate-200 dark:border-white/10">
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <div className="w-3 h-3 rounded-full bg-blue-500 animate-pulse" />
                        <div className="absolute inset-0 w-3 h-3 rounded-full bg-blue-500 blur-sm opacity-50 animate-ping" />
                    </div>
                    <h1 className="text-xl font-bold tracking-tight text-slate-900 dark:text-white uppercase">
                        Last Mile <span className="text-blue-500">Tracker</span>
                    </h1>
                </div>

                {/* Search */}
                <div className="relative group">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <svg className="h-4 w-4 text-slate-400 group-focus-within:text-blue-500 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                        </svg>
                    </div>
                    <input
                        type="text"
                        className="block w-full pl-10 pr-3 py-2 border border-slate-200 dark:border-slate-700 rounded-xl leading-5 bg-slate-50 dark:bg-slate-900/50 text-slate-900 dark:text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 sm:text-sm transition-all shadow-sm"
                        placeholder="Search assets..."
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>

                {/* Stats */}
                <div className="flex items-center justify-between text-xs font-medium text-slate-500 dark:text-slate-400">
                    <span className="uppercase tracking-wider">Active Assets</span>
                    <span className="px-2 py-0.5 rounded-full bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20">
                        {activeCount} / {devices.length} ONLINE
                    </span>
                </div>
            </header>

            {/* Device List */}
            <div className="flex-1 overflow-y-auto custom-scrollbar p-4 space-y-3">
                {filteredDevices.map((device) => {
                    const isSelected = selectedDeviceId === device.id;
                    const isMoving = device.speed > 0;
                    const isHighShock = device.shock > 500;

                    return (
                        <div
                            key={device.id}
                            onClick={() => onSelectDevice(device.id)}
                            className={`
                                group relative p-4 rounded-xl border transition-all duration-200 cursor-pointer
                                ${isSelected
                                    ? 'bg-blue-500/5 border-blue-500 shadow-md ring-1 ring-blue-500/20'
                                    : 'bg-white/50 dark:bg-slate-900/30 border-slate-200 dark:border-white/5 hover:border-blue-400/50 hover:shadow-sm'
                                }
                            `}
                        >
                            <div className="flex justify-between items-start mb-2">
                                <div>
                                    <h3 className={`font-semibold text-sm tracking-tight ${isSelected ? 'text-blue-600 dark:text-blue-400' : 'text-slate-900 dark:text-slate-100'}`}>
                                        {device.id}
                                    </h3>
                                    <p className="text-[10px] text-slate-500 dark:text-slate-400 font-mono mt-0.5">
                                        {new Date(device.timestamp).toLocaleTimeString()}
                                    </p>
                                </div>
                                <div className={`
                                    w-2 h-2 rounded-full
                                    ${isMoving ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]' : 'bg-slate-300 dark:bg-slate-600'}
                                `} />
                            </div>

                            <div className="grid grid-cols-2 gap-2 mt-3">
                                <div className="bg-slate-100 dark:bg-white/5 rounded-lg p-2">
                                    <p className="text-[9px] font-bold text-slate-400 uppercase">Speed</p>
                                    <p className="text-xs font-bold text-slate-700 dark:text-slate-200">
                                        {device.speed} <span className="font-normal text-[10px] opacity-70">km/h</span>
                                    </p>
                                </div>
                                <div className="bg-slate-100 dark:bg-white/5 rounded-lg p-2">
                                    <p className="text-[9px] font-bold text-slate-400 uppercase">Shock</p>
                                    <p className={`text-xs font-bold ${isHighShock ? 'text-red-500' : 'text-slate-700 dark:text-slate-200'}`}>
                                        {device.shock} <span className="font-normal text-[10px] opacity-70">g</span>
                                    </p>
                                </div>
                            </div>

                            {/* Selection Indicator */}
                            {isSelected && (
                                <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-blue-500 rounded-r-full" />
                            )}
                        </div>
                    );
                })}

                {filteredDevices.length === 0 && (
                    <div className="text-center py-12">
                        <p className="text-sm text-slate-400">No assets found matching &quot;{search}&quot;</p>
                    </div>
                )}
            </div>

            <footer className="p-4 border-t border-slate-200 dark:border-white/10 bg-slate-50 dark:bg-black/20">
                <div className="flex justify-between items-center text-[10px] text-slate-400 font-medium">
                    <span>SYSTEM STATUS</span>
                    <span className="text-green-500 flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
                        OPERATIONAL
                    </span>
                </div>
            </footer>
        </aside>
    );
}
