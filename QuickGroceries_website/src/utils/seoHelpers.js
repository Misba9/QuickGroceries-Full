/**
 * SEO Helpers
 * Utility functions for managing SEO implementation
 */

import { SITE_URL, SITE_NAME } from './seoConfig';

/**
 * Generate canonical URL
 */
export const getCanonicalUrl = (path = '/') => {
    return `${SITE_URL}${path}`;
};

/**
 * Update document meta tags
 */
export const updateMetaTags = (metadata) => {
    // Update title
    if (metadata.title) {
        document.title = metadata.title;
    }

    // Update meta description
    if (metadata.description) {
        updateMetaTag('description', metadata.description);
    }

    // Update meta keywords
    if (metadata.keywords) {
        updateMetaTag('keywords', metadata.keywords);
    }

    // Update canonical tag
    if (metadata.canonical) {
        updateCanonicalTag(metadata.canonical);
    }

    // Update OG tags
    if (metadata.ogTitle) {
        updateMetaTag('og:title', metadata.ogTitle, 'property');
    }
    if (metadata.ogDescription) {
        updateMetaTag('og:description', metadata.ogDescription, 'property');
    }
    if (metadata.ogImage) {
        updateMetaTag('og:image', metadata.ogImage, 'property');
    }
    if (metadata.ogType) {
        updateMetaTag('og:type', metadata.ogType, 'property');
    }
    if (metadata.ogUrl) {
        updateMetaTag('og:url', metadata.ogUrl, 'property');
    }

    // Update Twitter tags
    if (metadata.twitterCard) {
        updateMetaTag('twitter:card', metadata.twitterCard);
    }
    if (metadata.twitterTitle) {
        updateMetaTag('twitter:title', metadata.twitterTitle);
    }
    if (metadata.twitterDescription) {
        updateMetaTag('twitter:description', metadata.twitterDescription);
    }
    if (metadata.twitterImage) {
        updateMetaTag('twitter:image', metadata.twitterImage);
    }
};

/**
 * Update or create a meta tag
 */
const updateMetaTag = (name, content, attribute = 'name') => {
    let tag = document.querySelector(`meta[${attribute}="${name}"]`);

    if (!tag) {
        tag = document.createElement('meta');
        tag.setAttribute(attribute, name);
        document.head.appendChild(tag);
    }

    tag.setAttribute('content', content);
};

/**
 * Update or create canonical tag
 */
const updateCanonicalTag = (url) => {
    let link = document.querySelector('link[rel="canonical"]');

    if (!link) {
        link = document.createElement('link');
        link.setAttribute('rel', 'canonical');
        document.head.appendChild(link);
    }

    link.setAttribute('href', url);
};

/**
 * Add schema markup to page
 */
export const addSchemaMarkup = (schema, id = 'schema-markup') => {
    let script = document.getElementById(id);

    if (!script) {
        script = document.createElement('script');
        script.id = id;
        script.type = 'application/ld+json';
        document.head.appendChild(script);
    }

    script.innerHTML = JSON.stringify(schema, null, 2);
};

/**
 * Remove schema markup from page
 */
export const removeSchemaMarkup = (id = 'schema-markup') => {
    const script = document.getElementById(id);
    if (script) {
        script.remove();
    }
};

/**
 * Generate structured metadata for a page
 */
export const generatePageMetadata = (pageMeta, additionalMetadata = {}) => {
    return {
        title: pageMeta.title,
        description: pageMeta.description,
        keywords: pageMeta.keywords,
        canonical: getCanonicalUrl(additionalMetadata.path),
        ogTitle: pageMeta.ogTitle,
        ogDescription: pageMeta.ogDescription,
        ogImage: pageMeta.ogImage,
        ogType: 'website',
        ogUrl: getCanonicalUrl(additionalMetadata.path),
        twitterCard: 'summary_large_image',
        twitterTitle: pageMeta.ogTitle,
        twitterDescription: pageMeta.ogDescription,
        twitterImage: pageMeta.ogImage,
        ...additionalMetadata
    };
};

/**
 * Generate breadcrumb items
 */
export const generateBreadcrumbs = (items) => {
    return items.map((item, index) => ({
        position: index + 1,
        name: item.name,
        item: `${SITE_URL}${item.path}`
    }));
};

/**
 * Optimize image for SEO
 */
export const optimizeImage = (imagePath, altText) => {
    return {
        src: imagePath,
        alt: altText,
        title: altText,
        loading: 'lazy'
    };
};

/**
 * Get keywords for a page as comma-separated string
 */
export const getKeywordsString = (keywordArray) => {
    return Array.isArray(keywordArray) ? keywordArray.join(', ') : keywordArray;
};

/**
 * Validate SEO content
 */
export const validateSEOContent = (content) => {
    const warnings = [];

    if (!content.title || content.title.length < 30) {
        warnings.push('Title should be at least 30 characters');
    }
    if (content.title && content.title.length > 60) {
        warnings.push('Title is longer than recommended (60 characters)');
    }
    if (!content.description || content.description.length < 120) {
        warnings.push('Meta description should be at least 120 characters');
    }
    if (content.description && content.description.length > 160) {
        warnings.push('Meta description is longer than recommended (160 characters)');
    }
    if (!content.h1 || content.h1.length < 20) {
        warnings.push('H1 tag should be at least 20 characters');
    }

    return {
        isValid: warnings.length === 0,
        warnings
    };
};

/**
 * Get SEO score
 */
export const getSEOScore = (metadata) => {
    let score = 0;
    const checks = [];

    if (metadata.title && metadata.title.length >= 30 && metadata.title.length <= 60) {
        score += 20;
        checks.push('✓ Title optimization');
    }
    if (metadata.description && metadata.description.length >= 120 && metadata.description.length <= 160) {
        score += 20;
        checks.push('✓ Meta description optimization');
    }
    if (metadata.keywords) {
        score += 10;
        checks.push('✓ Keywords included');
    }
    if (metadata.canonical) {
        score += 10;
        checks.push('✓ Canonical tag set');
    }
    if (metadata.ogImage && metadata.ogTitle && metadata.ogDescription) {
        score += 20;
        checks.push('✓ Open Graph tags present');
    }
    if (metadata.twitterCard && metadata.twitterImage) {
        score += 10;
        checks.push('✓ Twitter card present');
    }
    if (metadata.schema) {
        score += 10;
        checks.push('✓ Schema markup present');
    }

    return {
        score: Math.min(score, 100),
        checks
    };
};

/**
 * Create Schema.org structured data context
 */
export const createStructuredDataContext = () => {
    return {
        "@context": "https://schema.org"
    };
};

/**
 * Format date for schema
 */
export const formatDateForSchema = (date) => {
    return new Date(date).toISOString().split('T')[0];
};

/**
 * Create URL list for sitemap
 */
export const generateSitemapUrls = (routes) => {
    return routes.map(route => ({
        loc: getCanonicalUrl(route.path),
        lastmod: new Date().toISOString().split('T')[0],
        changefreq: route.changefreq || 'monthly',
        priority: route.priority || 0.8
    }));
};

/**
 * SEO best practices check
 */
export const checkSEOBestPractices = (content) => {
    const practices = {
        hasH1: !!content.h1,
        hasKeywordInH1: content.h1 && content.keywords &&
            content.keywords.some(kw => content.h1.toLowerCase().includes(kw.toLowerCase())),
        hasKeywordInDescription: content.description && content.keywords &&
            content.keywords.some(kw => content.description.toLowerCase().includes(kw.toLowerCase())),
        hasKeywordInTitle: content.title && content.keywords &&
            content.keywords.some(kw => content.title.toLowerCase().includes(kw.toLowerCase())),
        hasAltText: content.images && content.images.every(img => img.alt),
        hasLinks: !!content.internalLinks || !!content.externalLinks,
        contentLength: content.content && content.content.split(' ').length > 300
    };

    return {
        score: Object.values(practices).filter(Boolean).length,
        practices
    };
};
