// Sentry telemetry configuration stub for fleet_dashboard
export const initSentry = () => {
    try {
        const dsn = process.env.NEXT_PUBLIC_SENTRY_DSN || '';
        if (dsn) {
            console.log('[Sentry] Telemetry Client initialized');
            // In production, integrate:
            // Sentry.init({ dsn, tracesSampleRate: 1.0 });
        }
    } catch (e) {
        console.error('[Sentry] Init failed:', e);
    }
};

export const captureException = (error: unknown, extra?: Record<string, unknown>) => {
    console.error('[Sentry Capture Exception]', error, extra);
    // In production, integrate:
    // Sentry.captureException(error, { extra });
};
