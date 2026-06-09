import React from 'react';
import { CheckCircle2, ClipboardList, ShieldCheck, GraduationCap, Truck, Zap, Download } from 'lucide-react';

const DeliveryPartner = () => {
    const benefits = [
        'Flexible timings',
        'Weekly payouts',
        'High demand orders',
        'Work in your local area',
    ];

    const requirements = [
        'Bike',
        'Driving license',
        'Smartphone',
        'Local area knowledge',
    ];

    const steps = [
        { title: 'Apply', description: 'Share your basic details and preferred working area.' },
        { title: 'Verification', description: 'We verify your documents and contact details.' },
        { title: 'Training', description: 'Quick onboarding to understand delivery flow.' },
        { title: 'Start Delivering', description: 'Go live and start earning right away.' },
    ];

    const earnings = [
        { title: 'Per order payout', description: 'Transparent earnings for every completed delivery.', icon: Truck },
        { title: 'Incentives', description: 'Extra rewards for consistent performance.', icon: Zap },
        { title: 'Peak bonuses', description: 'Boost your income during high-demand hours.', icon: CheckCircle2 },
    ];

    return (
        <div className="bg-gray-950 text-white min-h-screen">
            <section className="relative overflow-hidden">
                <div className="absolute inset-0">
                    <div className="absolute -top-40 -left-20 w-96 h-96 bg-primary-600/20 blur-3xl rounded-full" />
                    <div className="absolute -bottom-40 -right-20 w-96 h-96 bg-accent-500/20 blur-3xl rounded-full" />
                </div>
                <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-28">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
                        <div>
                            <p className="text-sm uppercase tracking-[0.2em] text-primary-300 font-semibold">
                                Delivery Partner Program
                            </p>
                            <h1 className="mt-4 text-4xl sm:text-5xl font-display font-bold leading-tight">
                                Become a Delivery Partner
                            </h1>
                            <p className="mt-5 text-lg text-gray-300 max-w-xl">
                                Earn by delivering groceries in your city with flexible working hours.
                            </p>
                            <div className="mt-8 flex flex-wrap gap-4">
                                <a
                                    href="#apply"
                                    className="inline-flex items-center justify-center px-6 py-3 rounded-full bg-primary-500 hover:bg-primary-400 text-white font-semibold shadow-lg shadow-primary-500/30 transition-all duration-300"
                                >
                                    Apply Now
                                </a>
                                <a
                                    href="/Quick-Grocery-Delivery.apk"
                                    download
                                    className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-full bg-gray-900/80 border border-gray-700 hover:border-primary-400 text-white font-semibold shadow-lg transition-all duration-300"
                                >
                                    <Download className="w-4 h-4 text-primary-300" />
                                    Download APK
                                </a>
                                <div className="inline-flex items-center gap-2 text-sm text-gray-400">
                                    <ShieldCheck className="w-4 h-4 text-primary-300" />
                                    Trusted by local riders across the city
                                </div>
                            </div>
                        </div>
                        <div className="bg-gray-900/70 border border-gray-800 rounded-3xl p-8 shadow-2xl">
                            <div className="rounded-3xl overflow-hidden mb-8 h-96">
                                <img
                                    src="https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=800&h=600&q=90"
                                    alt="Delivery partner on a bike"
                                    className="w-full h-full object-cover rounded-2xl hover:scale-105 transition-transform duration-500"
                                    loading="eager"
                                />
                            </div>
                            <div className="grid grid-cols-2 gap-6">
                                {benefits.map((benefit) => (
                                    <div
                                        key={benefit}
                                        className="rounded-2xl bg-gray-900/90 border border-gray-800 p-4 hover:border-primary-500/60 transition-colors"
                                    >
                                        <div className="flex items-center gap-2 text-sm font-medium">
                                            <CheckCircle2 className="w-4 h-4 text-primary-400" />
                                            {benefit}
                                        </div>
                                    </div>
                                ))}
                            </div>
                            <div className="mt-6 rounded-2xl bg-gradient-to-r from-primary-500/20 to-accent-500/20 border border-primary-500/30 p-4 text-sm text-gray-200">
                                Start earning from your first week with performance bonuses.
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 lg:py-20">
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
                    <div className="bg-gray-900/70 border border-gray-800 rounded-3xl p-8 shadow-xl">
                        <h2 className="text-2xl font-display font-semibold">Why Join Us</h2>
                        <div className="mt-6 grid gap-4 sm:grid-cols-2">
                            {benefits.map((benefit) => (
                                <div
                                    key={benefit}
                                    className="rounded-2xl bg-gray-950/60 border border-gray-800 p-4 hover:-translate-y-1 hover:border-primary-400/70 transition-all"
                                >
                                    <div className="flex items-center gap-2 text-sm font-medium text-gray-200">
                                        <CheckCircle2 className="w-4 h-4 text-primary-400" />
                                        {benefit}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="bg-gray-900/70 border border-gray-800 rounded-3xl p-8 shadow-xl">
                        <h2 className="text-2xl font-display font-semibold">Requirements</h2>
                        <div className="mt-6 grid gap-4 sm:grid-cols-2">
                            {requirements.map((item) => (
                                <div
                                    key={item}
                                    className="rounded-2xl bg-gray-950/60 border border-gray-800 p-4 hover:-translate-y-1 hover:border-primary-400/70 transition-all"
                                >
                                    <div className="flex items-center gap-2 text-sm font-medium text-gray-200">
                                        <ClipboardList className="w-4 h-4 text-accent-400" />
                                        {item}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                </div>
            </section>

            <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-16 lg:pb-20">
                <div className="bg-gray-900/70 border border-gray-800 rounded-3xl p-8 shadow-xl">
                    <div className="flex items-center justify-between flex-wrap gap-4">
                        <h2 className="text-2xl font-display font-semibold">How It Works</h2>
                        <span className="text-sm text-gray-400">4 simple steps to get started</span>
                    </div>
                    <div className="mt-8 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                        {steps.map((step, index) => (
                            <div
                                key={step.title}
                                className="rounded-2xl bg-gray-950/60 border border-gray-800 p-6 hover:border-primary-500/60 transition-colors"
                            >
                                <div className="text-sm text-primary-300 font-semibold">Step {index + 1}</div>
                                <h3 className="mt-2 text-lg font-semibold">{step.title}</h3>
                                <p className="mt-2 text-sm text-gray-400">{step.description}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-16 lg:pb-20">
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    {earnings.map(({ title, description, icon: Icon }) => (
                        <div
                            key={title}
                            className="rounded-3xl bg-gray-900/70 border border-gray-800 p-8 shadow-xl hover:-translate-y-1 hover:border-primary-400/70 transition-all"
                        >
                            <Icon className="w-8 h-8 text-primary-400" />
                            <h3 className="mt-4 text-xl font-display font-semibold">{title}</h3>
                            <p className="mt-3 text-sm text-gray-400">{description}</p>
                        </div>
                    ))}
                </div>
            </section>

            <section id="apply" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-20 lg:pb-28">
                <div className="grid grid-cols-1 lg:grid-cols-5 gap-10 items-start">
                    <div className="lg:col-span-2">
                        <h2 className="text-3xl font-display font-semibold">Application Form</h2>
                        <p className="mt-4 text-gray-400">
                            Fill out the details below and our team will contact you within 24 hours.
                        </p>
                        <div className="mt-6 rounded-2xl bg-gray-900/70 border border-gray-800 p-6">
                            <div className="flex items-center gap-3 text-sm text-gray-300">
                                <GraduationCap className="w-5 h-5 text-primary-400" />
                                Short training, long-term earnings potential.
                            </div>
                        </div>
                    </div>
                    <div className="lg:col-span-3 bg-gray-900/70 border border-gray-800 rounded-3xl p-8 shadow-xl">
                        <form className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                            <div className="sm:col-span-2">
                                <label className="text-sm text-gray-300">Full Name</label>
                                <input
                                    type="text"
                                    placeholder="Enter your full name"
                                    className="mt-2 w-full rounded-xl bg-gray-950/70 border border-gray-800 px-4 py-3 text-sm text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500"
                                />
                            </div>
                            <div>
                                <label className="text-sm text-gray-300">Phone</label>
                                <input
                                    type="tel"
                                    placeholder="Enter your phone"
                                    className="mt-2 w-full rounded-xl bg-gray-950/70 border border-gray-800 px-4 py-3 text-sm text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500"
                                />
                            </div>
                            <div>
                                <label className="text-sm text-gray-300">City</label>
                                <input
                                    type="text"
                                    placeholder="City"
                                    className="mt-2 w-full rounded-xl bg-gray-950/70 border border-gray-800 px-4 py-3 text-sm text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500"
                                />
                            </div>
                            <div>
                                <label className="text-sm text-gray-300">Vehicle Type</label>
                                <input
                                    type="text"
                                    placeholder="Bike / Scooter"
                                    className="mt-2 w-full rounded-xl bg-gray-950/70 border border-gray-800 px-4 py-3 text-sm text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500"
                                />
                            </div>
                            <div>
                                <label className="text-sm text-gray-300">Availability</label>
                                <input
                                    type="text"
                                    placeholder="Full time / Part time"
                                    className="mt-2 w-full rounded-xl bg-gray-950/70 border border-gray-800 px-4 py-3 text-sm text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500"
                                />
                            </div>
                            <div className="sm:col-span-2">
                                <label className="text-sm text-gray-300">Message</label>
                                <textarea
                                    rows="4"
                                    placeholder="Tell us about your local area and experience"
                                    className="mt-2 w-full rounded-xl bg-gray-950/70 border border-gray-800 px-4 py-3 text-sm text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-500"
                                />
                            </div>
                            <div className="sm:col-span-2 flex flex-wrap items-center justify-between gap-4">
                                <button
                                    type="button"
                                    className="inline-flex items-center justify-center px-6 py-3 rounded-full bg-primary-500 hover:bg-primary-400 text-white font-semibold shadow-lg shadow-primary-500/30 transition-all duration-300"
                                >
                                    Submit Application
                                </button>
                                <span className="text-xs text-gray-500">No backend - UI only.</span>
                            </div>
                        </form>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default DeliveryPartner;
