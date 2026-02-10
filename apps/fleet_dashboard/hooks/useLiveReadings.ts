import { useEffect, useState } from 'react';
import { supabase } from '@/utils/supabase';
import { DeviceReading } from '@/utils/types';

interface SensorReadingRaw {
    device_id: string;
    lat: number;
    lon: number;
    speed: number;
    temp: number;
    shock_value: number;
    timestamp: string;
}

export function useLiveReadings(initialData: DeviceReading[]) {
    const [devices, setDevices] = useState<DeviceReading[]>(initialData);

    useEffect(() => {
        // 1. Initial Fetch
        const fetchLatest = async () => {
            const { data, error } = await supabase
                .from('sensor_readings')
                .select('*')
                .order('timestamp', { ascending: false })
                .limit(20);

            if (!error && data) {
                // Simple logic to keep only the latest reading per device ID
                const latestPerDevice: Record<string, DeviceReading> = {};
                // Cast data to known type instead of any
                (data as SensorReadingRaw[]).forEach((r) => {
                    if (!latestPerDevice[r.device_id] || new Date(r.timestamp) > new Date(latestPerDevice[r.device_id].timestamp)) {
                        latestPerDevice[r.device_id] = {
                            id: r.device_id,
                            lat: r.lat,
                            lon: r.lon,
                            speed: r.speed,
                            temp: r.temp,
                            shock: r.shock_value,
                            timestamp: r.timestamp
                        };
                    }
                });
                setDevices(Object.values(latestPerDevice));
            }
        };

        fetchLatest();

        // 2. Realtime Subscription
        const channel = supabase
            .channel('live-telemetry')
            .on(
                'postgres_changes',
                { event: 'INSERT', schema: 'public', table: 'sensor_readings' },
                (payload) => {
                    const newReading = payload.new as SensorReadingRaw;
                    setDevices((prev) => {
                        const index = prev.findIndex((d) => d.id === newReading.device_id);
                        const updatedReading: DeviceReading = {
                            id: newReading.device_id,
                            lat: newReading.lat,
                            lon: newReading.lon,
                            speed: newReading.speed,
                            temp: newReading.temp,
                            shock: newReading.shock_value,
                            timestamp: newReading.timestamp
                        };

                        if (index > -1) {
                            const next = [...prev];
                            next[index] = updatedReading;
                            return next;
                        } else {
                            return [...prev, updatedReading];
                        }
                    });
                }
            )
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, []);

    return devices;
}
