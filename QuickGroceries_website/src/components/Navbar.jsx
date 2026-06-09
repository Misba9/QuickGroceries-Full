import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { ShoppingCart, Menu, X, Apple, Download } from 'lucide-react';

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { name: 'Home', href: '/' },
    { name: 'About', href: '/about' },
    { name: 'Services', href: '/services' },
    { name: 'How It Works', href: '/how-it-works' },
    { name: 'Features', href: '/features' },
    // { name: 'Pricing', href: '/pricing' },
  ];

  return (
    <motion.nav
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      transition={{ duration: 0.6 }}
      className={`fixed w-full top-0 z-50 transition-all duration-300 ${isScrolled
          ? 'bg-lemon-100/90 backdrop-blur-md shadow-lg'
          : 'bg-transparent'
        }`}
    >
      <div className="max-w-7xl mx-auto container-padding">
        <div className="flex items-center justify-between h-16 lg:h-20">
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="flex items-center space-x-2 cursor-pointer"
          >
            <img
              src="/images/logo.png"
              alt="Quick Grocery Delivery in Bhongir Telangana"
              width="40"
              height="40"
              className="h-10 w-auto"
            />
            <div className="flex flex-col">
              <span className="text-xl lg:text-2xl font-display font-bold">
                <span className="text-accent-600">Quick</span>
                <span className="text-primary-700">Groceries</span>
              </span>
              <span className="text-xs text-gray-600">Order it, Get it</span>
            </div>
          </motion.div>

          <div className="hidden lg:flex items-center space-x-8">
            {navLinks.map((link, index) => (
              <motion.div
                key={link.name}
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                whileHover={{ y: -2 }}
                asChild
              >
                <Link
                  to={link.href}
                  className="text-gray-800 hover:text-primary-600 font-medium transition-colors relative group"
                  aria-label={link.name}
                >
                  {link.name}
                  <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-primary-500 transition-all duration-300 group-hover:w-full" />
                </Link>
              </motion.div>
            ))}
          </div>

          <div className="hidden lg:flex items-center space-x-3">
            <motion.a
              href="https://play.google.com/store/apps/details?id=com.quickgrocery.io"
              target="_blank"
              rel="noopener noreferrer"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              className="px-6 py-2.5 gradient-fresh text-white rounded-full font-semibold shadow-lg hover:shadow-glow-hover transition-all duration-300 flex items-center space-x-2"
            >
              <Download className="w-4 h-4" />
              <span>Download App</span>
            </motion.a>
          </div>

          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="lg:hidden p-3 rounded-lg hover:bg-lemon-100 transition-colors"
            aria-label="Toggle navigation menu"
          >
            {isMobileMenuOpen ? (
              <X className="w-6 h-6 text-gray-900" />
            ) : (
              <Menu className="w-6 h-6 text-gray-900" />
            )}
          </motion.button>
        </div>
      </div>

      {isMobileMenuOpen && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="lg:hidden bg-lemon-50 border-t border-lemon-100"
        >
          <div className="container-padding py-4 space-y-3">
            {navLinks.map((link) => (
              <Link
                key={link.name}
                to={link.href}
                onClick={() => setIsMobileMenuOpen(false)}
                className="block py-2 text-gray-800 hover:text-primary-600 font-medium transition-colors"
                aria-label={link.name}
              >
                {link.name}
              </Link>
            ))}
            <a
              href="https://play.google.com/store/apps/details?id=com.quickgrocery.io"
              target="_blank"
              rel="noopener noreferrer"
              className="w-full mt-4 px-6 py-3 gradient-fresh text-white rounded-full font-semibold shadow-lg flex items-center justify-center space-x-2 block"
            >
              <Download className="w-4 h-4" />
              <span>Download App</span>
            </a>
          </div>
        </motion.div>
      )}
    </motion.nav>
  );
};

export default Navbar;
