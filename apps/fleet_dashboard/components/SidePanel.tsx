'use client';

import { DeviceReading } from '@/utils/types';
import { useState, useMemo } from 'react';

interface SidePanelProps {
    devices: DeviceReading[];
    selectedDeviceId: string | null;
    onSelectDevice: (id: string | null) => void;
    isDark: boolean;
    onToggleTheme: () => void;
}

export default function SidePanel({
    devices,
    selectedDeviceId,
    onSelectDevice,
    isDark,
    onToggleTheme,
}: SidePanelProps) {
    const [search, setSearch] = useState('');
    const [activeCommand, setActiveCommand] = useState<string | null>(null);

    const filteredDevices = useMemo(() => {
        if (!search) return devices;
        return devices.filter(d => d.id.toLowerCase().includes(search.toLowerCase()));
    }, [devices, search]);

    const activeCount = devices.filter(d => d.speed > 0).length;

    const selectedDevice = useMemo(() => {
        return devices.find(d => d.id === selectedDeviceId);
    }, [devices, selectedDeviceId]);

    const handleRunCommand = (command: string) => {
        setActiveCommand(command);
        setTimeout(() => setActiveCommand(null), 2500);
    };

    return (
        <aside className="w-96 flex flex-col glass border-r z-20 shadow-2xl transition-all duration-300 bg-white/80 dark:bg-slate-950/80 border-slate-200 dark:border-white/10 backdrop-blur-xl">
            {/* Header */}
            <header className="p-6 space-y-4 border-b border-slate-200 dark:border-white/10">
                <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="relative">
                            <div className="w-3.5 h-3.5 rounded-full bg-blue-500 animate-pulse" />
                            <div className="absolute inset-0 w-3.5 h-3.5 rounded-full bg-blue-500 blur-sm opacity-50 animate-ping" />
                        </div>
                        <h1 className="text-lg font-black tracking-tighter text-slate-900 dark:text-white uppercase italic">
                            LAST MILE <span className="text-blue-500 dark:text-blue-400">FLEET</span>
                        </h1>
                    </div>
                    {/* Theme Toggle Button */}
                    <button
                        onClick={onToggleTheme}
                        className="p-2 rounded-xl bg-slate-100 hover:bg-slate-200 dark:bg-white/5 dark:hover:bg-white/10 border border-slate-200/50 dark:border-white/5 transition-all text-slate-500 dark:text-slate-400"
                        title="Toggle Theme"
                    >
                        {isDark ? (
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364-6.364l-.707.707M6.343 17.657l-.707.707m2.828 0l-.707-.707M17.657 6.343l-.707-.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                            </svg>
                        ) : (
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                            </svg>
                        )}
                    </button>
                </div>

                {!selectedDevice && (
                    <>
                        {/* Search */}
                        <div className="relative group">
                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                <svg className="h-4 w-4 text-slate-400 group-focus-within:text-blue-500 transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                </svg>
                            </div>
                            <input
                                type="text"
                                className="block w-full pl-10 pr-3 py-2 border border-slate-200 dark:border-slate-800 rounded-xl leading-5 bg-slate-50 dark:bg-slate-900/50 text-slate-900 dark:text-slate-100 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-blue-500/50 focus:border-blue-500 sm:text-sm transition-all shadow-sm"
                                placeholder="Search fleet assets..."
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                            />
                        </div>

                        {/* Stats */}
                        <div className="flex items-center justify-between text-[10px] font-bold text-slate-400 dark:text-slate-500">
                            <span className="uppercase tracking-wider">ONLINE ASSETS</span>
                            <span className="px-2 py-0.5 rounded-md bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20">
                                {activeCount} / {devices.length} ACTIVE
                            </span>
                        </div>
                    </>
                )}
            </header>

            {/* Content Area */}
            {selectedDevice ? (
                /* Asset Inspector Panel */
                <div className="flex-1 overflow-y-auto custom-scrollbar p-6 space-y-6">
                    <button
                        onClick={() => onSelectDevice(null)}
                        className="text-slate-400 hover:text-blue-500 flex items-center gap-1 text-xs font-bold uppercase tracking-wider transition-all"
                    >
                        ← Back to asset list
                    </button>

                    <div className="space-y-1">
                        <div className="flex items-center justify-between">
                            <h2 className="text-xl font-bold text-slate-800 dark:text-white leading-none font-mono">
                                {selectedDevice.id}
                            </h2>
                            <span className={`w-2.5 h-2.5 rounded-full ${selectedDevice.speed > 0 ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]' : 'bg-slate-300 dark:bg-slate-600'}`} />
                        </div>
                        <p className="text-[10px] text-slate-400 font-mono">
                            Last Telemetry: {new Date(selectedDevice.timestamp).toLocaleTimeString()}
                        </p>
                    </div>

                    {/* Telemetry Metrics */}
                    <div className="grid grid-cols-2 gap-4">
                        <div className="glass p-3.5 rounded-2xl border border-slate-200/50 dark:border-white/5 bg-slate-50/50 dark:bg-slate-900/30">
                            <p className="text-[9px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Velocity</p>
                            <p className="text-lg font-bold text-slate-800 dark:text-white font-mono mt-1">
                                {selectedDevice.speed} <span className="text-xs font-normal opacity-70">km/h</span>
                            </p>
                        </div>
                        <div className="glass p-3.5 rounded-2xl border border-slate-200/50 dark:border-white/5 bg-slate-50/50 dark:bg-slate-900/30">
                            <p className="text-[9px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Temperature</p>
                            <p className="text-lg font-bold text-slate-800 dark:text-white font-mono mt-1">
                                {selectedDevice.temp} <span className="text-xs font-normal opacity-70">°C</span>
                            </p>
                        </div>
                        <div className="glass p-3.5 rounded-2xl border border-slate-200/50 dark:border-white/5 bg-slate-50/50 dark:bg-slate-900/30">
                            <p className="text-[9px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Shock Force</p>
                            <p className={`text-lg font-bold font-mono mt-1 ${selectedDevice.shock > 500 ? 'text-red-500' : 'text-slate-800 dark:text-white'}`}>
                                {selectedDevice.shock} <span className="text-xs font-normal opacity-70">G</span>
                            </p>
                        </div>
                        <div className="glass p-3.5 rounded-2xl border border-slate-200/50 dark:border-white/5 bg-slate-50/50 dark:bg-slate-900/30">
                            <p className="text-[9px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Device status</p>
                            <p className="text-xs font-bold text-emerald-500 uppercase tracking-widest mt-1">
                                Connected
                            </p>
                        </div>
                    </div>

                    {/* WiFi & System Diagnostics */}
                    <div className="glass p-5 rounded-2xl border border-slate-200/50 dark:border-white/5 bg-slate-50/50 dark:bg-slate-900/30 space-y-3">
                        <h4 className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest mb-2">Connectivity & Power</h4>
                        
                        <div className="flex justify-between items-center text-xs">
                            <span className="text-slate-500">Wi-Fi Network</span>
                            <span className="font-semibold text-slate-800 dark:text-slate-200 font-mono">LMT-GATEWAY-5G</span>
                        </div>
                        <div className="flex justify-between items-center text-xs">
                            <span className="text-slate-500">Signal RSSI</span>
                            <span className="font-semibold text-slate-800 dark:text-slate-200 font-mono">-62 dBm</span>
                        </div>
                        <div className="flex justify-between items-center text-xs">
                            <span className="text-slate-500">Firmware Build</span>
                            <span className="font-semibold text-slate-800 dark:text-slate-200 font-mono">v1.4.2-stable</span>
                        </div>
                    </div>

                    {/* Remote Command Terminal */}
                    <div className="space-y-3">
                        <h4 className="text-[10px] font-black text-slate-400 dark:text-slate-500 uppercase tracking-widest">Remote Controls</h4>
                        
                        <div className="grid grid-cols-2 gap-2">
                            <button
                                onClick={() => handleRunCommand('REBOOT')}
                                className="flex items-center justify-center gap-2 p-3 text-xs font-semibold rounded-xl border border-slate-200 dark:border-white/10 hover:bg-slate-50 dark:hover:bg-white/5 transition-all text-slate-800 dark:text-slate-200"
                            >
                                Reboot System
                            </button>
                            <button
                                onClick={() => handleRunCommand('IDENTIFY')}
                                className="flex items-center justify-center gap-2 p-3 text-xs font-semibold rounded-xl border border-slate-200 dark:border-white/10 hover:bg-slate-50 dark:hover:bg-white/5 transition-all text-slate-800 dark:text-slate-200"
                            >
                                Identify LED
                            </button>
                            <button
                                onClick={() => handleRunCommand('WIFI_SCAN')}
                                className="flex items-center justify-center gap-2 p-3 text-xs font-semibold rounded-xl border border-slate-200 dark:border-white/10 hover:bg-slate-50 dark:hover:bg-white/5 transition-all text-slate-800 dark:text-slate-200"
                            >
                                Refresh Wi-Fi
                            </button>
                            <button
                                onClick={() => handleRunCommand('OTA_TRIGGER')}
                                className="flex items-center justify-center gap-2 p-3 text-xs font-semibold rounded-xl border border-blue-500/20 hover:border-blue-500 bg-blue-500/10 dark:bg-blue-500/20 hover:bg-blue-500/20 transition-all text-blue-600 dark:text-blue-400"
                            >
                                Trigger OTA
                            </button>
                        </div>

                        {activeCommand && (
                            <div className="glass p-3 rounded-xl border border-blue-500/30 bg-blue-500/10 text-[10px] font-mono text-blue-600 dark:text-blue-400 animate-pulse text-center">
                                COMMAND [{activeCommand}] SENT TO DEVICE OVER SECURE GATT STACK
                            </div>
                        )}
                    </div>
                </div>
            ) : (
                /* Fleet Devices List */
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
                                    group relative p-4 rounded-2xl border transition-all duration-200 cursor-pointer
                                    ${isSelected
                                        ? 'bg-blue-500/5 border-blue-500 shadow-md ring-1 ring-blue-500/20'
                                        : 'bg-white/50 dark:bg-slate-900/30 border-slate-200 dark:border-white/5 hover:border-blue-400/50 hover:shadow-md hover:scale-[1.01]'
                                    }
                                `}
                            >
                                <div className="flex justify-between items-start mb-2">
                                    <div>
                                        <h3 className={`font-mono font-bold text-sm tracking-tight ${isSelected ? 'text-blue-600 dark:text-blue-400' : 'text-slate-900 dark:text-slate-100'}`}>
                                            {device.id}
                                        </h3>
                                        <p className="text-[9px] text-slate-400 font-mono mt-0.5">
                                            {new Date(device.timestamp).toLocaleTimeString()}
                                        </p>
                                    </div>
                                    <div className={`
                                        w-2.5 h-2.5 rounded-full
                                        ${isMoving ? 'bg-green-500 shadow-[0_0_8px_rgba(34,197,94,0.6)]' : 'bg-slate-300 dark:bg-slate-600'}
                                    `} />
                                </div>

                                <div className="grid grid-cols-2 gap-2 mt-3">
                                    <div className="bg-slate-50/50 dark:bg-white/5 rounded-xl p-2.5 border border-slate-100 dark:border-transparent">
                                        <p className="text-[9px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest">Velocity</p>
                                        <p className="text-xs font-bold text-slate-700 dark:text-slate-200 font-mono">
                                            {device.speed} <span className="font-normal text-[10px] opacity-70">km/h</span>
                                        </p>
                                    </div>
                                    <div className="bg-slate-50/50 dark:bg-white/5 rounded-xl p-2.5 border border-slate-100 dark:border-transparent">
                                        <p className="text-[9px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-widest">Shock force</p>
                                        <p className={`text-xs font-bold font-mono ${isHighShock ? 'text-red-500' : 'text-slate-700 dark:text-slate-200'}`}>
                                            {device.shock} <span className="font-normal text-[10px] opacity-70">g</span>
                                        </p>
                                    </div>
                                </div>

                                {/* Selection Indicator */}
                                {isSelected && (
                                    <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1.5 h-10 bg-blue-500 rounded-r-full" />
                                )}
                            </div>
                        );
                    })}

                    {filteredDevices.length === 0 && (
                        <div className="text-center py-12">
                            <p className="text-xs font-bold text-slate-400">No assets found matching &quot;{search}&quot;</p>
                        </div>
                    )}
                </div>
            )}

            <footer className="p-4 border-t border-slate-200 dark:border-white/10 bg-slate-50/50 dark:bg-black/20">
                <div className="flex justify-between items-center text-[9px] text-slate-400 dark:text-slate-500 font-black tracking-widest">
                    <span>SYSTEM HEALTH</span>
                    <span className="text-green-500 flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse" />
                        OPERATIONAL
                    </span>
                </div>
            </footer>
        </aside>
    );
}
