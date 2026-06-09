import React from 'react';
import { motion } from 'framer-motion';
import { Check, Zap, Crown, Sparkles } from 'lucide-react';

const Pricing = () => {
  const plans = [
    {
      name: 'Basic',
      icon: Zap,
      price: '0',
      period: 'Free Forever',
      description: 'Perfect for trying out our service',
      features: [
        'Standard delivery',
        'Browse all products',
        'Email support',
        'Order tracking',
        'Basic rewards',
      ],
      color: 'from-gray-600 to-gray-800',
      popular: false,
    },
    {
      name: 'Premium',
      icon: Crown,
      price: '9.99',
      period: 'per month',
      description: 'Most popular for regular shoppers',
      features: [
        'Free delivery on all orders',
        'Priority customer support',
        'Exclusive deals & discounts',
        'Early access to new products',
        'Premium rewards program',
        'Extended return window',
      ],
      color: 'from-primary-500 to-primary-700',
      popular: true,
    },
    {
      name: 'Family',
      icon: Sparkles,
      price: '19.99',
      period: 'per month',
      description: 'Best value for families',
      features: [
        'Everything in Premium',
        'Up to 5 family members',
        'Shared shopping lists',
        'Family meal planning',
        'Bulk order discounts',
        'Dedicated account manager',
        'VIP customer support',
      ],
      color: 'from-accent-500 to-accent-600',
      popular: false,
    },
  ];

  return (
    <section id="pricing" className="relative py-20 lg:py-32 bg-white overflow-hidden">
      <div className="absolute inset-0 opacity-5">
        <div className="absolute top-0 left-0 w-full h-full">
          <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <pattern id="pricing-grid" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="currentColor" strokeWidth="1" className="text-primary-500" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#pricing-grid)" />
          </svg>
        </div>
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
            Pricing Plans
          </motion.span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-display font-bold text-gray-900 mb-6">
            Choose Your <span className="text-gradient">Perfect Plan</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            Select the plan that best fits your needs. All plans include access to our full catalog of fresh groceries.
          </p>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-8 lg:gap-6">
          {plans.map((plan, index) => (
            <motion.div
              key={plan.name}
              initial={{ opacity: 0, y: 50 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              whileHover={{ y: -10, scale: plan.popular ? 1.02 : 1 }}
              className={`relative bg-white rounded-3xl shadow-xl hover:shadow-2xl transition-all duration-300 overflow-hidden ${
                plan.popular ? 'ring-2 ring-primary-500 md:scale-105' : ''
              }`}
            >
              {plan.popular && (
                <motion.div
                  initial={{ y: -100 }}
                  animate={{ y: 0 }}
                  className="absolute top-0 left-0 right-0 bg-gradient-to-r from-primary-500 to-primary-700 text-white text-center py-2 text-sm font-semibold"
                >
                  Most Popular
                </motion.div>
              )}

              <div className={`p-8 ${plan.popular ? 'pt-12' : ''}`}>
                <motion.div
                  initial={{ scale: 0 }}
                  whileInView={{ scale: 1 }}
                  viewport={{ once: true }}
                  transition={{ delay: index * 0.1 + 0.2, type: "spring", stiffness: 200 }}
                  className={`w-16 h-16 bg-gradient-to-br ${plan.color} rounded-2xl flex items-center justify-center mb-6 shadow-lg`}
                >
                  <plan.icon className="w-8 h-8 text-white" />
                </motion.div>

                <h3 className="text-2xl font-display font-bold text-gray-900 mb-2">
                  {plan.name}
                </h3>
                <p className="text-gray-600 text-sm mb-6">
                  {plan.description}
                </p>

                <div className="mb-6">
                  <div className="flex items-baseline">
                    <span className="text-5xl font-display font-bold text-gray-900">
                      ₹{plan.price}
                    </span>
                    <span className="text-gray-600 ml-2">/{plan.period}</span>
                  </div>
                </div>

                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  className={`w-full py-4 rounded-xl font-semibold shadow-lg transition-all duration-300 mb-8 ${
                    plan.popular
                      ? 'gradient-primary text-white hover:shadow-glow'
                      : 'bg-gray-100 text-gray-900 hover:bg-gray-200'
                  }`}
                >
                  Get Started
                </motion.button>

                <div className="space-y-4">
                  <p className="text-sm font-semibold text-gray-900 mb-3">
                    What's included:
                  </p>
                  {plan.features.map((feature, i) => (
                    <motion.div
                      key={feature}
                      initial={{ opacity: 0, x: -20 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: index * 0.1 + 0.3 + i * 0.05 }}
                      className="flex items-start space-x-3"
                    >
                      <div className={`w-5 h-5 bg-gradient-to-br ${plan.color} rounded-full flex items-center justify-center flex-shrink-0 mt-0.5`}>
                        <Check className="w-3 h-3 text-white" />
                      </div>
                      <span className="text-gray-700 text-sm">{feature}</span>
                    </motion.div>
                  ))}
                </div>
              </div>
            </motion.div>
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="mt-12 text-center"
        >
          <p className="text-gray-600">
            All plans include a <span className="font-semibold text-primary-600">30-day money-back guarantee</span>. 
            Cancel anytime, no questions asked.
          </p>
        </motion.div>
      </div>
    </section>
  );
};

export default Pricing;
