import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Apple, Download, Star, TrendingUp, Users, ShoppingBag } from 'lucide-react';
import PhoneMockup from './PhoneMockup';

const Hero = () => {
  const floatingIcons = [
    { Icon: ShoppingBag, delay: 0, position: 'top-16 left-8 md:top-20 md:left-10', color: 'text-primary-500' },
    { Icon: Star, delay: 0.2, position: 'top-32 right-16 md:top-40 md:right-20', color: 'text-accent-500' },
    { Icon: TrendingUp, delay: 0.4, position: 'bottom-32 left-16 md:bottom-40 md:left-20', color: 'text-primary-600' },
    { Icon: Users, delay: 0.6, position: 'bottom-16 right-8 md:bottom-20 md:right-10', color: 'text-accent-600' },
  ];

  return (
    <section id="home" className="relative min-h-screen pt-20 sm:pt-24 md:pt-28 lg:pt-24 xl:pt-28 2xl:pt-32 overflow-hidden bg-gradient-to-br from-lemon-100 via-lemon-50 to-lemon-100">
      <div className="absolute inset-0 opacity-30">
        <div className="absolute top-16 left-8 md:top-20 md:left-10 w-60 h-60 md:w-72 md:h-72 bg-primary-300 rounded-full mix-blend-multiply filter blur-3xl animate-pulse-slow" />
        <div className="absolute top-32 right-8 md:top-40 md:right-10 w-60 h-60 md:w-72 md:h-72 bg-accent-300 rounded-full mix-blend-multiply filter blur-3xl animate-pulse-slow animation-delay-2000" />
        <div className="absolute bottom-16 left-1/2 md:bottom-20 w-60 h-60 md:w-72 md:h-72 bg-primary-200 rounded-full mix-blend-multiply filter blur-3xl animate-pulse-slow animation-delay-4000" />
      </div>

      {floatingIcons.map(({ Icon, delay, position, color }, index) => (
        <motion.div
          key={index}
          initial={{ opacity: 0, scale: 0 }}
          animate={{ opacity: 0.3, scale: 1 }}
          transition={{ delay: delay + 0.5, duration: 0.8 }}
          className={`absolute ${position} hidden lg:block`}
        >
          <motion.div
            animate={{
              y: [0, -20, 0],
              rotate: [0, 10, -10, 0]
            }}
            transition={{
              duration: 4,
              repeat: Infinity,
              delay: delay
            }}
          >
            <Icon className={`w-12 h-12 ${color}`} />
          </motion.div>
        </motion.div>
      ))}

      <div className="relative max-w-7xl mx-auto container-padding">
        <div className="grid lg:grid-cols-2 gap-8 md:gap-10 lg:gap-12 items-center min-h-screen py-8 md:py-10 lg:py-0">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.8 }}
            className="space-y-4 sm:space-y-5 md:space-y-6 lg:space-y-7 text-center lg:text-left"
          >
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="inline-flex items-center space-x-2 bg-primary-100 px-4 py-2 rounded-full"
            >
              <Star className="w-4 h-4 text-primary-600 fill-primary-600" />
              <span className="text-sm font-semibold text-primary-700">
                4.8★ Rated by 50,000+ Users
              </span>
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="text-4xl sm:text-5xl lg:text-6xl xl:text-7xl font-display font-bold leading-tight"
            >
              <span className="sr-only">Quick Groceries - </span>
              Get Fresh Groceries in{' '}
              <span className="text-gradient-hero block mt-2">
                Bhongir, Telangana
              </span>
            </motion.h1>

            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="text-lg lg:text-xl text-gray-600 max-w-xl mx-auto lg:mx-0"
            >
              Download the app for quick orders, live tracking, and same-day delivery in Bhongir.
              Fresh produce, dairy, bakery, and essentials — all at your fingertips.
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              className="flex flex-col sm:flex-row gap-3 md:gap-4 justify-center lg:justify-start"
            >
              <motion.button
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
                className="group px-8 py-4 bg-black text-white rounded-2xl font-semibold shadow-xl hover:shadow-2xl transition-all duration-300 flex items-center justify-center space-x-3"
              >
                <Apple className="w-6 h-6" />
                <div className="text-left">
                  <div className="text-xs opacity-80">Download on the</div>
                  <div className="text-lg font-bold">App Store</div>
                </div>
              </motion.button>

              <motion.a
                href="https://play.google.com/store/apps/details?id=com.quickgrocery.io"
                target="_blank"
                rel="noopener noreferrer"
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
                className="group px-8 py-4 gradient-fresh text-white rounded-2xl font-semibold shadow-xl hover:shadow-glow-hover transition-all duration-300 flex items-center justify-center space-x-3"
              >
                <Download className="w-6 h-6" />
                <div className="text-left">
                  <div className="text-xs opacity-90">GET IT ON</div>
                  <div className="text-lg font-bold">Google Play</div>
                </div>
              </motion.a>
            </motion.div>

            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.6 }}
              className="flex items-center justify-center lg:justify-start space-x-4 md:space-x-6 pt-3 md:pt-4"
            >
              <div className="flex -space-x-3">
                {[1, 2, 3, 4].map((i) => (
                  <div
                    key={i}
                    className="w-10 h-10 rounded-full bg-gradient-to-br from-primary-400 to-primary-600 border-2 border-white"
                  />
                ))}
              </div>
              <div className="text-left">
                <div className="font-bold text-gray-900">50,000+</div>
                <div className="text-sm text-gray-600">Happy Customers</div>
              </div>
            </motion.div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.8, delay: 0.3 }}
            className="relative flex justify-center items-center"
          >
            <div className="absolute -top-8 -right-4 hidden md:block w-56 lg:w-64 h-72 rounded-3xl overflow-hidden shadow-2xl border-4 border-white/80">
              <img
                src="https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=90"
                alt="Fresh groceries delivered quickly"
                className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
                loading="eager"
              />
            </div>
            <PhoneMockup />
          </motion.div>
        </div>
      </div>
    </section>
  );
};

export default Hero;
