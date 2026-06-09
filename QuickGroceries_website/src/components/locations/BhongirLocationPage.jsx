/**
 * Bhongir Grocery Delivery Location Page
 * SEO Optimized for: "grocery delivery in bhongir", "vegetables delivery bhongir"
 */

import React, { useEffect } from 'react';
import { useSEO } from '../context/SEOProvider';
import { updateMetaTags, addSchemaMarkup, generateBreadcrumbs } from '../utils/seoHelpers';
import {
    generateLocalBusinessSchema,
    generateBreadcrumbSchema,
    generateFAQSchema
} from '../utils/seoSchemas';
import { SITE_URL, FAQ_CONTENT } from '../utils/seoConfig';

const BhongirLocationPage = () => {
    const metadata = {
        title: 'Grocery Delivery in Bhongir | Fresh Vegetables, Fruits & Daily Essentials',
        description: 'Get fresh groceries delivered in Bhongir within 30 minutes. Order vegetables, fruits, dairy, bakery items. Reliable, fast, and affordable grocery delivery service.',
        keywords: 'grocery delivery bhongir, vegetables delivery bhongir, fresh groceries bhongir, dairy delivery bhongir, online grocery bhongir',
        canonical: `${SITE_URL}/locations/bhongir-grocery-delivery`,
        ogTitle: 'Fast Grocery Delivery in Bhongir | Fresh Products',
        ogDescription: 'Order fresh groceries in Bhongir with 30-minute delivery guarantee',
        ogImage: `${SITE_URL}/images/bhongir-delivery.jpg`
    };

    const breadcrumbs = generateBreadcrumbs([
        { name: 'Home', path: '/' },
        { name: 'Locations', path: '/locations' },
        { name: 'Bhongir', path: '/locations/bhongir-grocery-delivery' }
    ]);

    useSEO(
        metadata,
        generateLocalBusinessSchema()
    );

    useEffect(() => {
        // Add breadcrumb schema
        addSchemaMarkup(generateBreadcrumbSchema(breadcrumbs), 'breadcrumb-schema');
        // Add FAQ schema for Bhongir-specific FAQs
        addSchemaMarkup(generateFAQSchema(FAQ_CONTENT), 'faq-schema');
    }, []);

    return (
        <div className="min-h-screen bg-gradient-to-b from-orange-50 to-white">
            {/* Breadcrumb Navigation */}
            <nav className="max-w-6xl mx-auto px-4 py-6 text-sm text-gray-600">
                <ol className="flex items-center gap-2">
                    {breadcrumbs.map((item, idx) => (
                        <li key={idx} className="flex items-center gap-2">
                            <a href={item.url} className="text-orange-600 hover:underline">
                                {item.name}
                            </a>
                            {idx < breadcrumbs.length - 1 && <span>/</span>}
                        </li>
                    ))}
                </ol>
            </nav>

            {/* Hero Section */}
            <section className="max-w-6xl mx-auto px-4 py-12">
                <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
                    Grocery Delivery in Bhongir | Fast & Fresh
                </h1>
                <p className="text-xl text-gray-700 mb-6 max-w-3xl">
                    Order fresh vegetables, fruits, dairy products, bakery items, and daily essentials
                    online in Bhongir with guaranteed 30-minute delivery. Quick Groceries brings the
                    freshest products right to your doorstep.
                </p>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
                    <div className="bg-white p-6 rounded-lg shadow-md">
                        <div className="text-3xl font-bold text-orange-600 mb-2">30 min</div>
                        <h3 className="font-semibold text-lg mb-2">Fast Delivery</h3>
                        <p className="text-gray-600">Guaranteed delivery within 30 minutes in Bhongir</p>
                    </div>

                    <div className="bg-white p-6 rounded-lg shadow-md">
                        <div className="text-3xl font-bold text-orange-600 mb-2">Fresh</div>
                        <h3 className="font-semibold text-lg mb-2">Quality Assured</h3>
                        <p className="text-gray-600">Hand-picked fresh produce from verified suppliers</p>
                    </div>

                    <div className="bg-white p-6 rounded-lg shadow-md">
                        <div className="text-3xl font-bold text-orange-600 mb-2">24/7</div>
                        <h3 className="font-semibold text-lg mb-2">Always Available</h3>
                        <p className="text-gray-600">Order anytime, delivery from 6 AM to 11 PM</p>
                    </div>
                </div>
            </section>

            {/* Products Section */}
            <section className="bg-white py-12">
                <div className="max-w-6xl mx-auto px-4">
                    <h2 className="text-3xl font-bold text-gray-900 mb-8">Fresh Products Available in Bhongir</h2>

                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
                        {/* Vegetables */}
                        <div className="border rounded-lg p-6 hover:shadow-lg transition">
                            <h3 className="text-lg font-semibold text-gray-900 mb-3">
                                🥬 Fresh Vegetables
                            </h3>
                            <p className="text-gray-600 mb-4">
                                Tomatoes, onions, potatoes, spinach, carrots, beans, and more.
                            </p>
                            <a href="#order" className="text-orange-600 font-semibold hover:underline">
                                Order Now →
                            </a>
                        </div>

                        {/* Fruits */}
                        <div className="border rounded-lg p-6 hover:shadow-lg transition">
                            <h3 className="text-lg font-semibold text-gray-900 mb-3">
                                🍎 Fresh Fruits
                            </h3>
                            <p className="text-gray-600 mb-4">
                                Apples, bananas, oranges, grapes, mangoes, and seasonal fruits.
                            </p>
                            <a href="#order" className="text-orange-600 font-semibold hover:underline">
                                Order Now →
                            </a>
                        </div>

                        {/* Dairy */}
                        <div className="border rounded-lg p-6 hover:shadow-lg transition">
                            <h3 className="text-lg font-semibold text-gray-900 mb-3">
                                🥛 Dairy & Bakery
                            </h3>
                            <p className="text-gray-600 mb-4">
                                Fresh milk, curd, cheese, butter, bread, and baked goods.
                            </p>
                            <a href="#order" className="text-orange-600 font-semibold hover:underline">
                                Order Now →
                            </a>
                        </div>

                        {/* Essentials */}
                        <div className="border rounded-lg p-6 hover:shadow-lg transition">
                            <h3 className="text-lg font-semibold text-gray-900 mb-3">
                                🛒 Daily Essentials
                            </h3>
                            <p className="text-gray-600 mb-4">
                                Rice, dal, oil, spices, snacks, and household items.
                            </p>
                            <a href="#order" className="text-orange-600 font-semibold hover:underline">
                                Order Now →
                            </a>
                        </div>
                    </div>
                </div>
            </section>

            {/* Why Choose Us */}
            <section className="py-12">
                <div className="max-w-6xl mx-auto px-4">
                    <h2 className="text-3xl font-bold text-gray-900 mb-8">Why Choose Quick Groceries in Bhongir?</h2>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                        <div className="space-y-6">
                            <div className="flex gap-4">
                                <div className="flex-shrink-0">
                                    <div className="flex items-center justify-center h-12 w-12 rounded-md bg-orange-600 text-white">
                                        ✓
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-semibold text-gray-900">30-Minute Delivery Guarantee</h3>
                                    <p className="text-gray-600">Get your fruits, vegetables, and essentials within 30 minutes</p>
                                </div>
                            </div>

                            <div className="flex gap-4">
                                <div className="flex-shrink-0">
                                    <div className="flex items-center justify-center h-12 w-12 rounded-md bg-orange-600 text-white">
                                        ✓
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-semibold text-gray-900">Fresh & Quality Assured</h3>
                                    <p className="text-gray-600">All products are handpicked and quality checked</p>
                                </div>
                            </div>

                            <div className="flex gap-4">
                                <div className="flex-shrink-0">
                                    <div className="flex items-center justify-center h-12 w-12 rounded-md bg-orange-600 text-white">
                                        ✓
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-semibold text-gray-900">Easy App Ordering</h3>
                                    <p className="text-gray-600">Download Quick Groceries app for convenient shopping</p>
                                </div>
                            </div>

                            <div className="flex gap-4">
                                <div className="flex-shrink-0">
                                    <div className="flex items-center justify-center h-12 w-12 rounded-md bg-orange-600 text-white">
                                        ✓
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-semibold text-gray-900">Best Prices</h3>
                                    <p className="text-gray-600">Competitive prices with frequent offers and discounts</p>
                                </div>
                            </div>
                        </div>

                        <div className="space-y-6">
                            <div className="flex gap-4">
                                <div className="flex-shrink-0">
                                    <div className="flex items-center justify-center h-12 w-12 rounded-md bg-orange-600 text-white">
                                        ✓
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-semibold text-gray-900">Real-Time Tracking</h3>
                                    <p className="text-gray-600">Track your order in real-time with live GPS updates</p>
                                </div>
                            </div>

                            <div className="flex gap-4">
                                <div className="flex-shrink-0">
                                    <div className="flex items-center justify-center h-12 w-12 rounded-md bg-orange-600 text-white">
                                        ✓
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-semibold text-gray-900">Safe Payments</h3>
                                    <p className="text-gray-600">Secure checkout with multiple payment options</p>
                                </div>
                            </div>

                            <div className="flex gap-4">
                                <div className="flex-shrink-0">
                                    <div className="flex items-center justify-center h-12 w-12 rounded-md bg-orange-600 text-white">
                                        ✓
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-semibold text-gray-900">Customer Support</h3>
                                    <p className="text-gray-600">24/7 customer support for any issues or queries</p>
                                </div>
                            </div>

                            <div className="flex gap-4">
                                <div className="flex-shrink-0">
                                    <div className="flex items-center justify-center h-12 w-12 rounded-md bg-orange-600 text-white">
                                        ✓
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-semibold text-gray-900">Local Community Focus</h3>
                                    <p className="text-gray-600">Supporting local suppliers and Bhongir community</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* FAQ Section */}
            <section className="bg-gray-50 py-12">
                <div className="max-w-6xl mx-auto px-4">
                    <h2 className="text-3xl font-bold text-gray-900 mb-8">
                        Frequently Asked Questions About Bhongir Delivery
                    </h2>

                    <div className="space-y-6">
                        {FAQ_CONTENT.map((item, idx) => (
                            <div key={idx} className="bg-white p-6 rounded-lg">
                                <h3 className="text-lg font-semibold text-gray-900 mb-3">
                                    Q: {item.question}
                                </h3>
                                <p className="text-gray-700">
                                    A: {item.answer}
                                </p>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* CTA Section */}
            <section className="py-12">
                <div className="max-w-4xl mx-auto px-4 text-center">
                    <h2 className="text-3xl font-bold text-gray-900 mb-4">
                        Ready to Order Fresh Groceries in Bhongir?
                    </h2>
                    <p className="text-xl text-gray-700 mb-8">
                        Download the Quick Groceries app and get your first order delivered in 30 minutes
                    </p>
                    <div className="flex flex-wrap gap-4 justify-center">
                        <a
                            href="#download"
                            className="inline-block px-8 py-4 bg-orange-600 text-white font-semibold rounded-lg hover:bg-orange-700 transition"
                        >
                            Download App
                        </a>
                        <a
                            href="/help"
                            className="inline-block px-8 py-4 border-2 border-orange-600 text-orange-600 font-semibold rounded-lg hover:bg-orange-50 transition"
                        >
                            Learn More
                        </a>
                    </div>
                </div>
            </section>
        </div>
    );
};

export default BhongirLocationPage;
