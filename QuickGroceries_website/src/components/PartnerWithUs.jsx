import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { ArrowRight, CheckCircle2, Zap, Users, MapPin, Warehouse, Award, Send, Building2, TrendingUp, Smartphone } from 'lucide-react';

const PartnerWithUs = () => {
    const [formData, setFormData] = useState({
        name: '',
        phone: '',
        email: '',
        city: '',
        businessType: '',
        investmentCapacity: '',
        message: '',
    });

    const [formSubmitted, setFormSubmitted] = useState(false);

    const handleInputChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        // Handle form submission
        console.log('Form submitted:', formData);
        setFormSubmitted(true);
        setTimeout(() => setFormSubmitted(false), 3000);
        setFormData({ name: '', phone: '', email: '', city: '', businessType: '', investmentCapacity: '', message: '' });
    };

    const containerVariants = {
        hidden: { opacity: 0 },
        visible: {
            opacity: 1,
            transition: {
                staggerChildren: 0.1,
                delayChildren: 0.2,
            },
        },
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { duration: 0.5 },
        },
    };

    const whyPartnerBenefits = [
        {
            icon: TrendingUp,
            title: 'Growing Market',
            description: 'Quick-commerce is the fastest growing segment in India'
        },
        {
            icon: Smartphone,
            title: 'Ready Tech Platform',
            description: 'Complete technology stack for order management and delivery'
        },
        {
            icon: Warehouse,
            title: 'Operational Support',
            description: 'Full logistics and operational guidance from day one'
        },
        {
            icon: Zap,
            title: 'Marketing Support',
            description: 'Branding, digital marketing, and community engagement'
        },
    ];

    const targetLocations = [
        { name: 'Tier 2 Cities', description: 'Medium-sized urban centers with high growth' },
        { name: 'Tier 3 Towns', description: 'Emerging towns with untapped potential' },
        { name: 'Urban Clusters', description: 'Peri-urban areas with rising demand' },
    ];

    const darkStoreFeatures = [
        { title: 'Micro-Warehouse', description: 'Local inventory hub managed by technology' },
        { title: 'Fast Processing', description: 'Real-time order processing and fulfillment' },
        { title: '30-Min Delivery', description: 'Lightning-fast delivery to customers' },
        { title: 'Tech Managed', description: 'Inventory and operations fully digitized' },
    ];

    const whoCanApply = [
        { title: 'Retail Shop Owners', description: 'Expand your existing retail operation' },
        { title: 'Warehouse Owners', description: 'Leverage your existing infrastructure' },
        { title: 'Entrepreneurs', description: 'Build a new business with proven model' },
        { title: 'Delivery Operators', description: 'Grow your delivery network' },
    ];

    const partnerBenefits = [
        { icon: TrendingUp, title: 'Monthly Revenue', description: 'Attractive monthly revenue sharing model' },
        { icon: Smartphone, title: 'Tech Provided', description: 'Complete tech platform and tools' },
        { icon: Award, title: 'Training Support', description: 'Comprehensive onboarding and training' },
        { icon: Users, title: 'Dedicated Team', description: '24/7 dedicated support team' },
    ];

    return (
        <div className="min-h-screen bg-gradient-to-b from-gray-950 via-gray-900 to-gray-950">
            {/* Hero Section */}
            <section className="relative min-h-screen flex items-center overflow-hidden pt-20 lg:pt-0">
                <div className="absolute inset-0 opacity-10">
                    <div className="absolute top-20 left-10 w-96 h-96 bg-primary-500 rounded-full mix-blend-overlay filter blur-3xl animate-pulse" />
                    <div className="absolute bottom-20 right-10 w-96 h-96 bg-accent-500 rounded-full mix-blend-overlay filter blur-3xl animate-pulse" />
                </div>

                <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 w-full">
                    <motion.div
                        initial={{ opacity: 0, y: 40 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8 }}
                        className="text-center"
                    >
                        <motion.div
                            initial={{ scale: 0 }}
                            animate={{ scale: 1 }}
                            transition={{ type: "spring", stiffness: 200, delay: 0.2 }}
                            className="inline-flex items-center justify-center w-16 h-16 bg-primary-500/20 backdrop-blur-sm rounded-full mb-8"
                        >
                            <Building2 className="w-8 h-8 text-primary-400" />
                        </motion.div>

                        <h1 className="text-5xl sm:text-6xl lg:text-7xl font-display font-bold text-white mb-6 leading-tight">
                            Partner With
                            <br />
                            <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-400 via-primary-300 to-accent-400">
                                Quick Groceries
                            </span>
                        </h1>

                        <p className="text-xl sm:text-2xl text-gray-300 max-w-3xl mx-auto mb-12 leading-relaxed">
                            Join us in building the fastest grocery delivery network across Tier 2 & Tier 3 cities in India.
                            <br className="hidden sm:block" />
                            <span className="text-primary-300">Expand your business. Scale fast. Earn more.</span>
                        </p>

                        <motion.div
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                            className="inline-block"
                        >
                            <a href="#application-form" className="group px-8 py-4 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-2xl font-semibold shadow-2xl hover:shadow-primary-500/50 transition-all duration-300 flex items-center space-x-2 hover:from-primary-700 hover:to-primary-800">
                                <span>Become a Partner</span>
                                <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                            </a>
                        </motion.div>

                        {/* Download Vendor App */}
                        <motion.div
                            whileHover={{ scale: 1.05 }}
                            whileTap={{ scale: 0.95 }}
                            className="inline-block ml-4"
                        >
                            <a
                                href="https://play.google.com/store/apps/details?id=com.quickgrocery_vendor.app"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="group px-8 py-4 bg-white text-primary-700 rounded-2xl font-semibold shadow-2xl hover:shadow-white/50 transition-all duration-300 flex items-center space-x-2 hover:bg-gray-100"
                            >
                                <Smartphone className="w-5 h-5" />
                                <span>Download Vendor App</span>
                                <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                            </a>
                        </motion.div>
                    </motion.div>
                </div>
            </section>

            {/* About Partnership */}
            <section className="relative py-20 lg:py-32 bg-gray-900/50">
                <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-center"
                    >
                        <h2 className="text-4xl lg:text-5xl font-display font-bold text-white mb-8">
                            About Our Partnership
                        </h2>
                        <p className="text-lg text-gray-400 leading-relaxed">
                            We are expanding into multiple towns across India and looking for local business partners to collaborate in operating dark stores and last-mile grocery fulfillment. Our partnership model enables entrepreneurs and business owners to build sustainable revenue streams while leveraging our proven technology platform and operational expertise.
                        </p>
                    </motion.div>
                </div>
            </section>

            {/* Why Partner With Us */}
            <section className="relative py-20 lg:py-32">
                <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-4xl lg:text-5xl font-display font-bold text-white text-center mb-16"
                    >
                        Why Partner With Us
                    </motion.h2>

                    <motion.div
                        variants={containerVariants}
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        className="grid md:grid-cols-2 lg:grid-cols-4 gap-8"
                    >
                        {whyPartnerBenefits.map((benefit, index) => {
                            const Icon = benefit.icon;
                            return (
                                <motion.div
                                    key={index}
                                    variants={itemVariants}
                                    className="group relative bg-gradient-to-br from-gray-800 to-gray-900 p-8 rounded-2xl border border-gray-700 hover:border-primary-500/50 transition-all duration-300 overflow-hidden"
                                >
                                    <div className="absolute inset-0 bg-gradient-to-br from-primary-500/10 to-accent-500/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                                    <div className="relative">
                                        <div className="w-14 h-14 bg-primary-500/20 rounded-xl flex items-center justify-center mb-6 group-hover:bg-primary-500/30 transition-colors">
                                            <Icon className="w-7 h-7 text-primary-400" />
                                        </div>
                                        <h3 className="text-xl font-bold text-white mb-3">{benefit.title}</h3>
                                        <p className="text-gray-400 leading-relaxed">{benefit.description}</p>
                                    </div>
                                </motion.div>
                            );
                        })}
                    </motion.div>
                </div>
            </section>

            {/* Dark Store Model */}
            <section className="relative py-20 lg:py-32 bg-gray-900/50">
                <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-4xl lg:text-5xl font-display font-bold text-white text-center mb-16"
                    >
                        The Dark Store Model
                    </motion.h2>

                    <motion.div
                        variants={containerVariants}
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        className="grid md:grid-cols-2 lg:grid-cols-4 gap-8"
                    >
                        {darkStoreFeatures.map((feature, index) => (
                            <motion.div
                                key={index}
                                variants={itemVariants}
                                className="relative"
                            >
                                <div className="bg-gradient-to-br from-primary-900/30 to-accent-900/30 p-8 rounded-2xl border border-primary-500/20 hover:border-primary-500/50 transition-all duration-300 h-full">
                                    <div className="flex items-center space-x-4 mb-4">
                                        <div className="w-4 h-4 rounded-full bg-primary-500" />
                                        <h3 className="text-xl font-bold text-white">{feature.title}</h3>
                                    </div>
                                    <p className="text-gray-300 leading-relaxed">{feature.description}</p>
                                </div>
                            </motion.div>
                        ))}
                    </motion.div>
                </div>
            </section>

            {/* Who Can Apply */}
            <section className="relative py-20 lg:py-32">
                <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-4xl lg:text-5xl font-display font-bold text-white text-center mb-16"
                    >
                        Who Can Apply
                    </motion.h2>

                    <motion.div
                        variants={containerVariants}
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto"
                    >
                        {whoCanApply.map((item, index) => (
                            <motion.div
                                key={index}
                                variants={itemVariants}
                                className="group flex items-start space-x-4 p-6 bg-gray-800/30 rounded-xl border border-gray-700 hover:border-primary-500/50 transition-all duration-300 hover:bg-gray-800/50"
                            >
                                <div className="flex-shrink-0">
                                    <div className="w-12 h-12 bg-primary-500/20 rounded-lg flex items-center justify-center group-hover:bg-primary-500/30 transition-colors">
                                        <CheckCircle2 className="w-6 h-6 text-primary-400" />
                                    </div>
                                </div>
                                <div>
                                    <h3 className="text-lg font-bold text-white mb-2">{item.title}</h3>
                                    <p className="text-gray-400 text-sm">{item.description}</p>
                                </div>
                            </motion.div>
                        ))}
                    </motion.div>
                </div>
            </section>

            {/* Partner Benefits */}
            <section className="relative py-20 lg:py-32 bg-gray-900/50">
                <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-4xl lg:text-5xl font-display font-bold text-white text-center mb-16"
                    >
                        Partner Benefits
                    </motion.h2>

                    <motion.div
                        variants={containerVariants}
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        className="grid md:grid-cols-2 lg:grid-cols-4 gap-8"
                    >
                        {partnerBenefits.map((benefit, index) => {
                            const Icon = benefit.icon;
                            return (
                                <motion.div
                                    key={index}
                                    variants={itemVariants}
                                    className="group relative bg-gradient-to-br from-gray-800 to-gray-900 p-8 rounded-2xl border border-gray-700 hover:border-accent-500/50 transition-all duration-300 overflow-hidden"
                                >
                                    <div className="absolute inset-0 bg-gradient-to-br from-accent-500/10 to-primary-500/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                                    <div className="relative">
                                        <div className="w-14 h-14 bg-accent-500/20 rounded-xl flex items-center justify-center mb-6 group-hover:bg-accent-500/30 transition-colors">
                                            <Icon className="w-7 h-7 text-accent-400" />
                                        </div>
                                        <h3 className="text-lg font-bold text-white mb-3">{benefit.title}</h3>
                                        <p className="text-gray-400 text-sm leading-relaxed">{benefit.description}</p>
                                    </div>
                                </motion.div>
                            );
                        })}
                    </motion.div>
                </div>
            </section>

            {/* Target Locations */}
            <section className="relative py-20 lg:py-32">
                <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <motion.h2
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        className="text-4xl lg:text-5xl font-display font-bold text-white text-center mb-16"
                    >
                        Target Locations
                    </motion.h2>

                    <motion.div
                        variants={containerVariants}
                        initial="hidden"
                        whileInView="visible"
                        viewport={{ once: true }}
                        className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto"
                    >
                        {targetLocations.map((location, index) => (
                            <motion.div
                                key={index}
                                variants={itemVariants}
                                className="group relative bg-gradient-to-br from-primary-900/40 to-accent-900/40 p-8 rounded-2xl border border-primary-500/20 hover:border-primary-500/50 transition-all duration-300 overflow-hidden"
                            >
                                <div className="absolute inset-0 bg-gradient-to-br from-primary-500/10 to-accent-500/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
                                <div className="relative">
                                    <div className="flex items-center space-x-3 mb-4">
                                        <MapPin className="w-6 h-6 text-primary-400" />
                                        <h3 className="text-xl font-bold text-white">{location.name}</h3>
                                    </div>
                                    <p className="text-gray-300 leading-relaxed">{location.description}</p>
                                </div>
                            </motion.div>
                        ))}
                    </motion.div>
                </div>
            </section>

            {/* CTA Section */}
            <section className="relative py-20 lg:py-32 bg-gradient-to-br from-primary-900/30 to-accent-900/30 border-y border-primary-500/20">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                    className="relative max-w-4xl mx-auto text-center px-4 sm:px-6 lg:px-8"
                >
                    <h2 className="text-4xl lg:text-5xl font-display font-bold text-white mb-6">
                        Start Your Partnership Journey
                    </h2>
                    <p className="text-xl text-gray-300 mb-12">
                        Fill out the application form below and our team will get in touch with you within 24 hours.
                    </p>
                    <motion.a
                        href="#application-form"
                        whileHover={{ scale: 1.05 }}
                        whileTap={{ scale: 0.95 }}
                        className="group inline-flex items-center space-x-2 px-8 py-4 bg-white text-primary-700 rounded-2xl font-semibold shadow-2xl hover:shadow-white/50 transition-all duration-300"
                    >
                        <span>Apply Now</span>
                        <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                    </motion.a>
                </motion.div>
            </section>

            {/* Application Form */}
            <section id="application-form" className="relative py-20 lg:py-32">
                <div className="relative max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                    >
                        <h2 className="text-4xl lg:text-5xl font-display font-bold text-white text-center mb-6">
                            Partner Application Form
                        </h2>
                        <p className="text-lg text-gray-400 text-center mb-12">
                            Take the first step towards building your quick-commerce business with us.
                        </p>

                        <motion.form
                            onSubmit={handleSubmit}
                            className="bg-gradient-to-br from-gray-800 to-gray-900 p-8 lg:p-12 rounded-3xl border border-gray-700 shadow-2xl"
                        >
                            <div className="grid md:grid-cols-2 gap-8 mb-8">
                                {/* Name */}
                                <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}>
                                    <label className="block text-sm font-semibold text-white mb-3">Full Name *</label>
                                    <input
                                        type="text"
                                        name="name"
                                        value={formData.name}
                                        onChange={handleInputChange}
                                        placeholder="Your full name"
                                        required
                                        className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary-500 transition-colors"
                                    />
                                </motion.div>

                                {/* Phone */}
                                <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}>
                                    <label className="block text-sm font-semibold text-white mb-3">Phone Number *</label>
                                    <input
                                        type="tel"
                                        name="phone"
                                        value={formData.phone}
                                        onChange={handleInputChange}
                                        placeholder="+91 9XXXXXXXXX"
                                        required
                                        className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary-500 transition-colors"
                                    />
                                </motion.div>

                                {/* Email */}
                                <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}>
                                    <label className="block text-sm font-semibold text-white mb-3">Email Address *</label>
                                    <input
                                        type="email"
                                        name="email"
                                        value={formData.email}
                                        onChange={handleInputChange}
                                        placeholder="your.email@example.com"
                                        required
                                        className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary-500 transition-colors"
                                    />
                                </motion.div>

                                {/* City */}
                                <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}>
                                    <label className="block text-sm font-semibold text-white mb-3">City *</label>
                                    <input
                                        type="text"
                                        name="city"
                                        value={formData.city}
                                        onChange={handleInputChange}
                                        placeholder="Your city"
                                        required
                                        className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary-500 transition-colors"
                                    />
                                </motion.div>

                                {/* Business Type */}
                                <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}>
                                    <label className="block text-sm font-semibold text-white mb-3">Business Type *</label>
                                    <select
                                        name="businessType"
                                        value={formData.businessType}
                                        onChange={handleInputChange}
                                        required
                                        className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white focus:outline-none focus:border-primary-500 transition-colors"
                                    >
                                        <option value="">Select business type</option>
                                        <option value="retail">Retail Shop Owner</option>
                                        <option value="warehouse">Warehouse Owner</option>
                                        <option value="entrepreneur">Entrepreneur</option>
                                        <option value="delivery">Delivery Operator</option>
                                    </select>
                                </motion.div>

                                {/* Investment Capacity */}
                                <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }}>
                                    <label className="block text-sm font-semibold text-white mb-3">Investment Capacity *</label>
                                    <select
                                        name="investmentCapacity"
                                        value={formData.investmentCapacity}
                                        onChange={handleInputChange}
                                        required
                                        className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white focus:outline-none focus:border-primary-500 transition-colors"
                                    >
                                        <option value="">Select capacity</option>
                                        <option value="5-10L">₹50k-1 Lakhs</option>
                                        <option value="10-25L">₹1-10 Lakhs</option>
                                        <option value="25-50L">₹10-25 Lakhs</option>
                                        <option value="50L+">₹25+ Lakhs</option>
                                    </select>
                                </motion.div>
                            </div>

                            {/* Message */}
                            <motion.div initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} className="mb-8">
                                <label className="block text-sm font-semibold text-white mb-3">Tell Us About Your Business</label>
                                <textarea
                                    name="message"
                                    value={formData.message}
                                    onChange={handleInputChange}
                                    placeholder="Share details about your business experience, why you want to partner with us, and any questions..."
                                    rows="5"
                                    className="w-full px-4 py-3 bg-gray-700/50 border border-gray-600 rounded-lg text-white placeholder-gray-500 focus:outline-none focus:border-primary-500 transition-colors resize-none"
                                />
                            </motion.div>

                            {/* Submit Button */}
                            <motion.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                                <button
                                    type="submit"
                                    className="w-full group px-8 py-4 bg-gradient-to-r from-primary-600 to-primary-700 text-white rounded-xl font-semibold shadow-lg hover:shadow-xl transition-all duration-300 flex items-center justify-center space-x-2 hover:from-primary-700 hover:to-primary-800"
                                >
                                    <span>Submit Application</span>
                                    <Send className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                                </button>
                            </motion.div>

                            {/* Success Message */}
                            {formSubmitted && (
                                <motion.div
                                    initial={{ opacity: 0, y: 10 }}
                                    animate={{ opacity: 1, y: 0 }}
                                    exit={{ opacity: 0, y: 10 }}
                                    className="mt-4 p-4 bg-green-500/20 border border-green-500/50 rounded-lg text-green-400 text-center font-medium"
                                >
                                    ✓ Application submitted successfully! We'll be in touch soon.
                                </motion.div>
                            )}
                        </motion.form>
                    </motion.div>
                </div>
            </section>

            {/* Footer CTA */}
            <section className="relative py-16 bg-gray-900/50 border-t border-gray-800">
                <div className="relative max-w-4xl mx-auto text-center px-4 sm:px-6 lg:px-8">
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                    >
                        <p className="text-lg text-gray-400 mb-6">
                            Have questions? Reach out to our partnership team.
                        </p>
                        <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
                            <a href="tel:+919493803361" className="text-primary-400 font-semibold hover:text-primary-300 transition-colors">
                                📞 +91 94938 03361
                            </a>
                            <span className="hidden sm:block text-gray-600">•</span>
                            <a href="mailto:partners@quickgroceries.in" className="text-primary-400 font-semibold hover:text-primary-300 transition-colors">
                                📧 partners@quickgroceries.in
                            </a>
                        </div>
                    </motion.div>
                </div>
            </section>
        </div>
    );
};

export default PartnerWithUs;
