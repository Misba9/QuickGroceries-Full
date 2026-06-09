import React from 'react';

const TermsOfService = () => {
    const sections = [
        {
            title: 'Use of Service',
            description:
                'By accessing the Quick Groceries platform you agree to use the service lawfully and provide accurate, current information. You may not misuse the platform, interfere with operations, or attempt to access restricted data.',
            points: [
                'You must be at least 18 years old or use the service under guardian supervision.',
                'You are responsible for activity performed through your account.',
                'We may suspend access for suspected fraud, abuse, or policy violations.',
            ],
        },
        {
            title: 'Account and Security',
            description:
                'Keep your login credentials confidential and promptly notify us of any unauthorized access. We are not liable for losses resulting from compromised accounts if reasonable security practices are not followed.',
            points: [
                'Use a strong password and avoid sharing OTPs or verification codes.',
                'Update contact details to ensure order and support communications reach you.',
            ],
        },
        {
            title: 'Orders, Pricing, and Payments',
            description:
                'Orders are subject to product availability and confirmation. Prices, offers, and delivery fees may vary by location and time and are shown at checkout before you pay.',
            points: [
                'Payment must be completed to process an order unless cash on delivery is available.',
                'Substitutions may be offered for out-of-stock items with your approval.',
                'Promotions have terms, limits, and expiry dates which may change without notice.',
            ],
        },
        {
            title: 'Cancellations and Refunds',
            description:
                'Cancellation eligibility depends on order status and rider assignment. Refunds are issued to the original payment method once the cancellation is confirmed.',
            points: [
                'Orders that are already packed or out for delivery may not be cancelable.',
                'Refund processing times may vary by bank or payment provider.',
                'Contact support within 24 hours for missing or damaged items.',
            ],
        },
        {
            title: 'Delivery Commitments',
            description:
                'Estimated delivery times are displayed at checkout but may vary due to traffic, weather, or operational constraints. We aim to keep you informed of any delays.',
            points: [
                'Provide accurate delivery address and landmarks to avoid failed delivery attempts.',
                'Contactless delivery options are available for safety and convenience.',
            ],
        },
        {
            title: 'Limitation of Liability',
            description:
                'To the extent permitted by law, Quick Groceries is not liable for indirect, incidental, or consequential damages arising from the use of the platform.',
            points: [
                'Our total liability is limited to the value of the affected order.',
                'We are not responsible for issues caused by third-party services or network outages.',
            ],
        },
        {
            title: 'Updates to Terms',
            description:
                'We may update these terms to reflect changes in services, policies, or legal requirements. Continued use of the platform constitutes acceptance of the updated terms.',
            points: [
                'Important changes will be communicated through app notifications or email.',
                'The latest version is always available on this page.',
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
                    <h1 className="mt-4 text-4xl sm:text-5xl font-display font-bold">Terms of Service</h1>
                    <p className="mt-4 text-lg text-gray-300 max-w-2xl mx-auto">
                        Please review the terms that govern the use of Quick Groceries services.
                    </p>
                </div>
            </section>

            <section className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 pb-20 lg:pb-28">
                <div className="rounded-3xl bg-gray-900/80 border border-gray-800 p-8 shadow-xl">
                    <div className="space-y-6">
                        {sections.map((section) => (
                            <div key={section.title} className="rounded-2xl bg-gray-950/70 border border-gray-800 p-5">
                                <h2 className="text-lg font-display font-semibold">{section.title}</h2>
                                <p className="mt-2 text-sm text-gray-400">{section.description}</p>
                                {section.points && (
                                    <ul className="mt-4 space-y-2 text-sm text-gray-400">
                                        {section.points.map((point) => (
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
                        This is a summary for UI purposes only and does not replace the official legal document.
                    </p>
                </div>
            </section>
        </div>
    );
};

export default TermsOfService;
