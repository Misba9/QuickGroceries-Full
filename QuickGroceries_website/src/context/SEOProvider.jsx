/**
 * SEO Provider Component
 * Manages dynamic meta tags, schema markup, and SEO settings for each page
 */

import React, { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import {
    updateMetaTags,
    addSchemaMarkup,
    removeSchemaMarkup,
    generatePageMetadata,
    getCanonicalUrl
} from '../utils/seoHelpers';
import {
    PAGE_META,
    SITE_URL,
    SITE_NAME
} from '../utils/seoConfig';
import {
    generateOrganizationSchema,
    generateBreadcrumbSchema,
    generateFAQSchema,
    generateLocalBusinessSchema
} from '../utils/seoSchemas';

/**
 * Page routes with their SEO configuration
 */
const routeToMetaMap = {
    '/': 'home',
    '/about': 'about',
    '/services': 'services',
    '/how-it-works': 'howItWorks',
    '/features': 'features',
    '/testimonials': 'testimonials',
    '/download': 'download',
    '/quick-grocery-delivery-bhongir': 'deliveryBhongir',
    '/PartnerWithUs': 'partner',
    '/delivery-partner': 'partner',
    '/blog': 'blog',
    '/help': 'help',
    '/safety': 'safety',
    '/privacy': 'privacy',
    '/terms': 'terms'
};

export const SEOProvider = ({ children }) => {
    const location = useLocation();

    useEffect(() => {
        // Get the meta configuration for current route
        const metaKey = routeToMetaMap[location.pathname] || 'home';
        const currentPageMeta = PAGE_META[metaKey];

        if (currentPageMeta) {
            // Generate comprehensive metadata
            const metadata = generatePageMetadata(currentPageMeta, {
                path: location.pathname
            });

            // Update all meta tags
            updateMetaTags(metadata);

            // Add organization schema
            addSchemaMarkup(generateOrganizationSchema(), 'org-schema');

            // Add local business schema
            addSchemaMarkup(generateLocalBusinessSchema(), 'local-business-schema');

            // Add breadcrumb schema based on route
            const breadcrumbs = generateBreadcrumbs(getBreadcrumbItems(location.pathname));
            addSchemaMarkup(generateBreadcrumbSchema(breadcrumbs), 'breadcrumb-schema');

            // Add page-specific schema
            if (metaKey === 'help') {
                const { FAQ_CONTENT } = require('../utils/seoConfig');
                addSchemaMarkup(generateFAQSchema(FAQ_CONTENT), 'faq-schema');
            }

            // Scroll to top
            window.scrollTo(0, 0);
        }
    }, [location.pathname]);

    return children;
};

/**
 * Hook to manually set SEO metadata for a component
 */
export const useSEO = (metadata, schemaMarkup = null) => {
    useEffect(() => {
        if (metadata) {
            updateMetaTags(metadata);
        }

        if (schemaMarkup) {
            addSchemaMarkup(schemaMarkup, 'page-schema');
        }

        return () => {
            if (schemaMarkup) {
                removeSchemaMarkup('page-schema');
            }
        };
    }, [metadata, schemaMarkup]);
};

/**
 * Helper function to generate breadcrumb items based on route
 */
const getBreadcrumbItems = (pathname) => {
    const breadcrumbs = [
        { name: 'Home', path: '/' }
    ];

    if (pathname === '/') return breadcrumbs;

    // Get the route name
    const routeName = pathname
        .split('/')
        .filter(Boolean)
        .join(' ')
        .replace(/-/g, ' ')
        .replace(/\b\w/g, l => l.toUpperCase());

    breadcrumbs.push({
        name: routeName,
        path: pathname
    });

    return breadcrumbs;
};

/**
 * Generate breadcrumbs schema
 */
const generateBreadcrumbs = (items) => {
    return items.map((item, index) => ({
        position: index + 1,
        name: item.name,
        url: `${SITE_URL}${item.path}`
    }));
};

export default SEOProvider;
