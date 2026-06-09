import React, { useEffect } from 'react';
import { Routes, Route, useLocation } from 'react-router-dom';
import Navbar from './components/Navbar';
import Hero from './components/Hero';
import About from './components/About';
import Services from './components/Services';
import HowItWorks from './components/HowItWorks';
import Features from './components/Features';
import AppScreens from './components/AppScreens';
import Testimonials from './components/Testimonials';
// import Pricing from './components/Pricing';
import DownloadCTA from './components/DownloadCTA';
import Footer from './components/Footer';
import ParticleBackground from './components/ParticleBackground';
import BhongirGroceryDelivery from './components/BhongirGroceryDelivery';
import PartnerWithUs from './components/PartnerWithUs';
import DeliveryPartner from './components/DeliveryPartner';
import Blog from './components/Blog';
import HelpCenter from './components/HelpCenter';
import Safety from './components/Safety';
import TermsOfService from './components/TermsOfService';
import PrivacyPolicy from './components/PrivacyPolicy';
import SEOProvider from './context/SEOProvider';

function AppContent() {
  const location = useLocation();

  useEffect(() => {
    const observerOptions = {
      threshold: 0.1,
      rootMargin: '0px 0px -100px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
        }
      });
    }, observerOptions);

    const animatedElements = document.querySelectorAll('.animate-on-scroll');
    animatedElements.forEach(el => observer.observe(el));

    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    window.scrollTo({ top: 0, left: 0, behavior: 'smooth' });
  }, [location.pathname]);

  return (
    <div className="min-h-screen bg-lemon-50 overflow-x-hidden">
      <ParticleBackground />
      <header>
        <Navbar />
      </header>
      <main>
        <Routes>
          <Route path="/" element={
            <>
              <Hero />
              <About />
              <Services />
              <HowItWorks />
              <Features />
              <AppScreens />
              <Testimonials />
              {/* <Pricing /> */}
              <DownloadCTA />
            </>
          } />
          <Route path="/about" element={<About />} />
          <Route path="/services" element={<Services />} />
          <Route path="/how-it-works" element={<HowItWorks />} />
          <Route path="/features" element={<Features />} />
          <Route path="/testimonials" element={<Testimonials />} />
          <Route path="/download" element={<DownloadCTA />} />
          <Route path="/quick-grocery-delivery-bhongir" element={<BhongirGroceryDelivery />} />
          <Route path="/PartnerWithUs" element={<PartnerWithUs />} />
          <Route path="/delivery-partner" element={<DeliveryPartner />} />
          <Route path="/blog" element={<Blog />} />
          <Route path="/help" element={<HelpCenter />} />
          <Route path="/safety" element={<Safety />} />
          <Route path="/terms" element={<TermsOfService />} />
          <Route path="/privacy" element={<PrivacyPolicy />} />
        </Routes>
      </main>
      <footer>
        <Footer />
      </footer>
    </div>
  );
}

function App() {
  return (
    <SEOProvider>
      <AppContent />
    </SEOProvider>
  );
}

export default App;
