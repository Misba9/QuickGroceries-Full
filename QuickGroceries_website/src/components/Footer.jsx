import React from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { Facebook, Twitter, Instagram, Linkedin, Mail, MapPin, Phone, Download, Bike, BarChart3, Users } from 'lucide-react';

const Footer = () => {
  const companyLinks = [
    { name: 'About Us', path: '/about' },
    { name: 'Careers', path: '/careers' },
    { name: 'Services', path: '/services' },
    { name: 'Blog', path: '/blog' },
    { name: 'How It Works', path: '/how-it-works' },
    { name: 'Features', path: '/features' },
  ];

  const supportLinks = [
    { name: 'Help Center', path: '/help' },
    { name: 'Safety', path: '/safety' },
    { name: 'Terms of Service', path: '/terms' },
    { name: 'Privacy Policy', path: '/privacy' },
  ];

  const businessLinks = [
    { name: 'Admin Panel', path: 'https://quikgroceries.web.app/', icon: BarChart3, isExternal: true },
    { name: 'Partner', path: '/PartnerWithUs', icon: Users },
    { name: 'Delivery Partner', path: '/delivery-partner', icon: Bike },
  ];

  const socialLinks = [
    { icon: Facebook, href: '#', label: 'Facebook' },
    { icon: Instagram, href: '#', label: 'Instagram' },
    { icon: Twitter, href: '#', label: 'Twitter' },
    { icon: Linkedin, href: '#', label: 'LinkedIn' },
  ];

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

  return (
    <footer className="relative bg-gradient-to-b from-gray-900 via-gray-900 to-gray-950 text-white overflow-hidden">
      {/* Background gradient blobs */}
      <div className="absolute inset-0 opacity-5 pointer-events-none">
        <div className="absolute -top-20 -left-20 w-96 h-96 bg-primary-500 rounded-full filter blur-3xl" />
        <div className="absolute -bottom-20 -right-20 w-96 h-96 bg-accent-500 rounded-full filter blur-3xl" />
      </div>

      {/* Main Footer Content */}
      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 lg:py-24">
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-8 lg:gap-12 mb-12"
        >
          {/* Brand Section */}
          <motion.div variants={itemVariants} className="lg:col-span-2">
            <div className="mb-8">
              <img
                src="/images/logo-full.png"
                alt="Quick Groceries Logo"
                width="120"
                height="120"
                className="h-20 w-auto mb-4"
              />
            </div>

            <p className="text-gray-400 text-sm leading-relaxed mb-6">
              Fresh groceries delivered to your doorstep in Bhongir, Telangana. Experience fast, reliable, and convenient online grocery shopping.
            </p>

            {/* Contact Info */}
            <div className="space-y-3">
              <div className="flex items-start space-x-3 group">
                <MapPin className="w-4 h-4 text-primary-400 flex-shrink-0 mt-1" />
                <span className="text-sm text-gray-400 group-hover:text-gray-300 transition-colors">
                  Bhongir, Telangana, India
                </span>
              </div>
              <div className="flex items-center space-x-3 group">
                <Phone className="w-4 h-4 text-primary-400 flex-shrink-0" />
                <a href="tel:+919493803361" className="text-sm text-gray-400 group-hover:text-primary-400 transition-colors font-medium">
                  +91 94938 03361
                </a>
              </div>
              <div className="flex items-center space-x-3 group">
                <Mail className="w-4 h-4 text-primary-400 flex-shrink-0" />
                <a href="mailto:support@quickgroceries.in" className="text-sm text-gray-400 group-hover:text-primary-400 transition-colors font-medium">
                  support@quickgroceries.in
                </a>
              </div>
            </div>
          </motion.div>

          {/* Company Links */}
          <motion.div variants={itemVariants}>
            <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6">Company</h3>
            <ul className="space-y-4">
              {companyLinks.map((link) => (
                <li key={link.name}>
                  <Link
                    to={link.path}
                    className="text-sm text-gray-400 hover:text-primary-400 transition-colors duration-200 inline-flex items-center group"
                  >
                    <span className="group-hover:translate-x-1 transition-transform duration-200">{link.name}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </motion.div>

          {/* Support Links */}
          <motion.div variants={itemVariants}>
            <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6">Support</h3>
            <ul className="space-y-4">
              {supportLinks.map((link) => (
                <li key={link.name}>
                  <Link
                    to={link.path}
                    className="text-sm text-gray-400 hover:text-primary-400 transition-colors duration-200 inline-flex items-center group"
                  >
                    <span className="group-hover:translate-x-1 transition-transform duration-200">{link.name}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </motion.div>

          {/* Business Portal */}
          <motion.div variants={itemVariants}>
            <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6">Business</h3>
            <ul className="space-y-4">
              {businessLinks.map((link) => {
                const Icon = link.icon;
                const linkProps = {
                  className: "text-sm text-gray-400 hover:text-primary-400 transition-colors duration-200 inline-flex items-center space-x-2 group",
                };

                const content = (
                  <>
                    <Icon className="w-4 h-4 opacity-70 group-hover:opacity-100 transition-opacity" />
                    <span className="group-hover:translate-x-1 transition-transform duration-200">{link.name}</span>
                  </>
                );

                return (
                  <li key={link.name}>
                    {link.isExternal ? (
                      <a href={link.path} target="_blank" rel="noopener noreferrer" {...linkProps}>
                        {content}
                      </a>
                    ) : (
                      <Link to={link.path} {...linkProps}>
                        {content}
                      </Link>
                    )}
                  </li>
                );
              })}
            </ul>
          </motion.div>

          {/* Download App Section */}
          <motion.div variants={itemVariants}>
            <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6">Get App</h3>
            <div className="space-y-3">
              <a
                href="https://play.google.com/store/apps/details?id=com.quickgrocery.io"
                target="_blank"
                rel="noopener noreferrer"
                className="group block"
              >
                <div className="bg-gradient-to-r from-gray-800 to-gray-700 hover:from-gray-700 hover:to-gray-600 px-4 py-3 rounded-lg transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl">
                  <div className="flex items-center space-x-2">
                    <Download className="w-4 h-4 text-primary-400" />
                    <div className="text-left">
                      <div className="text-xs text-gray-400">Download on</div>
                      <div className="text-sm font-semibold text-white">Google Play</div>
                    </div>
                  </div>
                </div>
              </a>

              <p className="text-xs text-gray-500 mt-4">
                🌟 <span className="text-gray-400">Rated 4.8/5</span><br />
                📱 <span className="text-gray-400">10K+ Downloads</span>
              </p>
            </div>
          </motion.div>
        </motion.div>

        {/* Divider */}
        <div className="h-px bg-gradient-to-r from-transparent via-gray-700 to-transparent mb-12" />

        {/* Bottom Strip */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          className="flex flex-col md:flex-row items-center justify-between gap-6"
        >
          {/* Status Badge */}
          <motion.div variants={itemVariants}>
            <div className="inline-flex items-center space-x-2 px-4 py-2 bg-gray-800/50 backdrop-blur-sm rounded-full border border-gray-700 hover:border-gray-600 transition-colors">
              <div className="flex space-x-1">
                {[0, 1, 2].map((i) => (
                  <div
                    key={i}
                    className="w-2 h-2 rounded-full bg-green-500 animate-pulse"
                    style={{ animationDelay: `${i * 0.15}s` }}
                  />
                ))}
              </div>
              <span className="text-xs text-gray-400">All systems operational</span>
            </div>
          </motion.div>

          {/* Copyright & Credits */}
          <motion.div variants={itemVariants} className="text-center md:text-center text-xs text-gray-500">
            <p>
              © 2026 Quick Groceries. All rights reserved. |
              <span className="mx-2">Developed by</span>
              <a
                href="https://www.houseofscalers.com/"
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary-400 hover:text-primary-300 transition-colors font-medium inline"
              >
                House Of Scalers
              </a>
            </p>
          </motion.div>

          {/* Social Links */}
          <motion.div variants={itemVariants} className="flex items-center space-x-4">
            {socialLinks.map(({ icon: Icon, href, label }) => (
              <motion.a
                key={label}
                href={href}
                whileHover={{ scale: 1.15, y: -2 }}
                whileTap={{ scale: 0.9 }}
                className="w-10 h-10 bg-gray-800 hover:bg-primary-600 rounded-lg flex items-center justify-center transition-all duration-300 shadow-lg hover:shadow-primary-500/50 group"
                aria-label={label}
              >
                <Icon className="w-5 h-5 text-gray-400 group-hover:text-white transition-colors" />
              </motion.a>
            ))}
          </motion.div>
        </motion.div>
      </div>

      {/* Top gradient line */}
      <div className="absolute top-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-primary-500/30 to-transparent" />
    </footer>
  );
};

export default Footer;
