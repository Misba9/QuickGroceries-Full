import React from 'react';
import { Mail, Phone, MessageCircle, LifeBuoy } from 'lucide-react';

const HelpCenter = () => {
    const topics = [
        {
            title: 'Order Issues',
            description: 'Get help with delayed, missing, or incorrect orders.',
        },
        {
            title: 'Payments & Refunds',
            description: 'Understand payment methods and refund timelines.',
        },
        {
            title: 'Account & Profile',
            description: 'Manage your account details and delivery preferences.',
        },
        {
            title: 'Delivery Support',
            description: 'Live support for delivery tracking and rider updates.',
        },
    ];

    const faqs = [
        {
            question: 'How do I track my order?',
            answer: 'Open the app and visit Orders to see live delivery status.',
        },
        {
            question: 'What if my item is missing?',
            answer: 'Report it in the order details within 24 hours for quick help.',
        },
        {
            question: 'How can I change my delivery address?',
            answer: 'Update your address in the app before placing a new order.',
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
                    <p className="text-sm uppercase tracking-[0.3em] text-primary-300 font-semibold">Support</p>
                    <h1 className="mt-4 text-4xl sm:text-5xl font-display font-bold">Help Center</h1>
                    <p className="mt-4 text-lg text-gray-300 max-w-2xl mx-auto">
                        Find quick answers, live support, and helpful resources.
                    </p>
                </div>
            </section>

            <section className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pb-16 lg:pb-20">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {topics.map((topic) => (
                        <div
                            key={topic.title}
                            className="rounded-2xl bg-gray-900/80 border border-gray-800 p-6 shadow-lg hover:-translate-y-1 hover:border-primary-500/60 transition-all"
                        >
                            <h2 className="text-xl font-display font-semibold">{topic.title}</h2>
                            <p className="mt-3 text-sm text-gray-400">{topic.description}</p>
                            <button
                                type="button"
                                className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-primary-300 hover:text-primary-200 transition-colors"
                            >
                                Explore
                                <LifeBuoy className="w-4 h-4" />
                            </button>
                        </div>
                    ))}
                </div>
            </section>

            <section className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pb-16 lg:pb-20">
                <div className="rounded-3xl bg-gray-900/80 border border-gray-800 p-8 shadow-xl">
                    <h2 className="text-2xl font-display font-semibold">Frequently Asked Questions</h2>
                    <div className="mt-6 space-y-4">
                        {faqs.map((faq) => (
                            <div key={faq.question} className="rounded-2xl bg-gray-950/70 border border-gray-800 p-4">
                                <h3 className="text-sm font-semibold text-gray-200">{faq.question}</h3>
                                <p className="mt-2 text-sm text-gray-400">{faq.answer}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            <section className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pb-20 lg:pb-28">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                    {[
                        { label: 'Call Support', value: '+91 94938 03361', icon: Phone },
                        { label: 'Email Us', value: 'support@quickgroceries.in', icon: Mail },
                        { label: 'Live Chat', value: 'Available 9 AM - 9 PM', icon: MessageCircle },
                    ].map(({ label, value, icon: Icon }) => (
                        <div
                            key={label}
                            className="rounded-2xl bg-gray-900/80 border border-gray-800 p-6 shadow-lg"
                        >
                            <Icon className="w-6 h-6 text-primary-400" />
                            <p className="mt-4 text-sm text-gray-400">{label}</p>
                            <p className="mt-2 text-base font-semibold text-gray-200">{value}</p>
                        </div>
                    ))}
                </div>
            </section>
        </div>
    );
};

export default HelpCenter;
