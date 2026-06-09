import React, { useState, useEffect } from 'react';
import { motion, useInView } from 'framer-motion';
import { Clock, Shield, MapPin, Zap, HeadphonesIcon, Leaf } from 'lucide-react';

const AnimatedCounter = ({ end, duration = 2, inView }) => {
  const [count, setCount] = useState(0);

  useEffect(() => {
    if (!inView) return;

    let startTime;
    const animate = (currentTime) => {
      if (!startTime) startTime = currentTime;
      const progress = Math.min((currentTime - startTime) / (duration * 1000), 1);

      setCount(Math.floor(progress * end));

      if (progress < 1) {
        requestAnimationFrame(animate);
      }
    };

    requestAnimationFrame(animate);
  }, [end, duration, inView]);

  return <span>{count}</span>;
};

const Features = () => {
  const [ref, inView] = [React.useRef(null), true];

  const features = [
    {
      icon: Clock,
      title: '30-Min Delivery',
      description: 'Lightning-fast delivery to your doorstep. Order now, enjoy soon.',
      stat: '30',
      suffix: 'min',
      color: 'from-accent-500 to-accent-600',
    },
    {
      icon: Shield,
      title: '100% Safe',
      description: 'Contactless delivery and stringent hygiene protocols for your safety.',
      stat: '100',
      suffix: '%',
      color: 'from-primary-500 to-primary-700',
    },
    {
      icon: MapPin,
      title: 'Live Tracking',
      description: 'Track your order in real-time from warehouse to your doorstep.',
      stat: '24',
      suffix: '/7',
      color: 'from-primary-400 to-primary-600',
    },
    {
      icon: Zap,
      title: 'Instant Checkout',
      description: 'Seamless payment experience with multiple payment options.',
      stat: '5',
      suffix: 'sec',
      color: 'from-accent-500 to-accent-600',
    },
    {
      icon: HeadphonesIcon,
      title: '24/7 Support',
      description: 'Always here to help. Our customer support team is available round the clock.',
      stat: '24',
      suffix: '/7',
      color: 'from-accent-400 to-accent-600',
    },
    {
      icon: Leaf,
      title: 'Eco-Friendly',
      description: 'Sustainable packaging and green delivery practices for a better planet.',
      stat: '99',
      suffix: '%',
      color: 'from-primary-400 to-primary-600',
    },
  ];

  return (
    <section id="features" className="relative py-20 lg:py-32 bg-gradient-to-br from-lemon-50 to-lemon-100 overflow-hidden">
      <div className="absolute inset-0 opacity-30">
        <div className="absolute top-20 right-10 w-96 h-96 bg-primary-300 rounded-full mix-blend-multiply filter blur-3xl animate-pulse-slow" />
        <div className="absolute bottom-20 left-10 w-96 h-96 bg-accent-300 rounded-full mix-blend-multiply filter blur-3xl animate-pulse-slow" />
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
            Why Choose Us
          </motion.span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-display font-bold text-gray-900 mb-6">
            Amazing <span className="text-gradient-hero">Features</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            We're committed to providing the best grocery delivery experience with
            cutting-edge features and exceptional service.
          </p>
        </motion.div>

        <div className="mb-16 max-w-6xl mx-auto">
          <div className="rounded-3xl overflow-hidden shadow-2xl border-4 border-primary-300 h-96 md:h-[500px]">
            <img
              src="https://images.unsplash.com/photo-1580674285054-bed31e145f59?auto=format&fit=crop&w=1800&q=90"
              alt="Fast grocery fulfillment operations"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
              loading="eager"
            />
          </div>
        </div>

        <div ref={ref} className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6 lg:gap-8">
          {features.map((feature, index) => (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: index * 0.1 }}
              whileHover={{ y: -10, scale: 1.02 }}
              className="group relative bg-white rounded-2xl p-6 lg:p-8 shadow-lg hover:shadow-2xl transition-all duration-300"
            >
              <div className="absolute inset-0 bg-gradient-to-br from-primary-50 to-white rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300" />

              <div className="relative">
                <motion.div
                  initial={{ scale: 0 }}
                  whileInView={{ scale: 1 }}
                  viewport={{ once: true }}
                  transition={{
                    type: "spring",
                    stiffness: 200,
                    delay: index * 0.1 + 0.2
                  }}
                  whileHover={{ rotate: 360 }}
                  className={`w-16 h-16 bg-gradient-to-br ${feature.color} rounded-2xl flex items-center justify-center mb-6 shadow-lg`}
                >
                  <feature.icon className="w-8 h-8 text-white" />
                </motion.div>

                <div className="mb-4">
                  <motion.div
                    initial={{ scale: 0 }}
                    whileInView={{ scale: 1 }}
                    viewport={{ once: true }}
                    transition={{ delay: index * 0.1 + 0.3 }}
                    className="text-4xl font-display font-bold text-gradient-hero mb-1"
                  >
                    <AnimatedCounter end={parseInt(feature.stat)} inView={inView} />
                    {feature.suffix}
                  </motion.div>
                </div>

                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  {feature.title}
                </h3>
                <p className="text-gray-600 leading-relaxed">
                  {feature.description}
                </p>
              </div>

              <motion.div
                className="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                whileHover={{ scale: 1.2, rotate: 90 }}
              >
                <div className={`w-8 h-8 bg-gradient-to-br ${feature.color} rounded-lg opacity-20`} />
              </motion.div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Features;
