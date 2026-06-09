import React from 'react';
import { motion } from 'framer-motion';
import { ShoppingCart, Clock, Star, Truck, Phone, MessageCircle, MapPin } from 'lucide-react';

const BhongirGroceryDelivery = () => {
  return (
    <div className="min-h-screen bg-lemon-50">
      {/* Hero Section */}
      <section className="py-16 lg:py-24 bg-gradient-to-br from-primary-600 via-primary-700 to-primary-800 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <motion.h1 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-4xl lg:text-6xl font-display font-bold mb-6"
            >
              Quick Grocery Delivery in Bhongir, Telangana
            </motion.h1>
            <motion.p 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="text-xl lg:text-2xl text-white/90 max-w-4xl mx-auto mb-8"
            >
              Get fresh groceries, vegetables & daily essentials delivered in 30 minutes in Bhongir. 
              Your local online supermarket for instant grocery delivery.
            </motion.p>
            
            {/* CTA Buttons */}
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.4 }}
              className="flex flex-col sm:flex-row gap-4 justify-center items-center"
            >
              <a
                href="https://wa.me/919493803361"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center space-x-2 bg-green-500 hover:bg-green-600 text-white px-8 py-4 rounded-full font-semibold shadow-lg transition-all duration-300"
              >
                <MessageCircle className="w-5 h-5" />
                <span>Order via WhatsApp</span>
              </a>
              <a
                href="tel:+919493803361"
                className="flex items-center space-x-2 bg-white text-primary-700 px-8 py-4 rounded-full font-semibold shadow-lg hover:shadow-xl transition-all duration-300"
              >
                <Phone className="w-5 h-5" />
                <span>Call Now: +91 94938 03361</span>
              </a>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Online Grocery Delivery Section */}
      <section className="py-16 lg:py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <motion.h2 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-3xl lg:text-4xl font-display font-bold text-gray-900 mb-6"
            >
              Online Grocery Delivery in Bhongir
            </motion.h2>
            <p className="text-lg text-gray-600 max-w-3xl mx-auto">
              Experience the convenience of online grocery shopping in Bhongir. 
              Order fresh groceries from our online supermarket and get them delivered to your doorstep in Bhongir.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {[
              {
                icon: ShoppingCart,
                title: "Easy Online Ordering",
                description: "Browse our wide range of fresh groceries online in Bhongir. Order vegetables, fruits, dairy, and daily essentials with just a few clicks."
              },
              {
                icon: Truck,
                title: "Fast Delivery",
                description: "Our delivery service in Bhongir ensures your groceries reach you within 30 minutes. Same-day delivery available throughout Bhongir."
              },
              {
                icon: Star,
                title: "Quality Guaranteed",
                description: "We source fresh vegetables and quality products for grocery delivery in Bhongir. Best quality guaranteed for every order."
              }
            ].map((feature, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.2 }}
                className="bg-white p-8 rounded-2xl shadow-lg text-center"
              >
                <feature.icon className="w-12 h-12 text-primary-600 mx-auto mb-4" />
                <h3 className="text-xl font-bold text-gray-900 mb-4">{feature.title}</h3>
                <p className="text-gray-600">{feature.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Fresh Vegetables Section */}
      <section className="py-16 lg:py-24 bg-lemon-100">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <motion.h2 
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                className="text-3xl lg:text-4xl font-display font-bold text-gray-900 mb-6"
              >
                Fresh Vegetables & Daily Essentials in Bhongir
              </motion.h2>
              <div className="space-y-4">
                <p className="text-gray-600">
                  Our grocery delivery service in Bhongir brings you the freshest vegetables, fruits, 
                  and daily essentials right to your door. We understand the needs of Bhongir residents 
                  and provide quality products for your daily needs.
                </p>
                <p className="text-gray-600">
                  From fresh vegetables delivery in Bhongir to milk and grocery delivery, 
                  we cover all your daily essentials. Our local suppliers in Bhongir ensure 
                  the best quality products for our online supermarket.
                </p>
              </div>
            </div>
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              className="bg-white p-8 rounded-2xl shadow-lg"
            >
              <h3 className="text-xl font-bold text-gray-900 mb-4">What We Deliver in Bhongir</h3>
              <ul className="space-y-3">
                {[
                  "Fresh Vegetables & Fruits",
                  "Milk & Dairy Products", 
                  "Bakery Items",
                  "Daily Essentials & Household Items",
                  "Grocery Store Items"
                ].map((item, index) => (
                  <li key={index} className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-primary-600 rounded-full"></div>
                    <span className="text-gray-700">{item}</span>
                  </li>
                ))}
              </ul>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Instant Delivery Section */}
      <section className="py-16 lg:py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <motion.h2 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-3xl lg:text-4xl font-display font-bold text-gray-900 mb-6"
            >
              Instant & Same-Day Grocery Delivery
            </motion.h2>
            <p className="text-lg text-gray-600 max-w-3xl mx-auto">
              Our instant grocery delivery service in Bhongir ensures you get your groceries 
              when you need them. Same-day delivery available for all orders in Bhongir, Telangana.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {[
              { icon: Clock, title: "30 Min Delivery", desc: "Fast delivery in Bhongir" },
              { icon: Truck, title: "Same Day", desc: "Order today, delivered today" },
              { icon: Star, title: "Quality", desc: "Best quality products in Bhongir" },
              { icon: ShoppingCart, title: "Convenient", desc: "Easy online ordering" }
            ].map((item, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1 }}
                className="bg-white p-6 rounded-xl shadow-lg text-center"
              >
                <item.icon className="w-8 h-8 text-primary-600 mx-auto mb-3" />
                <h4 className="font-bold text-gray-900 mb-2">{item.title}</h4>
                <p className="text-gray-600 text-sm">{item.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Why Choose Us Section */}
      <section className="py-16 lg:py-24 bg-gradient-to-br from-primary-600 to-primary-700 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <motion.h2 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-3xl lg:text-4xl font-display font-bold mb-6"
            >
              Why Choose Quick Groceries in Bhongir
            </motion.h2>
            <p className="text-xl text-white/90 max-w-3xl mx-auto">
              We are the best grocery shop in Bhongir, offering instant delivery and quality products.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              "Local & Fresh Products",
              "Fast 30-Min Delivery",
              "Quality Guaranteed",
              "Best Prices in Bhongir",
              "Easy Online Ordering",
              "Reliable Service"
            ].map((benefit, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1 }}
                className="bg-white/10 backdrop-blur-sm p-6 rounded-xl text-center"
              >
                <div className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Star className="w-6 h-6 text-white" />
                </div>
                <h3 className="font-bold text-lg mb-2">{benefit}</h3>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Order Online Section */}
      <section className="py-16 lg:py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <motion.h2 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="text-3xl lg:text-4xl font-display font-bold text-gray-900 mb-6"
            >
              Order Groceries Online in Bhongir
            </motion.h2>
            <p className="text-lg text-gray-600 max-w-3xl mx-auto mb-8">
              Our online supermarket in Bhongir makes grocery shopping easy and convenient. 
              Order fresh groceries online and get them delivered to your doorstep in Bhongir.
            </p>
            
            <motion.div 
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="flex flex-col sm:flex-row gap-4 justify-center items-center"
            >
              <a
                href="https://play.google.com/store/apps/details?id=com.quickgrocery.io"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center space-x-2 bg-black text-white px-8 py-4 rounded-full font-semibold shadow-lg hover:shadow-xl transition-all duration-300"
              >
                <ShoppingCart className="w-5 h-5" />
                <span>Download App</span>
              </a>
              <a
                href="https://wa.me/919493803361"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center space-x-2 bg-green-500 hover:bg-green-600 text-white px-8 py-4 rounded-full font-semibold shadow-lg transition-all duration-300"
              >
                <MessageCircle className="w-5 h-5" />
                <span>WhatsApp Order</span>
              </a>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section className="py-16 bg-gray-900 text-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center">
            <h2 className="text-3xl font-display font-bold mb-8">Contact Quick Groceries Bhongir</h2>
            <div className="grid md:grid-cols-3 gap-8 max-w-4xl mx-auto">
              <div className="flex flex-col items-center">
                <Phone className="w-8 h-8 mb-2" />
                <span className="text-lg">+91 94938 03361</span>
                <span className="text-gray-400 text-sm">Call for orders</span>
              </div>
              <div className="flex flex-col items-center">
                <MessageCircle className="w-8 h-8 mb-2" />
                <span className="text-lg">WhatsApp</span>
                <span className="text-gray-400 text-sm">Click to chat</span>
              </div>
              <div className="flex flex-col items-center">
                <MapPin className="w-8 h-8 mb-2" />
                <span className="text-lg">Bhongir</span>
                <span className="text-gray-400 text-sm">Telangana, India</span>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default BhongirGroceryDelivery;