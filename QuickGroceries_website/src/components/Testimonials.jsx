import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Star, Quote, ChevronLeft, ChevronRight } from 'lucide-react';


const Testimonials = () => {
  const [currentIndex, setCurrentIndex] = useState(0);

  const testimonials = [
    {
      id: 1,
      name: "Saritha Reddy",
      role: "Software Engineer, Bhongir",
      image: "https://i.pravatar.cc/150?img=1",
      rating: 5,
      text: "Quick Groceries has completely transformed my shopping experience! As a working professional, I barely have time to shop. Now I get fresh produce delivered right to my doorstep in 30 minutes. Incredible service!"
    },
    {
      id: 2,
      name: "Rajesh Kumar",
      role: "Business Owner, Bhongir",
      image: "https://i.pravatar.cc/150?img=2",
      rating: 5,
      text: "The app is so easy to use and the delivery is always on time. I order groceries for my family every week. Best grocery service I've ever used in Bhongir!"
    },
    {
      id: 3,
      name: "Lakshmi Devi",
      role: "Homemaker, Bhongir",
      image: "https://i.pravatar.cc/150?img=3",
      rating: 5,
      text: "Amazing quality and lightning-fast delivery. The vegetables are so fresh and the fruits are perfectly ripe. I recommend Quick Groceries to all my friends and family in Telangana!"
    },
    {
      id: 4,
      name: "Suresh Naidu",
      role: "Teacher, Bhongir",
      image: "https://i.pravatar.cc/150?img=4",
      rating: 5,
      text: "The customer service is exceptional. They really care about quality and customer satisfaction. I had an issue with one order and they resolved it immediately. Great team!"
    },
    {
      id: 5,
      name: "Anusha Singh",
      role: "Doctor, Bhongir",
      image: "https://i.pravatar.cc/150?img=5",
      rating: 5,
      text: "Fresh vegetables, dairy products, everything is top quality. The app is very convenient for busy professionals like me. And the prices are very reasonable for the quality provided!"
    },
    {
      id: 6,
      name: "Venkat Rao",
      role: "Retired Government Officer, Bhongir",
      image: "https://i.pravatar.cc/150?img=6",
      rating: 5,
      text: "I love the live tracking feature. I can see exactly when my order will arrive. The delivery boys are very polite and professional. So convenient for senior citizens like me!"
    }
  ];

  const nextTestimonial = () => {
    setCurrentIndex((prev) => (prev + 1) % testimonials.length);
  };

  const prevTestimonial = () => {
    setCurrentIndex((prev) => (prev - 1 + testimonials.length) % testimonials.length);
  };

  useEffect(() => {
    const interval = setInterval(nextTestimonial, 5000);
    return () => clearInterval(interval);
  }, []);

  return (
    <section id="testimonials" className="relative py-20 lg:py-32 bg-gradient-to-br from-lemon-100 via-lemon-50 to-lemon-100 overflow-hidden">
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
            Testimonials
          </motion.span>
          <h2 className="text-3xl sm:text-4xl lg:text-5xl font-display font-bold text-gray-900 mb-6">
            What Our <span className="text-gradient-hero">Customers Say</span>
          </h2>
          <p className="text-lg text-gray-600 max-w-3xl mx-auto">
            Don't just take our word for it. Here's what our happy customers have to say about their experience.
          </p>
        </motion.div>

        <div className="mb-16 max-w-6xl mx-auto">
          <div className="rounded-3xl overflow-hidden shadow-2xl border-4 border-primary-300 h-96 md:h-[500px]">
            <img
              src="https://images.unsplash.com/photo-1529070538774-1843cb3265df?auto=format&fit=crop&w=1800&q=90"
              alt="Delivery partner handing groceries"
              className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
              loading="eager"
            />
          </div>
        </div>

        <div className="max-w-4xl mx-auto">
          <div className="relative">
            <AnimatePresence mode="wait">
              <motion.div
                key={currentIndex}
                initial={{ opacity: 0, x: 100 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -100 }}
                transition={{ duration: 0.5 }}
                className="bg-white rounded-3xl p-8 lg:p-12 shadow-2xl"
              >
                <div className="relative">
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ delay: 0.2, type: "spring", stiffness: 200 }}
                    className="absolute -top-4 -left-4 w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-700 rounded-2xl flex items-center justify-center shadow-lg"
                  >
                    <Quote className="w-8 h-8 text-white" />
                  </motion.div>

                  <div className="flex items-center space-x-1 mb-6 ml-14">
                    {[...Array(testimonials[currentIndex].rating)].map((_, i) => (
                      <motion.div
                        key={i}
                        initial={{ scale: 0, rotate: -180 }}
                        animate={{ scale: 1, rotate: 0 }}
                        transition={{ delay: 0.3 + i * 0.1 }}
                      >
                        <Star className="w-6 h-6 text-accent-500 fill-accent-500" />
                      </motion.div>
                    ))}
                  </div>

                  <motion.p
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.4 }}
                    className="text-xl lg:text-2xl text-gray-800 font-medium mb-8 leading-relaxed"
                  >
                    "{testimonials[currentIndex].text}"
                  </motion.p>

                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.5 }}
                    className="flex items-center space-x-4"
                  >
                    <motion.div
                      whileHover={{ scale: 1.1 }}
                      className="relative"
                    >
                      <div className="w-16 h-16 rounded-full overflow-hidden ring-4 ring-primary-100">
                        <img
                          src={testimonials[currentIndex].image}
                          alt={`Customer ${testimonials[currentIndex].name} from Bhongir using Quick Groceries`}
                          width="64"
                          height="64"
                          className="w-full h-full object-cover"
                          loading="lazy"
                        />
                      </div>
                      <div className="absolute -bottom-1 -right-1 w-6 h-6 bg-primary-500 rounded-full flex items-center justify-center border-2 border-white">
                        <Star className="w-3 h-3 text-white fill-white" />
                      </div>
                    </motion.div>
                    <div>
                      <h4 className="text-lg font-bold text-gray-900">
                        {testimonials[currentIndex].name}
                      </h4>
                      <p className="text-gray-600">
                        {testimonials[currentIndex].role}
                      </p>
                    </div>
                  </motion.div>
                </div>
              </motion.div>
            </AnimatePresence>

            <div className="absolute top-1/2 -translate-y-1/2 -left-4 lg:-left-16">
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                onClick={prevTestimonial}
                className="w-12 h-12 lg:w-14 lg:h-14 bg-white rounded-full shadow-xl flex items-center justify-center hover:shadow-2xl transition-shadow"
              >
                <ChevronLeft className="w-6 h-6 text-gray-700" />
              </motion.button>
            </div>

            <div className="absolute top-1/2 -translate-y-1/2 -right-4 lg:-right-16">
              <motion.button
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.9 }}
                onClick={nextTestimonial}
                className="w-12 h-12 lg:w-14 lg:h-14 bg-white rounded-full shadow-xl flex items-center justify-center hover:shadow-2xl transition-shadow"
              >
                <ChevronRight className="w-6 h-6 text-gray-700" />
              </motion.button>
            </div>
          </div>

          <div className="flex justify-center space-x-2 mt-8">
            {testimonials.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentIndex(index)}
                className={`h-2 rounded-full transition-all duration-300 ${index === currentIndex
                  ? 'bg-primary-600 w-8'
                  : 'bg-gray-300 w-2'
                  }`}
              />
            ))}
          </div>
        </div>

        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="grid sm:grid-cols-3 gap-6 mt-16"
        >
          {[
            { value: '50K+', label: 'Happy Users' },
            { value: '4.8★', label: 'App Rating' },
            { value: '99%', label: 'Satisfaction' },
          ].map((stat, index) => (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, scale: 0.8 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ delay: 0.7 + index * 0.1 }}
              whileHover={{ y: -5 }}
              className="bg-white rounded-2xl p-6 shadow-lg text-center"
            >
              <div className="text-3xl lg:text-4xl font-display font-bold text-gradient mb-2">
                {stat.value}
              </div>
              <p className="text-gray-600 font-medium">{stat.label}</p>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
};

export default Testimonials;
