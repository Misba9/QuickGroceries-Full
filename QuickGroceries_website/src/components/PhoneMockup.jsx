import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ShoppingCart, Search, Heart, Clock } from 'lucide-react';

const PhoneMockup = () => {
  const [currentScreen, setCurrentScreen] = useState(0);

  const screens = [
    {
      id: 1,
      title: 'Browse Fresh Produce',
      content: (
        <div className="space-y-2">
          <div className="flex items-center space-x-1 bg-white/80 backdrop-blur-sm p-1 rounded-md">
            <Search className="w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search groceries..."
              className="bg-transparent flex-1 outline-none text-sm"
              disabled
            />
          </div>
          <div className="grid grid-cols-2 gap-1">
            {['Tomatoes', 'Broccoli', 'Carrots', 'Lettuce'].map((item, i) => (
              <div key={i} className="bg-white/90 backdrop-blur-sm p-1 rounded-md">
                <div className="w-12 h-12 bg-gradient-to-br from-primary-100 to-primary-200 rounded-sm mb-1" />
                <p className="text-xs font-semibold text-gray-800">{item}</p>
                <p className="text-xs text-primary-600 font-bold">₹{(2.99 + i * 0.5).toFixed(2)}</p>
              </div>
            ))}
          </div>
        </div>
      ),
    },
    {
      id: 2,
      title: 'Add to Cart',
      content: (
        <div className="space-y-2">
          {['Fresh Tomatoes', 'Organic Milk', 'Whole Grain Bread'].map((item, i) => (
            <div key={i} className="bg-white/90 backdrop-blur-sm p-1 rounded-md flex items-center space-x-1">
              <div className="w-8 h-8 bg-gradient-to-br from-primary-100 to-primary-200 rounded-sm" />
              <div className="flex-1">
                <p className="text-sm font-semibold text-gray-800">{item}</p>
                <p className="text-xs text-gray-500">Qty: {i + 1}</p>
              </div>
              <p className="text-sm font-bold text-primary-600">₹{(3.99 + i * 2).toFixed(2)}</p>
            </div>
          ))}
          <button className="w-full py-1 gradient-primary text-white rounded-md font-semibold text-xs">
            Checkout - ₹15.97
          </button>
        </div>
      ),
    },
    {
      id: 3,
      title: 'Track Delivery',
      content: (
        <div className="space-y-2">
          <div className="bg-white/90 backdrop-blur-sm p-2 rounded-md">
            <div className="flex items-center justify-between mb-3">
              <p className="text-sm font-semibold text-gray-800">Order #12345</p>
              <span className="px-2 py-1 bg-primary-100 text-primary-700 text-xs font-semibold rounded-full">
                In Transit
              </span>
            </div>
            <div className="space-y-3">
              <div className="flex items-start space-x-3">
                <div className="w-5 h-5 rounded-full bg-primary-500 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <p className="text-xs font-semibold text-gray-800">Order Confirmed</p>
                  <p className="text-xs text-gray-500">10:30 AM</p>
                </div>
              </div>
              <div className="flex items-start space-x-3">
                <div className="w-5 h-5 rounded-full bg-primary-500 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <p className="text-xs font-semibold text-gray-800">Out for Delivery</p>
                  <p className="text-xs text-gray-500">11:15 AM</p>
                </div>
              </div>
              <div className="flex items-start space-x-3">
                <div className="w-5 h-5 rounded-full border-2 border-primary-300 flex-shrink-0 mt-0.5" />
                <div className="flex-1">
                  <p className="text-xs font-semibold text-gray-400">Delivered</p>
                  <p className="text-xs text-gray-400">Est. 12:00 PM</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      ),
    },
  ];

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentScreen((prev) => (prev + 1) % screens.length);
    }, 3500);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="relative">
      <motion.div
        animate={{ 
          y: [0, -15, 0],
          rotate: [0, 2, -2, 0] 
        }}
        transition={{ 
          duration: 5,
          repeat: Infinity,
          ease: "easeInOut" 
        }}
        className="relative z-10"
      >
        <div className="w-[200px] h-[350px] bg-gradient-to-br from-gray-800 to-gray-900 rounded-[2rem] p-2 shadow-lg">
          <div className="w-full h-full bg-gradient-to-br from-primary-400 to-primary-600 rounded-[1.5rem] overflow-hidden relative">
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-20 h-4 bg-gray-900 rounded-b-xl z-20" />
            
            <div className="h-full p-3 pt-6 overflow-hidden">
              <AnimatePresence mode="wait">
                <motion.div
                  key={currentScreen}
                  initial={{ opacity: 0, x: 100 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -100 }}
                  transition={{ duration: 0.5 }}
                  className="h-full"
                >
                  <h3 className="text-white font-bold text-sm mb-2">
                    {screens[currentScreen].title}
                  </h3>
                  {screens[currentScreen].content}
                </motion.div>
              </AnimatePresence>
            </div>

            <div className="absolute bottom-2 left-1/2 -translate-x-1/2 flex space-x-2 z-20">
              {screens.map((_, index) => (
                <button
                  key={index}
                  onClick={() => setCurrentScreen(index)}
                  className={`w-2 h-2 rounded-full transition-all duration-300 ${
                    index === currentScreen
                      ? 'bg-white w-6'
                      : 'bg-white/50'
                  }`}
                />
              ))}
            </div>
          </div>
        </div>
      </motion.div>

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
        className="absolute -top-6 -right-6 w-20 h-20 bg-gradient-to-br from-accent-400 to-accent-600 rounded-full opacity-50 blur-lg"
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
        className="absolute -bottom-6 -left-6 w-24 h-24 bg-gradient-to-br from-primary-300 to-primary-500 rounded-full opacity-50 blur-lg"
      />
    </div>
  );
};

export default PhoneMockup;
