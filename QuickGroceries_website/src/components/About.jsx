import React from 'react';
import { motion } from 'framer-motion';
import { Heart, Target, Award, Sparkles } from 'lucide-react';

const About = () => {
  const values = [
    {
      icon: Heart,
      title: 'Customer First',
      description: 'Your satisfaction is our top priority. We go the extra mile to ensure quality and freshness.',
      color: 'from-accent-500 to-accent-600',
    },
    {
      icon: Target,
      title: 'Quality Guaranteed',
      description: 'We source only the finest products from trusted local farmers and suppliers.',
      color: 'from-primary-500 to-primary-700',
    },
    {
      icon: Award,
      title: 'Fast & Reliable',
      description: 'Same-day delivery with real-time tracking. Your groceries arrive fresh and on time.',
      color: 'from-primary-400 to-primary-600',
    },
    {
      icon: Sparkles,
      title: 'Sustainable',
      description: 'We are committed to eco-friendly practices and reducing our environmental impact.',
      color: 'from-lemon-400 to-lemon-500',
    },
  ];

  return (
    <section id="about" className="relative py-20 lg:py-32 bg-lemon-50 overflow-hidden">
      <div className="absolute inset-0 opacity-5">
        <div className="absolute top-0 left-0 w-96 h-96 bg-primary-500 rounded-full filter blur-3xl" />
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-accent-500 rounded-full filter blur-3xl" />
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
            About Quick Groceries
          </motion.span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-display font-bold text-gray-900 mb-6">
            Fresh Food, <span className="text-gradient-hero">Fast Delivery</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            Founded in 2020 in Bhongir, Telangana, Quick Groceries started with a simple mission: make fresh,
            quality groceries accessible to everyone. Today, we serve over 50,000 happy
            customers in Bhongir and surrounding areas, delivering farm-fresh produce right to your doorstep.
          </p>
        </motion.div>

        <div className="mb-16">
          <div className="relative max-w-6xl mx-auto rounded-3xl overflow-hidden shadow-2xl border-4 border-primary-300 h-96 md:h-[600px]">
            <img
              src="https://images.unsplash.com/photo-1534723452862-4c874018d66d?auto=format&fit=crop&w=1800&q=90"  alt="Fresh groceries packed for delivery"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
              loading="eager"
            />
          </div>
        </div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6 lg:gap-8">
          {values.map((value, index) => (
            <motion.div
              key={value.title}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              whileHover={{ y: -10 }}
              className="group relative bg-white rounded-2xl p-6 shadow-lg hover:shadow-2xl transition-all duration-300"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-primary-50 to-white rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

              <div className="relative">
                <motion.div
                  whileHover={{ rotate: 360 }}
                  transition={{ duration: 0.6 }}
                  className={`w-14 h-14 bg-gradient-to-br ${value.color} rounded-xl flex items-center justify-center mb-4 shadow-lg`}
                >
                  <value.icon className="w-7 h-7 text-white" />
                </motion.div>

                <h3 className="text-xl font-bold text-gray-900 mb-2">
                  {value.title}
                </h3>
                <p className="text-gray-600 text-sm leading-relaxed">
                  {value.description}
                </p>
              </div>
            </motion.div>
          ))}
        </div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.4 }}
          className="mt-16 grid md:grid-cols-3 gap-8 text-center"
        >
          {[
            { value: '50K+', label: 'Happy Customers' },
            { value: '500+', label: 'Products Available' },
            { value: '99%', label: 'Satisfaction Rate' },
          ].map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, scale: 0.5 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.5 + index * 0.1 }}
              className="p-6"
            >
              <motion.h3
                initial={{ scale: 0 }}
                whileInView={{ scale: 1 }}
                viewport={{ once: true }}
                transition={{
                  type: "spring",
                  stiffness: 200,
                  delay: 0.6 + index * 0.1
                }}
                className="text-4xl lg:text-5xl font-display font-bold text-gradient-hero mb-2"
              >
                {stat.value}
              </motion.h3>
              <p className="text-gray-600 font-medium">{stat.label}</p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
};

export default About;
