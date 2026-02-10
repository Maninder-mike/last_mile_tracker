'use client';

import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { DeviceReading } from '@/utils/types';

// Premium Marker SVG
const createCustomIcon = (isHighShock: boolean) => {
    const color = isHighShock ? '#ef4444' : '#3b82f6';
    const svg = `
        <svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M20 38C20 38 34 26.6863 34 16C34 8.26801 27.732 2 20 2C12.268 2 6 8.26801 6 16C6 26.6863 20 38 20 38Z" fill="${color}" fill-opacity="0.2"/>
            <path d="M20 32C20 32 30 23.0588 30 16C30 10.4772 25.5228 6 20 6C14.4772 6 10 10.4772 10 16C10 23.0588 20 32 20 32Z" fill="${color}" stroke="white" stroke-width="2"/>
            <circle cx="20" cy="16" r="4" fill="white"/>
            ${isHighShock ? '<circle cx="20" cy="16" r="10" stroke="#ef4444" stroke-width="2" opacity="0.5"><animate attributeName="r" from="4" to="14" dur="1s" repeatCount="indefinite" /><animate attributeName="opacity" from="0.5" to="0" dur="1s" repeatCount="indefinite" /></circle>' : ''}
        </svg>
    `;

    return L.divIcon({
        html: svg,
        className: 'marker-shadow',
        iconSize: [40, 40],
        iconAnchor: [20, 40],
        popupAnchor: [0, -35],
    });
};

export default function FleetMap({ devices }: { devices: DeviceReading[] }) {
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    if (!mounted) return <div className="h-full w-full bg-slate-100 dark:bg-slate-900 animate-pulse" />;

    return (
        <MapContainer
            center={[37.7749, -122.4194]}
            zoom={13}
            zoomControl={false}
            style={{ height: '100%', width: '100%', background: '#0f172a' }}
        >
            <TileLayer
                url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>'
            />
            {devices.map((device) => (
                <Marker
                    key={device.id}
                    position={[device.lat, device.lon]}
                    icon={createCustomIcon(device.shock > 500)}
                >
                    <Popup className="premium-popup">
                        <div className="p-1 min-w-[140px]">
                            <h5 className="font-black text-slate-900 tracking-tighter uppercase italic border-b border-slate-100 pb-2 mb-2">
                                {device.id}
                            </h5>
                            <div className="space-y-1.5 text-[11px] font-bold text-slate-600 uppercase tracking-widest">
                                <div className="flex justify-between">
                                    <span>Velocity</span>
                                    <span className="text-slate-900 font-black">{device.speed} KM/H</span>
                                </div>
                                <div className="flex justify-between">
                                    <span>Ambient</span>
                                    <span className="text-slate-900 font-black">{device.temp}°C</span>
                                </div>
                                <div className="flex justify-between">
                                    <span>Shock</span>
                                    <span className={device.shock > 500 ? "text-red-500 font-black" : "text-slate-900 font-black"}>
                                        {device.shock}G
                                    </span>
                                </div>
                            </div>
                        </div>
                    </Popup>
                </Marker>
            ))}
        </MapContainer>
    );
}
