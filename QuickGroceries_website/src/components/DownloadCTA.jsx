import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Apple, Download, Smartphone, QrCode, X } from 'lucide-react';

const DownloadCTA = () => {
  const [showQR, setShowQR] = useState(false);

  return (
    <section className="relative py-20 lg:py-32 bg-gradient-to-br from-primary-600 via-primary-700 to-primary-800 overflow-hidden">
      <div className="absolute inset-0 opacity-20">
        <div className="absolute top-10 left-10 w-72 h-72 bg-white rounded-full mix-blend-overlay filter blur-3xl animate-pulse-slow" />
        <div className="absolute bottom-10 right-10 w-72 h-72 bg-accent-300 rounded-full mix-blend-overlay filter blur-3xl animate-pulse-slow" />
      </div>

      <div className="absolute inset-0 opacity-10">
        <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <pattern id="cta-pattern" width="60" height="60" patternUnits="userSpaceOnUse">
              <circle cx="30" cy="30" r="2" fill="white" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#cta-pattern)" />
        </svg>
      </div>

      <div className="relative max-w-7xl mx-auto container-padding">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center"
        >
          <motion.div
            initial={{ scale: 0 }}
            whileInView={{ scale: 1 }}
            viewport={{ once: true }}
            transition={{ type: "spring", stiffness: 200, delay: 0.2 }}
            className="inline-flex items-center justify-center w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full mb-6"
          >
            <Smartphone className="w-10 h-10 text-white" />
          </motion.div>

          <h2 className="text-3xl sm:text-4xl lg:text-6xl font-display font-bold text-white mb-6">
            Get Fresh Groceries Delivered
            <br />
            <span className="text-lemon-200">Right to Your Door</span>
          </h2>

          <p className="text-xl text-white/90 max-w-3xl mx-auto mb-12">
            Download the app for quick orders, live tracking, and same-day delivery.
            <br />
            Available on iOS and Android.
          </p>

          <div className="mb-12 max-w-5xl mx-auto rounded-3xl overflow-hidden shadow-2xl border-4 border-white h-96 md:h-[500px]">
            <img
              src="https://images.unsplash.com/photo-1607252650355-f7fd0460ccdb?auto=format&fit=crop&w=1800&q=90"
              alt="Download Quick Groceries mobile app"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
              loading="eager"
            />
          </div>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center mb-12">
            <motion.a
              href="#"
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
              className="group px-8 py-4 bg-black text-white rounded-2xl font-semibold shadow-2xl hover:shadow-3xl transition-all duration-300 flex items-center space-x-3 min-w-[200px]"
            >
              <Apple className="w-7 h-7" />
              <div className="text-left">
                <div className="text-xs opacity-80">Download on the</div>
                <div className="text-lg font-bold">App Store</div>
              </div>
            </motion.a>

            <motion.a
              href="https://play.google.com/store/apps/details?id=com.quickgrocery.io"
              target="_blank"
              rel="noopener noreferrer"
              whileHover={{ scale: 1.05, y: -2 }}
              whileTap={{ scale: 0.95 }}
              className="group px-8 py-4 bg-white text-primary-700 rounded-2xl font-semibold shadow-2xl hover:shadow-3xl transition-all duration-300 flex items-center space-x-3 min-w-[200px]"
            >
              <Download className="w-7 h-7" />
              <div className="text-left">
                <div className="text-xs opacity-80">GET IT ON</div>
                <div className="text-lg font-bold">Google Play</div>
              </div>
            </motion.a>
          </div>

          <motion.a
            whileHover={{ scale: 1.05, y: -2 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => setShowQR(!showQR)}
            className="inline-flex items-center space-x-2 px-6 py-3 bg-white/10 backdrop-blur-sm text-white rounded-full font-semibold hover:bg-white/20 transition-all duration-300"
          >
            <QrCode className="w-5 h-5" />
            <span>Or Scan QR Code</span>
          </motion.a>

          <AnimatePresence>
            {showQR && (
              <motion.div
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.8 }}
                className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm"
                onClick={() => setShowQR(false)}
              >
                <motion.div
                  initial={{ y: 50 }}
                  animate={{ y: 0 }}
                  exit={{ y: 50 }}
                  onClick={(e) => e.stopPropagation()}
                  className="bg-white rounded-3xl p-8 max-w-sm mx-4 relative"
                >
                  <button
                    onClick={() => setShowQR(false)}
                    className="absolute top-4 right-4 w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center hover:bg-gray-200 transition-colors"
                  >
                    <X className="w-5 h-5 text-gray-700" />
                  </button>

                  <h3 className="text-2xl font-bold text-gray-900 mb-4 text-center">
                    Scan to Download
                  </h3>

                  <div className="w-64 h-64 bg-gray-100 rounded-2xl flex items-center justify-center mb-4 mx-auto">
                    <QrCode className="w-48 h-48 text-gray-400" />
                  </div>

                  <p className="text-center text-gray-600 text-sm">
                    Scan this QR code with your phone camera to download the app
                  </p>
                </motion.div>
              </motion.div>
            )}
          </AnimatePresence>

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.4 }}
            className="mt-16 grid sm:grid-cols-3 gap-8 max-w-4xl mx-auto"
          >
            {[
              { value: '4.8★', label: 'App Store Rating' },
              { value: '50K+', label: 'Downloads' },
              { value: '5K+', label: 'Active Users' },
            ].map((stat, index) => (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, scale: 0.8 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ delay: 0.5 + index * 0.1 }}
                className="text-center"
              >
                <div className="text-4xl lg:text-5xl font-display font-bold text-white mb-2">
                  {stat.value}
                </div>
                <p className="text-white/80 font-medium">{stat.label}</p>
              </motion.div>
            ))}
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
};

export default DownloadCTA;
