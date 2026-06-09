/**
 * SEO Configuration
 * Centralized keywords, meta descriptions, and metadata for all pages
 */

export const SITE_NAME = "Quick Groceries";
export const SITE_URL = "https://quickgroceries.in";
export const DOMAIN = "quickgroceries.in";
export const PHONE = "+91-XXXXXXXXXX";

// Logo and images
export const LOGOS = {
    full: `${SITE_URL}/images/logo-full.png`,
    transparent: `${SITE_URL}/images/logo-trp.png`,
    favicon: `${SITE_URL}/images/logo.png`
};

// Primary keywords for SEO targeting
export const PRIMARY_KEYWORDS = {
    main: [
        "online grocery delivery",
        "grocery delivery near me",
        "30 minute grocery delivery",
        "quick commerce india",
        "grocery app india"
    ],
    local: [
        "grocery delivery in bhongir",
        "grocery delivery telangana",
        "grocery near me open now",
        "vegetables delivery bhongir",
        "fresh groceries bhongir",
        "dairy delivery bhongir",
        "online grocery bhongir"
    ],
    business: [
        "become grocery partner",
        "delivery partner jobs india",
        "dark store business india",
        "quick commerce partnership",
        "delivery partner earnings"
    ]
};

// Page metadata - includes title, description, keywords, and structured content
export const PAGE_META = {
    home: {
        title: "Online Grocery Delivery in Bhongir | Quick Groceries - 30 Min Delivery",
        description: "Order fresh groceries online with 30-minute delivery in Bhongir, Telangana. Fresh vegetables, fruits, dairy, bakery & daily essentials at best prices. Download Quick Groceries app.",
        keywords: "online grocery delivery, grocery delivery near me, groceries online, Bhongir, Telangana, same-day delivery, fresh groceries",
        ogTitle: "Quick Groceries - Fresh Grocery Delivery in Bhongir | 30-Min Guarantee",
        ogDescription: "Get fresh groceries delivered to your doorstep in 30 minutes. Order fresh vegetables, fruits, dairy, bakery items & daily essentials online.",
        ogImage: LOGOS.transparent,
        schema: "Organization"
    },
    about: {
        title: "About Quick Groceries | Fresh Grocery Delivery Service in Bhongir",
        description: "Learn about Quick Groceries mission to revolutionize grocery delivery. We provide fast, reliable, and affordable grocery delivery in Bhongir with fresh produce and daily essentials.",
        keywords: "about quick groceries, grocery delivery service, fresh groceries, Bhongir delivery, local grocery service",
        ogTitle: "About Quick Groceries - Fast Grocery Delivery Service",
        ogDescription: "Discover how Quick Groceries is changing the way people shop for groceries with fast, reliable, and affordable delivery.",
        ogImage: LOGOS.full,
        schema: "Organization"
    },
    services: {
        title: "Grocery Delivery Services | Fresh Vegetables, Fruits & Dairy | Quick Groceries",
        description: "Discover our grocery delivery services including fresh vegetables, fruits, dairy, bakery items, and daily essentials. Fast delivery in Bhongir, Telangana.",
        keywords: "grocery delivery services, fresh vegetables delivery, fruits delivery, dairy products, bakery items, daily essentials, Bhongir",
        ogTitle: "Grocery Delivery Services - Fresh Products Delivered",
        ogDescription: "Shop for fresh vegetables, fruits, dairy, bakery items, and daily essentials with fast delivery.",
        ogImage: LOGOS.transparent,
        schema: "Service"
    },
    howItWorks: {
        title: "How It Works | Quick Grocery Delivery Process | Quick Groceries",
        description: "Easy 3-step process: Download app, place order, get delivery in 30 minutes. Learn how Quick Groceries makes grocery shopping fast and convenient.",
        keywords: "how grocery delivery works, quick delivery process, place order, 30 minute delivery, easy ordering",
        ogTitle: "How Quick Groceries Works - Easy 3-Step Process",
        ogDescription: "Simple process: Download app → Place order → Get delivery in 30 minutes",
        ogImage: LOGOS.transparent,
        schema: "HowTo"
    },
    features: {
        title: "Features | Fresh Groceries, Fast Delivery, Best Prices | Quick Groceries",
        description: "Quick Groceries features: 30-minute delivery guarantee, fresh produce selection, real-time tracking, secure payments, and best prices in Bhongir.",
        keywords: "grocery app features, 30 minute delivery, fresh groceries, real-time tracking, price comparison, easy checkout",
        ogTitle: "Quick Groceries Features - Premium Grocery Delivery",
        ogDescription: "Experience the best grocery delivery with 30-min guarantee, fresh produce, live tracking, and secure payments.",
        ogImage: LOGOS.transparent,
        schema: "Product"
    },
    testimonials: {
        title: "Customer Reviews | Happy Customers | Quick Groceries",
        description: "See what thousands of customers love about Quick Groceries. Read reviews, ratings, and testimonials from Bhongir residents.",
        keywords: "customer reviews, testimonials, grocery app reviews, quick grocery ratings, customer satisfaction",
        ogTitle: "Customer Reviews & Testimonials - Quick Groceries",
        ogDescription: "Thousands of happy customers sharing their Quick Groceries delivery experience.",
        ogImage: LOGOS.transparent,
        schema: "AggregateRating"
    },
    download: {
        title: "Download Quick Groceries App | iOS & Android | Free Delivery",
        description: "Download Quick Groceries app for iOS and Android. Get exclusive offers, track orders in real-time, and enjoy fast grocery delivery.",
        keywords: "download grocery app, quick groceries app, iOS app, Android app, mobile app download",
        ogTitle: "Download Quick Groceries App - Get Fast Delivery Now",
        ogDescription: "Download the Quick Groceries app and get your first order delivered in 30 minutes.",
        ogImage: LOGOS.transparent,
        schema: "SoftwareApplication"
    },
    deliveryBhongir: {
        title: "Grocery Delivery in Bhongir | Fresh Online Groceries | Quick Groceries",
        description: "Order fresh groceries online in Bhongir with 30-minute fast delivery. Shop vegetables, fruits, dairy, bakery & essentials at best prices.",
        keywords: "grocery delivery bhongir, fresh groceries bhongir, vegetables delivery bhongir, online shopping bhongir, quick delivery telangana",
        ogTitle: "Grocery Delivery in Bhongir - Fast 30-Min Delivery",
        ogDescription: "Get fresh groceries delivered in Bhongir in just 30 minutes. Vegetables, fruits, dairy, bakery & daily essentials.",
        ogImage: LOGOS.transparent,
        schema: "LocalBusiness"
    },
    partner: {
        title: "Become a Delivery Partner | Jobs | Quick Groceries Partner Program",
        description: "Join Quick Groceries as a delivery partner. Flexible hours, good earnings, and app-based work. Apply now for delivery partner jobs in Bhongir.",
        keywords: "delivery partner jobs, quick commerce jobs, delivery jobs india, part time work, gig economy jobs, bharati",
        ogTitle: "Delivery Partner Program - Earn with Quick Groceries",
        ogDescription: "Flexible work as a delivery partner. Good earnings, easy sign-up. Join Quick Groceries today.",
        ogImage: LOGOS.transparent,
        schema: "JobPosting"
    },
    blog: {
        title: "Blog | Grocery Tips, Recipes & Quick Commerce Updates | Quick Groceries",
        description: "Read articles about grocery shopping tips, recipe ideas, healthy eating, and updates on quick commerce industry.",
        keywords: "grocery blog, recipes, shopping tips, quick commerce news, food tips",
        ogTitle: "Blog - Grocery Tips & Quick Commerce Updates",
        ogDescription: "Discover tips, recipes, and insights about grocery shopping and quick delivery.",
        ogImage: LOGOS.transparent,
        schema: "Blog"
    },
    help: {
        title: "Help Center | FAQ | Quick Groceries Support",
        description: "Find answers to frequently asked questions about Quick Groceries app, delivery, products, and orders.",
        keywords: "help center, faq, support, customer service, how to use, troubleshooting",
        ogTitle: "Help Center & FAQ - Quick Groceries Support",
        ogDescription: "Get help with your Quick Groceries orders and questions.",
        ogImage: LOGOS.transparent,
        schema: "FAQPage"
    },
    safety: {
        title: "Safety & Hygiene | Trusted Grocery Delivery | Quick Groceries",
        description: "Learn about our safety measures, hygiene standards, and quality assurance for grocery delivery.",
        keywords: "food safety, hygiene, quality assurance, trusted delivery, customer safety",
        ogTitle: "Safety & Hygiene - Quick Groceries Quality Promise",
        ogDescription: "We prioritize safety and hygiene in every delivery.",
        ogImage: LOGOS.transparent,
        schema: "Organization"
    },
    privacy: {
        title: "Privacy Policy | Data Protection | Quick Groceries",
        description: "Read our privacy policy to understand how Quick Groceries protects your personal information and data.",
        keywords: "privacy policy, data protection, personal information, security",
        ogTitle: "Privacy Policy - Quick Groceries",
        ogDescription: "Data privacy and protection at Quick Groceries.",
        ogImage: LOGOS.transparent,
        schema: "WebPage"
    },
    terms: {
        title: "Terms of Service | Quick Groceries",
        description: "Read the terms of service for using Quick Groceries app and services.",
        keywords: "terms of service, terms and conditions, user agreement",
        ogTitle: "Terms of Service - Quick Groceries",
        ogDescription: "Terms and conditions for Quick Groceries services.",
        ogImage: LOGOS.transparent,
        schema: "WebPage"
    }
};

// Social media links for schema
export const SOCIAL_MEDIA = {
    facebook: "https://facebook.com/quickgroceries",
    instagram: "https://instagram.com/quickgroceries",
    twitter: "https://twitter.com/quickgroceries",
    youtube: "https://youtube.com/@quickgroceries",
    linkedin: "https://linkedin.com/company/quickgroceries"
};

// Local keywords for different locations
export const LOCAL_KEYWORDS = {
    bhongir: {
        primary: "grocery delivery in bhongir",
        variations: [
            "vegetables delivery bhongir",
            "fruits delivery bhongir",
            "dairy delivery bhongir",
            "grocery near me bhongir",
            "online grocery bhongir",
            "quick grocery bhongir"
        ]
    },
    telangana: {
        primary: "grocery delivery in telangana",
        variations: [
            "online groceries telangana",
            "quick commerce telangana",
            "vegetable delivery telangana"
        ]
    }
};

// FAQ content for schema
export const FAQ_CONTENT = [
    {
        question: "How fast is the delivery?",
        answer: "We guarantee 30-minute delivery for most items in Bhongir. Some items may take longer depending on availability and location."
    },
    {
        question: "What payment methods do you accept?",
        answer: "We accept all major payment methods including credit cards, debit cards, digital wallets, UPI, and cash on delivery."
    },
    {
        question: "Is there a delivery fee?",
        answer: "Free delivery on orders above ₹200. Standard delivery fee is ₹30 for orders below ₹200."
    },
    {
        question: "How can I track my order?",
        answer: "Use real-time order tracking in the Quick Groceries app. You'll receive updates via SMS and push notifications."
    },
    {
        question: "What if my order is late?",
        answer: "If delivery exceeds 30 minutes, we'll provide store credit or a refund. Your satisfaction is guaranteed."
    },
    {
        question: "Are the products fresh?",
        answer: "Yes, all our products are sourced fresh daily from verified suppliers and quality checked."
    }
];

// Blog topics for SEO
export const BLOG_TOPICS = [
    {
        slug: "future-of-quick-commerce-india",
        title: "The Future of Quick Commerce in India: Trends & Insights",
        description: "Explore how quick commerce is revolutionizing retail in India and what the future holds.",
        keywords: ["quick commerce", "india retail", "grocery delivery trends"]
    },
    {
        slug: "grocery-delivery-business-model",
        title: "Understanding the Grocery Delivery Business Model",
        description: "Deep dive into how grocery delivery platforms operate and make profit.",
        keywords: ["business model", "delivery service", "quick commerce"]
    },
    {
        slug: "how-dark-stores-work",
        title: "How Dark Stores Work in Quick Commerce",
        description: "Learn about dark stores and their role in fast grocery delivery.",
        keywords: ["dark stores", "fulfillment", "quick delivery"]
    },
    {
        slug: "delivery-partner-earnings",
        title: "Delivery Partner Earnings: How Much Can You Make?",
        description: "Guide to delivery partner income and earning potential.",
        keywords: ["delivery partner", "gig work", "earnings"]
    },
    {
        slug: "quick-commerce-startup",
        title: "How to Start a Quick Commerce Grocery Delivery Startup",
        description: "Comprehensive guide for starting your own quick commerce business.",
        keywords: ["startup", "entrepreneurship", "quick commerce"]
    },
    {
        slug: "healthy-grocery-shopping",
        title: "Tips for Healthy Grocery Shopping Online",
        description: "Expert tips for choosing healthy groceries and planning meals.",
        keywords: ["healthy eating", "nutrition", "shopping tips"]
    }
];

// Service descriptions with keywords
export const SERVICES_DETAILED = {
    vegetables: {
        name: "Fresh Vegetables",
        description: "100% fresh, handpicked vegetables delivered daily. Premium quality vegetables sourced from local farmers.",
        keywords: ["fresh vegetables", "organic vegetables", "vegetable delivery", "quality produce"]
    },
    fruits: {
        name: "Premium Fruits",
        description: "Seasonal and exotic fruits delivered fresh. Handpicked for quality and ripeness.",
        keywords: ["fresh fruits", "fruit delivery", "seasonal fruits", "quality fruits"]
    },
    dairy: {
        name: "Dairy & Bakery",
        description: "Fresh milk, yogurt, cheese, and baked goods. Quality products from trusted suppliers.",
        keywords: ["dairy products", "milk delivery", "bakery items", "dairy delivery"]
    },
    essentials: {
        name: "Daily Essentials",
        description: "All your daily essentials - rice, dal, oil, spices, and more. Competitive prices and quality assured.",
        keywords: ["daily essentials", "grocery items", "pantry staples", "food essentials"]
    }
};

// Long-tail keywords for SEO
export const LONGTAIL_KEYWORDS = [
    "best grocery delivery app in bhongir",
    "fastest grocery delivery in bhongir",
    "grocery stores that deliver in bhongir",
    "online vegetable shopping bhongir",
    "fresh vegetables online delivery bhongir",
    "cheapest grocery delivery near me",
    "grocery delivery open now near me",
    "best online grocery service in india",
    "30 minute grocery delivery guarantee",
    "same day grocery delivery bhongir"
];
