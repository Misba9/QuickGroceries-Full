import React from 'react';
import { motion } from 'framer-motion';
import { Search, ShoppingCart, Truck, CheckCircle, ArrowRight } from 'lucide-react';

const HowItWorks = () => {
  const steps = [
    {
      icon: Search,
      title: 'Browse & Search',
      description: 'Explore our wide range of fresh products. Use filters to find exactly what you need.',
      color: 'from-accent-500 to-accent-600',
    },
    {
      icon: ShoppingCart,
      title: 'Add to Cart',
      description: 'Select your items and add them to your cart. Adjust quantities as needed.',
      color: 'from-primary-400 to-primary-600',
    },
    {
      icon: Truck,
      title: 'Fast Delivery',
      description: 'Our delivery team picks, packs, and delivers your order with care.',
      color: 'from-accent-500 to-accent-600',
    },
    {
      icon: CheckCircle,
      title: 'Enjoy Fresh Food',
      description: 'Receive your groceries at your doorstep. Fresh, on-time, every time.',
      color: 'from-primary-500 to-primary-700',
    },
  ];

  return (
    <section id="how-it-works" className="relative py-20 lg:py-32 bg-lemon-50 overflow-hidden">
      <div className="absolute inset-0">
        <svg className="absolute top-0 left-0 w-full h-full opacity-5" xmlns="http://www.w3.org/2000/svg">
          <defs>
            <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
              <path d="M 40 0 L 0 0 0 40" fill="none" stroke="currentColor" strokeWidth="1" className="text-primary-500" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#grid)" />
        </svg>
      </div>

      <div className="relative max-w-7xl mx-auto container-padding">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <motion.span
            initial={{ opacity: 0, scale: 0.8 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="inline-block px-4 py-2 bg-primary-100 text-primary-700 rounded-full text-sm font-semibold mb-4"
          >
            Simple Process
          </motion.span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-display font-bold text-gray-900 mb-6">
            How It <span className="text-gradient-hero">Works</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            Getting fresh groceries delivered in Bhongir, Telangana has never been easier. Just follow these simple steps for same-day delivery.
          </p>
        </motion.div>

        <div className="mb-16 max-w-6xl mx-auto">
          <div className="rounded-3xl overflow-hidden shadow-2xl border-4 border-primary-300 h-96 md:h-[500px]">
            <img
              src="https://images.unsplash.com/photo-1494412685616-a5d310fbb07d?auto=format&fit=crop&w=1800&q=90"
              alt="Grocery delivery workflow"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
              loading="eager"
            />
          </div>
        </div>

        <div className="relative">
          <div className="hidden lg:block absolute top-1/2 left-0 right-0 h-1 bg-gradient-to-r from-accent-500 via-primary-500 to-accent-500 -translate-y-1/2 opacity-20" />

          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-8 lg:gap-4">
            {steps.map((step, index) => (
              <motion.div
                key={step.title}
                initial={{ opacity: 0, y: 50 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: index * 0.15 }}
                className="relative"
              >
                <motion.div
                  whileHover={{ y: -10 }}
                  className="relative bg-white rounded-2xl p-6 shadow-lg hover:shadow-2xl transition-all duration-300 group"
                >
                  <div className="absolute -top-6 left-1/2 -translate-x-1/2">
                    <motion.div
                      initial={{ scale: 0 }}
                      whileInView={{ scale: 1 }}
                      viewport={{ once: true }}
                      transition={{
                        type: "spring",
                        stiffness: 200,
                        delay: index * 0.15 + 0.2
                      }}
                      whileHover={{ rotate: 360 }}
                      className={`w-16 h-16 bg-gradient-to-br ${step.color} rounded-2xl flex items-center justify-center shadow-xl`}
                    >
                      <step.icon className="w-8 h-8 text-white" />
                    </motion.div>
                  </div>

                  <div className="absolute -top-3 -right-3 w-8 h-8 bg-gradient-to-br from-primary-500 to-primary-700 rounded-full flex items-center justify-center text-white font-bold text-sm shadow-lg">
                    {index + 1}
                  </div>

                  <div className="mt-8 text-center">
                    <h3 className="text-xl font-bold text-gray-900 mb-3">
                      {step.title}
                    </h3>
                    <p className="text-gray-600 text-sm leading-relaxed">
                      {step.description}
                    </p>
                  </div>

                  {index < steps.length - 1 && (
                    <div className="hidden lg:block absolute top-1/2 -right-8 -translate-y-1/2">
                      <motion.div
                        animate={{ x: [0, 5, 0] }}
                        transition={{ duration: 1.5, repeat: Infinity }}
                      >
                        <ArrowRight className="w-6 h-6 text-primary-300" />
                      </motion.div>
                    </div>
                  )}
                </motion.div>
              </motion.div>
            ))}
          </div>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="mt-16 text-center"
        >
          <motion.a
            href="https://play.google.com/store/apps/details?id=com.quickgrocery.io"
            target="_blank"
            rel="noopener noreferrer"
            whileHover={{ scale: 1.05, y: -2 }}
            whileTap={{ scale: 0.95 }}
            className="px-8 py-4 gradient-fresh text-white rounded-full font-semibold shadow-xl hover:shadow-glow-hover transition-all duration-300 inline-flex items-center space-x-2"
          >
            <span>Download App & Get Started</span>
            <ArrowRight className="w-5 h-5" />
          </motion.a>
        </motion.div>
      </div>
    </section>
  );
};

export default HowItWorks;
