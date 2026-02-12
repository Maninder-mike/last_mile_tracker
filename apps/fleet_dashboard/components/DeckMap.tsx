'use client';

import { useEffect, useState, useMemo } from 'react';
import DeckGL from '@deck.gl/react';
import { IconLayer } from '@deck.gl/layers';
import { Map } from 'react-map-gl/maplibre';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { DeviceReading } from '@/utils/types';
import type { MapViewState, PickingInfo } from '@deck.gl/core';
import { FlyToInterpolator } from '@deck.gl/core';

// Initial view centered on San Francisco
const INITIAL_VIEW_STATE: MapViewState = {
    longitude: -122.4194,
    latitude: 37.7749,
    zoom: 13,
    pitch: 0,
    bearing: 0
};

// Map style for "Zero Cost" requirement (Carto Positron - Free for non-commercial/low volume)
const MAP_STYLE = 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';

interface DeckMapProps {
    devices: DeviceReading[];
    selectedDeviceId: string | null;
    onSelectDevice?: (id: string) => void;
}

export default function DeckMap({ devices, selectedDeviceId, onSelectDevice }: DeckMapProps) {
    const [viewState, setViewState] = useState(INITIAL_VIEW_STATE);

    // Update view state when selected device changes (FlyTo effect)
    useEffect(() => {
        if (selectedDeviceId) {
            const device = devices.find(d => d.id === selectedDeviceId);
            if (device) {
                // eslint-disable-next-line react-hooks/set-state-in-effect
                setViewState(prev => ({
                    ...prev,
                    longitude: device.lon,
                    latitude: device.lat,
                    zoom: 16,
                    transitionDuration: 1500,
                    transitionInterpolator: new FlyToInterpolator()
                }));
            }
        }
    }, [selectedDeviceId, devices]);

    const layers = useMemo(() => {
        return [
            new IconLayer({
                id: 'device-icons',
                data: devices,
                pickable: true,
                getIcon: () => ({
                    url: 'https://raw.githubusercontent.com/visgl/deck.gl-data/master/website/icon-sheet.png', // Placeholder sprite
                    width: 128,
                    height: 128,
                    anchorY: 128,
                    mask: true // Allows coloring
                }),
                getPosition: (d: DeviceReading) => [d.lon, d.lat],
                getSize: 40,
                getColor: (d: DeviceReading) => d.shock > 500 ? [239, 68, 68] : [59, 130, 246], // Tailwind red-500 or blue-500
                onClick: (info: PickingInfo) => {
                    if (info.object && onSelectDevice) {
                        onSelectDevice((info.object as DeviceReading).id);
                    }
                },
                iconMapping: {
                    marker: { x: 0, y: 0, width: 128, height: 128, mask: true }
                }
            })
        ];
    }, [devices, onSelectDevice]);

    // Custom Tooltip
    const getTooltip = ({ object }: PickingInfo) => {
        if (!object) return null;
        const d = object as DeviceReading;
        return {
            html: `
                <div class="p-2 bg-slate-900 text-white rounded-lg shadow-xl text-xs">
                    <div class="font-bold border-b border-white/20 pb-1 mb-1">${d.id}</div>
                    <div>Speed: ${d.speed} km/h</div>
                    <div>Temp: ${d.temp}°C</div>
                    <div class="${d.shock > 500 ? 'text-red-400 font-bold' : ''}">Shock: ${d.shock}g</div>
                </div>
            `,
            style: {
                backgroundColor: 'transparent',
                boxShadow: 'none'
            }
        };
    };

    return (
        <div className="relative w-full h-full bg-slate-50">
            <DeckGL
                initialViewState={INITIAL_VIEW_STATE}
                viewState={viewState}
                onViewStateChange={({ viewState }) => setViewState(viewState as MapViewState)}
                controller={true}
                layers={layers}
                getTooltip={getTooltip}
            >
                <Map
                    mapLib={maplibregl}
                    mapStyle={MAP_STYLE}
                    style={{ width: '100%', height: '100%' }}
                />
            </DeckGL>
        </div>
    );
}
