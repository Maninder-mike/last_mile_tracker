'use client';

import { DeviceReading } from '@/utils/types';
import { useEffect, useState } from 'react';

export default function AlertPanel({ devices }: { devices: DeviceReading[] }) {
    const [alerts, setAlerts] = useState<DeviceReading[]>([]);
    const [isVisible, setIsVisible] = useState(false);

    useEffect(() => {
        // Collect devices with high shock (> 500)
        const critical = devices.filter((d) => d.shock > 500);
        if (critical.length > 0) {
            setAlerts(critical);
            setIsVisible(true);
        } else {
            setIsVisible(false);
        }
    }, [devices]);

    if (!isVisible) return null;

    return (
        <div className="absolute top-10 left-1/2 -translate-x-1/2 w-full max-w-md z-[2000] px-4">
            <div className="glass border-red-500/50 bg-red-500/10 dark:bg-red-500/20 rounded-3xl p-4 shadow-[0_0_30px_rgba(239,68,68,0.3)] animate-bounce-slow">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full bg-red-500 flex items-center justify-center animate-pulse shadow-[0_0_20px_rgba(239,68,68,0.5)]">
                        <svg viewBox="0 0 24 24" className="w-6 h-6 text-white fill-current">
                            <path d="M12 2L1 21h22L12 2zm0 3.99L19.53 19H4.47L12 5.99zM11 16h2v2h-2zm0-6h2v4h-2z" />
                        </svg>
                    </div>
                    <div className="flex-1">
                        <h5 className="text-red-600 dark:text-red-400 font-black text-sm tracking-tighter uppercase italic">
                            Critical Shock Event Detected
                        </h5>
                        <div className="flex flex-wrap gap-2 mt-1">
                            {alerts.map(a => (
                                <span key={a.id} className="text-[10px] font-bold bg-red-500 text-white px-2 py-0.5 rounded-lg">
                                    {a.id}: {a.shock}G
                                </span>
                            ))}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
