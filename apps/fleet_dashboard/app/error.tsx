'use client';

import { useEffect } from 'react';

export default function Error({
    error,
    reset,
}: {
    error: Error & { digest?: string };
    reset: () => void;
}) {
    useEffect(() => {
        console.error(error);
    }, [error]);

    return (
        <div className="flex h-screen w-full flex-col items-center justify-center bg-gray-50 text-gray-900">
            <div className="rounded-lg bg-white p-8 shadow-lg text-center">
                <h2 className="mb-4 text-2xl font-bold text-red-600">Something went wrong!</h2>
                <p className="mb-6 text-gray-600">
                    We apologize for the inconvenience. An unexpected error has occurred.
                </p>
                <button
                    onClick={reset}
                    className="rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 transition-colors"
                >
                    Try again
                </button>
            </div>
        </div>
    );
}
