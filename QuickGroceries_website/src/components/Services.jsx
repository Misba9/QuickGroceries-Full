import React from 'react';
import { motion } from 'framer-motion';
import { Carrot, Milk, Croissant, Package } from 'lucide-react';

const Services = () => {
  const services = [
    {
      icon: Carrot,
      title: 'Fresh Vegetables',
      description: 'Farm-fresh organic vegetables delivered daily. From leafy greens to root vegetables.',
      image: 'linear-gradient(135deg, #17795A 0%, #0F6B4B 100%)',
      photo: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80',
      items: ['Tomatoes', 'Carrots', 'Broccoli', 'Spinach', 'Bell Peppers'],
    },
    {
      icon: Milk,
      title: 'Dairy Products',
      description: 'Premium dairy from local farms. Fresh milk, cheese, yogurt, and more.',
      image: 'linear-gradient(135deg, #FF5A56 0%, #FF3B3B 100%)',
      photo: 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=1200&q=80',
      items: ['Fresh Milk', 'Cheese', 'Yogurt', 'Butter', 'Cream'],
    },
    {
      icon: Croissant,
      title: 'Bakery Items',
      description: 'Freshly baked bread, pastries, and cakes. Baked daily with love.',
      image: 'linear-gradient(135deg, #FFC933 0%, #FFE066 100%)',
      photo: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',
      items: ['Bread', 'Croissants', 'Muffins', 'Cookies', 'Cakes'],
    },
    {
      icon: Package,
      title: 'Daily Essentials',
      description: 'All your daily necessities in one place. From snacks to household items.',
      image: 'linear-gradient(135deg, #0F6B4B 0%, #FF3B3B 100%)',
      photo: 'https://images.unsplash.com/photo-1601599561213-832382fd07ba?auto=format&fit=crop&w=1200&q=90',
      items: ['Rice & Grains', 'Spices', 'Snacks', 'Beverages', 'Cleaning'],
    },
  ];

  return (
    <section id="services" className="relative py-20 lg:py-32 bg-gradient-to-br from-lemon-50 to-lemon-100 overflow-hidden">
      <div className="absolute inset-0 opacity-30">
        <div className="absolute top-20 left-10 w-72 h-72 bg-primary-300 rounded-full mix-blend-multiply filter blur-3xl animate-pulse-slow" />
        <div className="absolute bottom-20 right-10 w-72 h-72 bg-accent-300 rounded-full mix-blend-multiply filter blur-3xl animate-pulse-slow" />
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
            Our Services
          </motion.span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-display font-bold text-gray-900 mb-6">
            What We <span className="text-gradient-hero">Deliver</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            From fresh farm produce to daily essentials in Bhongir, Telangana, we've got everything you need
            for a healthy lifestyle — all delivered to your doorstep in 30 minutes.
          </p>
        </motion.div>

        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-6 lg:gap-8">
          {services.map((service, index) => (
            <motion.div
              key={service.title}
              initial={{ opacity: 0, y: 50 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              whileHover={{ y: -10, scale: 1.02 }}
              className="group relative bg-white rounded-2xl overflow-hidden shadow-lg hover:shadow-2xl transition-all duration-300"
            >
              <div className="h-64 md:h-80 relative overflow-hidden">
                <img
                  src={service.photo}
                  alt={service.title}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                  loading="eager"
                />
                <div className="absolute inset-0 bg-gradient-to-br from-black/40 via-black/20 to-transparent" />
                <div className="absolute inset-0 flex items-center justify-center">
                  <service.icon className="w-20 h-20 text-white opacity-100" />
                </div>
              </div>

              <div className="p-6">
                <h3 className="text-xl font-bold text-gray-900 mb-2">
                  {service.title}
                </h3>
                <p className="text-gray-600 text-sm mb-4">
                  {service.description}
                </p>

                <div className="space-y-2">
                  {service.items.slice(0, 3).map((item, i) => (
                    <motion.div
                      key={item}
                      initial={{ opacity: 0, x: -20 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: 0.3 + i * 0.1 }}
                      className="flex items-center space-x-2 text-sm text-gray-500"
                    >
                      <div className="w-1.5 h-1.5 rounded-full bg-primary-500" />
                      <span>{item}</span>
                    </motion.div>
                  ))}
                  <p className="text-xs text-primary-600 font-semibold pt-2">
                    +{service.items.length - 3} more items
                  </p>
                </div>
              </div>

              <div className="absolute top-4 right-4">
                <motion.div
                  whileHover={{ rotate: 360 }}
                  transition={{ duration: 0.6 }}
                  className="w-12 h-12 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center shadow-lg"
                >
                  <service.icon className="w-6 h-6 text-primary-600" />
                </motion.div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Services;
