import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight, ShoppingCart, Search, User, Heart } from 'lucide-react';

const AppScreens = () => {
  const [currentScreen, setCurrentScreen] = useState(0);

  const screens = [
    {
      title: 'Browse Products',
      description: 'Explore thousands of fresh products with our intuitive interface',
      color: 'from-primary-500 to-primary-700',
      content: (
        <div className="space-y-2">
          <div className="flex items-center space-x-1 bg-white/90 backdrop-blur-sm p-1 rounded-md">
            <Search className="w-4 h-4 text-gray-400" />
            <input type="text" placeholder="Search..." className="bg-transparent text-xs flex-1 outline-none" disabled />
          </div>
          {[1, 2, 3].map((i) => (
            <div key={i} className="bg-white/90 backdrop-blur-sm p-2 rounded-md flex items-center space-x-2">
              <div className="w-10 h-10 bg-gradient-to-br from-primary-100 to-primary-200 rounded-md" />
              <div className="flex-1">
                <p className="text-xs font-semibold">Product {i}</p>
                <p className="text-xs text-primary-600">₹{(2.99 + i).toFixed(2)}</p>
              </div>
            </div>
          ))}
        </div>
      ),
    },
    {
      title: 'Shopping Cart',
      description: 'Manage your cart with ease and checkout in seconds',
      color: 'from-accent-500 to-accent-600',
      content: (
        <div className="space-y-2">
          {[1, 2].map((i) => (
            <div key={i} className="bg-white/90 backdrop-blur-sm p-2 rounded-md flex items-center space-x-2">
              <div className="w-12 h-12 bg-gradient-to-br from-purple-100 to-purple-200 rounded-lg" />
              <div className="flex-1">
                <p className="text-xs font-semibold">Item {i}</p>
                <p className="text-xs text-gray-500">Qty: {i}</p>
              </div>
              <p className="text-xs font-bold">₹{(5.99 * i).toFixed(2)}</p>
            </div>
          ))}
          <button className="w-full py-1 gradient-fresh text-white rounded-md text-xs font-semibold">
            Checkout - ₹11.98
          </button>
        </div>
      ),
    },
    {
      title: 'Order Tracking',
      description: 'Track your order in real-time from warehouse to doorstep',
      color: 'from-primary-400 to-primary-600',
      content: (
        <div className="space-y-2">
          <div className="bg-white/90 backdrop-blur-sm p-2 rounded-md">
            <div className="flex items-center justify-between mb-2">
              <p className="text-xs font-semibold">Order #12345</p>
              <span className="px-2 py-0.5 bg-primary-100 text-primary-700 text-xs rounded-full">Active</span>
            </div>
            <div className="space-y-1">
              {['Confirmed', 'Preparing', 'On the way'].map((status, i) => (
                <div key={status} className="flex items-center space-x-1">
                  <div className={`w-3 h-3 rounded-full ${i < 2 ? 'bg-primary-500' : 'border-2 border-primary-300'}`} />
                  <p className="text-xs text-gray-700">{status}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      ),
    },
    {
      title: 'User Profile',
      description: 'Manage your account, orders, and preferences',
      color: 'from-lemon-400 to-lemon-500',
      content: (
        <div className="space-y-2">
          <div className="bg-white/90 backdrop-blur-sm p-3 rounded-md text-center">
            <div className="w-12 h-12 bg-gradient-to-br from-accent-100 to-accent-200 rounded-full mx-auto mb-1" />
            <p className="text-sm font-semibold">John Doe</p>
            <p className="text-xs text-gray-500">john@example.com</p>
          </div>
          {['Orders', 'Favorites', 'Settings'].map((item) => (
            <div key={item} className="bg-white/90 backdrop-blur-sm p-2 rounded-md flex items-center justify-between">
              <p className="text-xs font-medium">{item}</p>
              <ChevronRight className="w-3 h-3 text-gray-400" />
            </div>
          ))}
        </div>
      ),
    },
  ];

  const nextScreen = () => {
    setCurrentScreen((prev) => (prev + 1) % screens.length);
  };

  const prevScreen = () => {
    setCurrentScreen((prev) => (prev - 1 + screens.length) % screens.length);
  };

  return (
    <section id="app-screens" className="relative py-16 lg:py-24 bg-white overflow-hidden">
      <div className="absolute inset-0 opacity-5">
        <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-primary-500 to-accent-500" />
      </div>

      <div className="relative max-w-7xl mx-auto container-padding">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <motion.span
            initial={{ opacity: 0, scale: 0.8 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="inline-block px-4 py-2 bg-primary-100 text-primary-700 rounded-full text-sm font-semibold mb-4"
          >
            App Preview
          </motion.span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-display font-bold text-gray-900 mb-6">
            Experience the <span className="text-gradient-hero">App</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            Swipe through our intuitive app interface and see how easy grocery shopping can be.
          </p>
        </motion.div>

        <div className="grid lg:grid-cols-2 gap-8 items-center">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="relative"
          >
            <div className="relative z-10 max-w-xs mx-auto">
              <div className="relative">
                <div className="w-full aspect-[9/14] bg-gradient-to-br from-gray-800 to-gray-900 rounded-[2rem] p-2 shadow-xl">
                  <div className={`w-full h-full bg-gradient-to-br ${screens[currentScreen].color} rounded-[1.5rem] overflow-hidden relative`}>
                    <div className="absolute top-0 left-1/2 -translate-x-1/2 w-20 h-4 bg-gray-900 rounded-b-xl z-20" />

                    <div className="h-full p-3 pt-6 overflow-hidden">
                      <AnimatePresence mode="wait">
                        <motion.div
                          key={currentScreen}
                          initial={{ opacity: 0, x: 100 }}
                          animate={{ opacity: 1, x: 0 }}
                          exit={{ opacity: 0, x: -100 }}
                          transition={{ duration: 0.3 }}
                          className="h-full"
                        >
                          <h3 className="text-white font-bold text-xs mb-2">
                            {screens[currentScreen].title}
                          </h3>
                          {screens[currentScreen].content}
                        </motion.div>
                      </AnimatePresence>
                    </div>
                  </div>
                </div>

                <div className="flex justify-center items-center space-x-3 mt-4">
                  <motion.button
                    type="button"
                    whileHover={{ scale: 1.1 }}
                    whileTap={{ scale: 0.9 }}
                    onClick={prevScreen}
                    className="w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center hover:shadow-xl transition-all z-10"
                    aria-label="Previous screen"
                  >
                    <ChevronLeft className="w-5 h-5 text-gray-700" />
                  </motion.button>

                  <div className="flex space-x-2">
                    {screens.map((_, index) => (
                      <button
                        type="button"
                        key={index}
                        onClick={() => setCurrentScreen(index)}
                        className={`h-2 rounded-full transition-all duration-300 ${index === currentScreen
                          ? 'bg-primary-600 w-8'
                          : 'bg-gray-300 w-2'
                          }`}
                        aria-label={`Go to screen ${index + 1}`}
                      />
                    ))}
                  </div>

                  <motion.button
                    type="button"
                    whileHover={{ scale: 1.1 }}
                    whileTap={{ scale: 0.9 }}
                    onClick={nextScreen}
                    className="w-10 h-10 bg-white rounded-full shadow-lg flex items-center justify-center hover:shadow-xl transition-all z-10"
                    aria-label="Next screen"
                  >
                    <ChevronRight className="w-5 h-5 text-gray-700" />
                  </motion.button>
                </div>
              </div>

              <motion.div
                animate={{
                  scale: [1, 1.1, 1],
                  rotate: [0, 5, -5, 0]
                }}
                transition={{
                  duration: 7,
                  repeat: Infinity,
                  ease: "easeInOut"
                }}
                className="absolute -top-6 -right-6 w-28 h-28 bg-gradient-to-br from-primary-300 to-primary-500 rounded-full opacity-30 blur-2xl"
              />
              <motion.div
                animate={{
                  scale: [1, 1.2, 1],
                  rotate: [0, -5, 5, 0]
                }}
                transition={{
                  duration: 6,
                  repeat: Infinity,
                  ease: "easeInOut",
                  delay: 0.5
                }}
                className="absolute -bottom-6 -left-6 w-28 h-28 bg-gradient-to-br from-accent-300 to-accent-500 rounded-full opacity-30 blur-2xl"
              />
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, x: 50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="space-y-4"
          >
            <div className="rounded-3xl overflow-hidden shadow-2xl border-4 border-primary-300 h-96 md:h-[600px]">
              <img
                src="https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=800&q=90"
                alt="Using the grocery app on a smartphone"
                className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
                loading="eager"
              />
            </div>
            <AnimatePresence mode="wait">
              <motion.div
                key={currentScreen}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -20 }}
                transition={{ duration: 0.3 }}
              >
                <h3 className="text-2xl lg:text-3xl font-display font-bold text-gray-900 mb-3">
                  {screens[currentScreen].title}
                </h3>
                <p className="text-base text-gray-600 mb-4">
                  {screens[currentScreen].description}
                </p>
              </motion.div>
            </AnimatePresence>

            <div className="grid grid-cols-2 gap-3">
              {[
                { icon: ShoppingCart, text: 'Easy Shopping', color: 'from-primary-500 to-primary-700' },
                { icon: Search, text: 'Smart Search', color: 'from-accent-500 to-accent-600' },
                { icon: Heart, text: 'Save Favorites', color: 'from-accent-400 to-accent-600' },
                { icon: User, text: 'User Profiles', color: 'from-primary-400 to-primary-600' },
              ].map((feature, index) => (
                <motion.div
                  key={feature.text}
                  initial={{ opacity: 0, scale: 0.8 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: index * 0.1 }}
                  whileHover={{ scale: 1.05 }}
                  className="bg-white rounded-lg p-3 shadow-md hover:shadow-lg transition-shadow"
                >
                  <div className={`w-8 h-8 bg-gradient-to-br ${feature.color} rounded-md flex items-center justify-center mb-2`}>
                    <feature.icon className="w-4 h-4 text-white" />
                  </div>
                  <p className="text-sm font-semibold text-gray-900">{feature.text}</p>
                </motion.div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
};

export default AppScreens;
