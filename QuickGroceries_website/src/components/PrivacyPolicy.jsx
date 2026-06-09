import React from 'react';

const PrivacyPolicy = () => {
    const items = [
        {
            title: 'Information We Collect',
            description:
                'We collect information required to provide grocery delivery services and improve user experience.',
            points: [
                'Account data: name, phone, email, and login credentials.',
                'Order data: items purchased, delivery address, and order history.',
                'Device data: IP address, browser type, and app usage analytics.',
            ],
        },
        {
            title: 'How We Use Data',
            description:
                'We use your information to fulfill orders, optimize delivery, and personalize service updates.',
            points: [
                'Confirm and deliver orders efficiently with accurate routing.',
                'Provide customer support and resolve service issues.',
                'Improve product availability, pricing, and user experience.',
            ],
        },
        {
            title: 'Sharing and Disclosure',
            description:
                'We share data only with trusted partners essential to operate the service and comply with law.',
            points: [
                'Delivery partners receive order and address details to fulfill deliveries.',
                'Payment processors receive transaction data for secure processing.',
                'Legal disclosure may occur for compliance or fraud prevention.',
            ],
        },
        {
            title: 'Data Security',
            description:
                'We apply administrative, technical, and physical safeguards to protect your data.',
            points: [
                'Access controls and monitoring limit unauthorized access.',
                'Sensitive data is encrypted in transit and at rest where applicable.',
                'We regularly review and update security practices.',
            ],
        },
        {
            title: 'Data Retention',
            description:
                'We retain information only as long as needed for operational, legal, or regulatory purposes.',
            points: [
                'Order data may be stored for accounting and support needs.',
                'Inactive accounts are reviewed periodically for cleanup.',
            ],
        },
        {
            title: 'Your Choices',
            description:
                'You can access, update, or request support for your personal data at any time.',
            points: [
                'Update profile and address details from your account settings.',
                'Opt out of promotional communications where available.',
                'Contact support for data requests or privacy concerns.',
            ],
        },
    ];

    return (
        <div className="bg-gray-950 text-white min-h-screen">
            <section className="relative overflow-hidden">
                <div className="absolute inset-0">
                    <div className="absolute -top-40 -left-20 w-96 h-96 bg-primary-500/20 blur-3xl rounded-full" />
                    <div className="absolute -bottom-40 -right-20 w-96 h-96 bg-accent-500/20 blur-3xl rounded-full" />
                </div>
                <div className="relative max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-24 text-center">
                    <p className="text-sm uppercase tracking-[0.3em] text-primary-300 font-semibold">Legal</p>
                    <h1 className="mt-4 text-4xl sm:text-5xl font-display font-bold">Privacy Policy</h1>
                    <p className="mt-4 text-lg text-gray-300 max-w-2xl mx-auto">
                        Learn how we collect, use, and protect your personal information.
                    </p>
                </div>
            </section>

            <section className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 pb-20 lg:pb-28">
                <div className="rounded-3xl bg-gray-900/80 border border-gray-800 p-8 shadow-xl">
                    <div className="space-y-6">
                        {items.map((item) => (
                            <div key={item.title} className="rounded-2xl bg-gray-950/70 border border-gray-800 p-5">
                                <h2 className="text-lg font-display font-semibold">{item.title}</h2>
                                <p className="mt-2 text-sm text-gray-400">{item.description}</p>
                                {item.points && (
                                    <ul className="mt-4 space-y-2 text-sm text-gray-400">
                                        {item.points.map((point) => (
                                            <li key={point} className="flex items-start gap-2">
                                                <span className="mt-1 h-1.5 w-1.5 rounded-full bg-primary-400" />
                                                <span>{point}</span>
                                            </li>
                                        ))}
                                    </ul>
                                )}
                            </div>
                        ))}
                    </div>
                    <p className="mt-6 text-xs text-gray-500">
                        This page is a UI placeholder and not a full legal policy.
                    </p>
                </div>
            </section>
        </div>
    );
};

export default PrivacyPolicy;
