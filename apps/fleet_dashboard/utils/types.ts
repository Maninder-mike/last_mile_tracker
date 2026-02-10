export interface DeviceReading {
    id: string;
    lat: number;
    lon: number;
    speed: number;
    temp: number;
    shock: number;
    timestamp: string;
}

export interface DeviceStatus {
    id: string;
    lastSeen: string;
    isOnline: boolean;
    batteryLevel?: number;
}
