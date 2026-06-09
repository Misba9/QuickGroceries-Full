/**
 * SEO Schema Generators
 * Generates structured data (JSON-LD) for better search engine understanding
 */

export const generateOrganizationSchema = () => ({
    "@context": "https://schema.org",
    "@type": "Organization",
    "name": "Quick Groceries",
    "url": "https://quickgroceries.in",
    "logo": "https://quickgroceries.in/images/logo-full.png",
    "description": "Fast grocery delivery service in Bhongir, Telangana with 30-minute delivery guarantee",
    "sameAs": [
        "https://facebook.com/quickgroceries",
        "https://instagram.com/quickgroceries",
        "https://twitter.com/quickgroceries",
        "https://youtube.com/@quickgroceries"
    ],
    "contactPoint": {
        "@type": "ContactPoint",
        "telephone": "+91-XXXXXXXXXX",
        "contactType": "Customer Service"
    }
});

export const generateLocalBusinessSchema = () => ({
    "@context": "https://schema.org",
    "@type": "LocalBusiness",
    "name": "Quick Groceries",
    "image": "https://quickgroceries.in/images/logo-full.png",
    "description": "Online grocery delivery service in Bhongir, Telangana",
    "address": {
        "@type": "PostalAddress",
        "streetAddress": "Bhongir",
        "addressLocality": "Bhongir",
        "addressRegion": "Telangana",
        "postalCode": "508216",
        "addressCountry": "IN"
    },
    "telephone": "+91-XXXXXXXXXX",
    "url": "https://quickgroceries.in",
    "priceRange": "₹",
    "areaServed": {
        "@type": "City",
        "name": "Bhongir"
    },
    "serviceType": "Grocery Delivery",
    "openingHoursSpecification": {
        "@type": "OpeningHoursSpecification",
        "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
        "opens": "06:00",
        "closes": "23:00"
    }
});

export const generateBreadcrumbSchema = (items) => ({
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": items.map((item, index) => ({
        "@type": "ListItem",
        "position": index + 1,
        "name": item.name,
        "item": item.url
    }))
});

export const generateProductSchema = (product) => ({
    "@context": "https://schema.org",
    "@type": "Product",
    "name": product.name,
    "description": product.description,
    "image": product.image,
    "brand": {
        "@type": "Brand",
        "name": "Quick Groceries"
    },
    "offers": {
        "@type": "Offer",
        "url": "https://quickgroceries.in",
        "priceCurrency": "INR",
        "price": product.price,
        "availability": "https://schema.org/InStock",
        "seller": {
            "@type": "Organization",
            "name": "Quick Groceries"
        }
    }
});

export const generateServiceSchema = (service) => ({
    "@context": "https://schema.org",
    "@type": "Service",
    "name": service.name,
    "description": service.description,
    "provider": {
        "@type": "Organization",
        "name": "Quick Groceries",
        "url": "https://quickgroceries.in"
    },
    "areaServed": {
        "@type": "City",
        "name": "Bhongir"
    },
    "url": service.url
});

export const generateFAQSchema = (faqs) => ({
    "@context": "https://schema.org",
    "@type": "FAQPage",
    "mainEntity": faqs.map(faq => ({
        "@type": "Question",
        "name": faq.question,
        "acceptedAnswer": {
            "@type": "Answer",
            "text": faq.answer
        }
    }))
});

export const generateArticleSchema = (article) => ({
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    "headline": article.title,
    "description": article.description,
    "image": article.image,
    "datePublished": article.publishedDate,
    "dateModified": article.modifiedDate,
    "author": {
        "@type": "Organization",
        "name": "Quick Groceries"
    },
    "publisher": {
        "@type": "Organization",
        "name": "Quick Groceries",
        "logo": {
            "@type": "ImageObject",
            "url": "https://quickgroceries.in/images/logo-full.png"
        }
    }
});

export const generateDeliverySchema = () => ({
    "@context": "https://schema.org",
    "@type": "Service",
    "name": "30-Minute Grocery Delivery",
    "description": "Fast and reliable grocery delivery service with 30-minute delivery guarantee in Bhongir",
    "provider": {
        "@type": "Organization",
        "name": "Quick Groceries"
    },
    "serviceType": "Delivery"
});

export const generateAggregateRatingSchema = (rating) => ({
    "@context": "https://schema.org",
    "@type": "AggregateRating",
    "ratingValue": rating.value,
    "ratingCount": rating.count,
    "bestRating": "5",
    "worstRating": "1"
});

export const renderSchemaTag = (schema) => {
    return `<script type="application/ld+json">${JSON.stringify(schema, null, 2)}</script>`;
};
