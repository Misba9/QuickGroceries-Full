import React from 'react';
import { ArrowUpRight } from 'lucide-react';

const Blog = () => {
    const posts = [
        {
            title: 'How Quick Commerce is Growing in Tier 2 Cities',
            category: 'Startup',
            description:
                'Demand for rapid grocery delivery is rising beyond metros as local operations unlock new growth hubs.',
            image:
                'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=1200&q=90',
        },
        {
            title: 'Why Dark Stores Are the Future of Grocery',
            category: 'Grocery',
            description:
                'Micro-fulfillment centers are redefining inventory velocity, enabling faster and smarter fulfillment.',
            image:
                'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=1200&q=90',
        },
        {
            title: 'How to Become a Grocery Delivery Partner',
            category: 'Partner',
            description:
                'A practical guide for riders to join, earn reliably, and build a steady schedule on the platform.',
            image:
                'https://images.unsplash.com/photo-1526367790999-0150786686a2?auto=format&fit=crop&w=1200&q=90',
        },
        {
            title: 'Managing Inventory in a Dark Store',
            category: 'Delivery',
            description:
                'Learn how smart stocking and replenishment keep fulfillment fast and reduce out-of-stock risk.',
            image:
                'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=1200&q=90',
        },
        {
            title: 'Tips for Faster 30-Minute Deliveries',
            category: 'Delivery',
            description:
                'Operational playbooks, rider coordination, and layout tweaks that shave minutes off every order.',
            image:
                'https://images.unsplash.com/photo-1603400521630-9f2de124b33b?auto=format&fit=crop&w=1200&q=90',
        },
        {
            title: 'Expanding Grocery Networks Across India',
            category: 'Startup',
            description:
                'From hub planning to local partnerships, explore the blueprint for nationwide grocery expansion.',
            image:
                'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=1200&q=90',
        },
    ];

    return (
        <div className="bg-gray-950 text-white min-h-screen">
            <section className="relative overflow-hidden">
                <div className="absolute inset-0">
                    <div className="absolute -top-40 -left-20 w-96 h-96 bg-primary-500/20 blur-3xl rounded-full" />
                    <div className="absolute -bottom-40 -right-20 w-96 h-96 bg-accent-500/20 blur-3xl rounded-full" />
                </div>
                <div className="relative max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-28 text-center">
                    <p className="text-sm uppercase tracking-[0.3em] text-primary-300 font-semibold">
                        Blog
                    </p>
                    <h1 className="mt-4 text-4xl sm:text-5xl font-display font-bold">Our Blog</h1>
                    <p className="mt-4 text-lg text-gray-300 max-w-2xl mx-auto">
                        Insights, updates, grocery trends, and startup growth stories.
                    </p>
                </div>
            </section>

            <section className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pb-16 lg:pb-20">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {posts.map((post) => (
                        <article
                            key={post.title}
                            className="group rounded-2xl bg-gray-900/80 border border-gray-800 overflow-hidden shadow-lg hover:-translate-y-2 hover:shadow-2xl hover:border-primary-500/60 transition-all"
                        >
                            <div className="h-48 overflow-hidden">
                                <img
                                    src={post.image}
                                    alt={post.title}
                                    className="h-full w-full object-cover group-hover:scale-105 transition-transform duration-500"
                                    loading="lazy"
                                />
                            </div>
                            <div className="p-6">
                                <span className="inline-flex items-center px-3 py-1 rounded-full bg-gray-800 text-xs uppercase tracking-wider text-primary-300">
                                    {post.category}
                                </span>
                                <h2 className="mt-4 text-xl font-display font-semibold leading-snug">
                                    {post.title}
                                </h2>
                                <p className="mt-3 text-sm text-gray-400 line-clamp-2">
                                    {post.description}
                                </p>
                                <button
                                    type="button"
                                    className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-primary-300 hover:text-primary-200 transition-colors"
                                >
                                    Read More
                                    <ArrowUpRight className="w-4 h-4" />
                                </button>
                            </div>
                        </article>
                    ))}
                </div>
            </section>

            <section className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 pb-20 lg:pb-28">
                <div className="rounded-3xl bg-gradient-to-r from-primary-500/20 via-gray-900 to-accent-500/20 border border-gray-800 p-10 text-center shadow-xl">
                    <h2 className="text-3xl font-display font-semibold">Stay Updated With Our Latest News</h2>
                    <p className="mt-3 text-gray-300">
                        Get curated stories on quick commerce, last-mile delivery, and growth strategies.
                    </p>
                    <button
                        type="button"
                        className="mt-8 inline-flex items-center justify-center px-6 py-3 rounded-full bg-primary-500 hover:bg-primary-400 text-white font-semibold shadow-lg shadow-primary-500/30 transition-all duration-300"
                    >
                        Subscribe Now
                    </button>
                </div>
            </section>
        </div>
    );
};

export default Blog;
