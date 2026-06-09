import React from 'react';
import { ShieldCheck, MapPin, PackageCheck, Bike } from 'lucide-react';

const Safety = () => {
    const highlights = [
        {
            title: 'Verified Delivery Partners',
            description: 'All riders are verified with documents and background checks.',
            icon: ShieldCheck,
        },
        {
            title: 'Contactless Delivery',
            description: 'Choose safe drop-off options for every order.',
            icon: PackageCheck,
        },
        {
            title: 'Live Tracking',
            description: 'Track your rider in real time with smart routing updates.',
            icon: MapPin,
        },
        {
            title: 'Rider Safety Gear',
            description: 'Helmets and safety kits are mandatory for every partner.',
            icon: Bike,
        },
    ];

    const tips = [
        'Share the correct address and landmark before checkout.',
        'Use in-app chat instead of sharing personal numbers.',
        'Report any issue directly from the order details screen.',
    ];

    return (
        <div className="bg-gray-950 text-white min-h-screen">
            <section className="relative overflow-hidden">
                <div className="absolute inset-0">
                    <div className="absolute -top-40 -left-20 w-96 h-96 bg-primary-500/20 blur-3xl rounded-full" />
                    <div className="absolute -bottom-40 -right-20 w-96 h-96 bg-accent-500/20 blur-3xl rounded-full" />
                </div>
                <div className="relative max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-24 text-center">
                    <p className="text-sm uppercase tracking-[0.3em] text-primary-300 font-semibold">Safety First</p>
                    <h1 className="mt-4 text-4xl sm:text-5xl font-display font-bold">Safety</h1>
                    <p className="mt-4 text-lg text-gray-300 max-w-2xl mx-auto">
                        Your safety and our partner safety are core to every delivery.
                    </p>
                </div>
            </section>

            <section className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pb-16 lg:pb-20">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {highlights.map(({ title, description, icon: Icon }) => (
                        <div
                            key={title}
                            className="rounded-2xl bg-gray-900/80 border border-gray-800 p-6 shadow-lg hover:-translate-y-1 hover:border-primary-500/60 transition-all"
                        >
                            <Icon className="w-6 h-6 text-primary-400" />
                            <h2 className="mt-4 text-xl font-display font-semibold">{title}</h2>
                            <p className="mt-3 text-sm text-gray-400">{description}</p>
                        </div>
                    ))}
                </div>
            </section>

            <section className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pb-20 lg:pb-28">
                <div className="rounded-3xl bg-gray-900/80 border border-gray-800 p-8 shadow-xl">
                    <h2 className="text-2xl font-display font-semibold">Safety Tips</h2>
                    <ul className="mt-6 space-y-3 text-sm text-gray-400">
                        {tips.map((tip) => (
                            <li key={tip} className="rounded-2xl bg-gray-950/70 border border-gray-800 p-4">
                                {tip}
                            </li>
                        ))}
                    </ul>
                </div>
            </section>
        </div>
    );
};

export default Safety;
