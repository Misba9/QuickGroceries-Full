# Quick Groceries - SEO Quick Reference Guide

**Quick lookup for implementing SEO in new components**

---

## Using SEO in a New Component

### 1. Import Required Functions

```javascript
import { useSEO } from '../context/SEOProvider';
import { updateMetaTags, generatePageMetadata } from '../utils/seoHelpers';
import { generateOrganizationSchema, generateBreadcrumbSchema } from '../utils/seoSchemas';
import { PAGE_META, SITE_URL } from '../utils/seoConfig';
```

### 2. Set Up Basic Page SEO

```javascript
// For a new page like /products
const ProductsPage = () => {
  const metadata = {
    title: 'Products | Quick Groceries',
    description: 'Browse fresh groceries including vegetables, fruits, dairy...',
    keywords: 'vegetables, fruits, dairy, groceries',
    canonical: `${SITE_URL}/products`,
    ogTitle: 'Fresh Groceries Products',
    ogDescription: 'Shop fresh vegetables, fruits and more',
    ogImage: `${SITE_URL}/images/products.jpg`
  };

  useSEO(metadata);

  return (
    // Your component JSX
  );
};
```

### 3. Add Schema Markup

```javascript
useSEO(
  metadata,
  generateOrganizationSchema() // Pass schema as second parameter
);
```

### 4. Complete Example

```javascript
import React from 'react';
import { useSEO } from '../context/SEOProvider';
import { generateOrganizationSchema } from '../utils/seoSchemas';
import { SITE_URL } from '../utils/seoConfig';

const NewPage = () => {
  const metadata = {
    title: 'Page Title - Quick Groceries',
    description: 'Compelling meta description under 160 characters',
    keywords: 'keyword1, keyword2, keyword3',
    canonical: `${SITE_URL}/page-path`,
    ogTitle: 'Page Title',
    ogDescription: 'OG description for social sharing',
    ogImage: `${SITE_URL}/images/page-image.jpg`
  };

  useSEO(metadata, generateOrganizationSchema());

  return (
    <div>
      <h1>Page Title with Primary Keyword</h1>
      {/* Rest of component */}
    </div>
  );
};

export default NewPage;
```

---

## Common Schema Markups

### Organization Schema
```javascript
generateOrganizationSchema()
// Use: Generic pages about the company
```

### Local Business Schema
```javascript
generateLocalBusinessSchema()
// Use: Homepage, location pages, contact pages
```

### Service Schema
```javascript
generateServiceSchema({
  name: 'Grocery Delivery',
  description: 'Fast grocery delivery service',
  url: 'https://quickgroceries.in/services'
})
// Use: Services pages
```

### FAQ Schema
```javascript
generateFAQSchema([
  { question: 'How fast is delivery?', answer: '30 minutes' },
  { question: 'What areas?', answer: 'Bhongir and Telangana' }
])
// Use: Help center, FAQ pages
```

### Article Schema
```javascript
generateArticleSchema({
  title: 'Blog Post Title',
  description: 'Blog post description',
  image: 'image-url.jpg',
  publishedDate: '2026-02-20',
  modifiedDate: '2026-02-20'
})
// Use: Blog posts
```

### Breadcrumb Schema
```javascript
generateBreadcrumbSchema([
  { position: 1, name: 'Home', url: 'https://quickgroceries.in/' },
  { position: 2, name: 'Services', url: 'https://quickgroceries.in/services' }
])
// Use: Every content page for navigation clarity
```

---

## Meta Tag Guidelines

### Title Tag
**Format:** `Primary Keyword | Brand | Modifier`  
**Length:** 50-60 characters  
**Example:** `Grocery Delivery in Bhongir | Quick Groceries | Fast & Fresh`

### Meta Description
**Length:** 120-160 characters  
**Include:** Keyword, unique value, CTA  
**Example:** `Order fresh groceries in Bhongir with 30-minute delivery. Vegetables, fruits, dairy & essentials. Download Quick Groceries app now!`

### Keywords
**Count:** 3-8 keywords  
**Format:** Comma-separated  
**Example:** `grocery delivery bhongir, fresh vegetables, fast delivery`

---

## Keyword Placement Checklist

- [ ] Primary keyword in Title tag (early position)
- [ ] Primary keyword in H1 tag
- [ ] Primary keyword in first 100 words
- [ ] Primary keyword in meta description
- [ ] Related keywords in H2/H3 tags
- [ ] Keywords naturally in body content
- [ ] Keywords in image alt text
- [ ] Keywords in internal link anchor text

---

## Heading Hierarchy Example

```html
<h1>Online Grocery Delivery in Bhongir | Fresh Products</h1>

<h2>Why Choose Quick Groceries?</h2>
<p>Content...</p>

<h3>Fast 30-Minute Delivery</h3>
<p>Content about delivery...</p>

<h3>Fresh Quality Guarantee</h3>
<p>Content about quality...</p>

<h2>Products Available</h2>
<h3>Fresh Vegetables</h3>
<h3>Fresh Fruits</h3>
<h3>Dairy Products</h3>
```

---

## Image SEO

```javascript
// Always use descriptive alt text
<img 
  src="/images/vegetables.jpg"
  alt="Fresh organic vegetables delivered in Bhongir"
  loading="lazy"
  title="Fresh Vegetables Delivery"
/>

// Or with optimized image component
export const OptimizedImage = ({ src, alt, keywords }) => (
  <img 
    src={src}
    alt={`${alt} | ${keywords}`}
    loading="lazy"
    title={alt}
  />
);
```

---

## Internal Linking Strategy

### Link Placement
```javascript
// In blog posts
<a href="/delivery-partner">Learn about delivery partner opportunities</a>

// In service pages
<a href="/blog/grocery-tips">Read our grocery shopping tips</a>

// In footer
<a href="/privacy">Privacy Policy</a>
<a href="/terms">Terms of Service</a>
<a href="/help">Help Center</a>
```

### Anchor Text Rules
- ✅ Keyword-rich and natural
- ✅ Relevant to page being linked
- ❌ Avoid: "click here", "read more"
- ❌ Avoid: Keyword stuffing

---

## Content Length Guidelines

| Page Type | Minimum | Ideal | Maximum |
|-----------|---------|-------|---------|
| Homepage | 300 | 500-800 | 2000 |
| Service Page | 400 | 600-800 | 2000 |
| Blog Post | 800 | 1500-2500 | 5000 |
| Location Page | 600 | 800-1200 | 2000 |
| Product Page | 150 | 300-500 | 1000 |
| FAQ Page | 50 per item | 100-150 | 500 |

---

## SEO Validation Checklist

Before publishing a page:

```javascript
// Check SEO quality
const { score, checks } = getSEOScore(metadata);
console.log(`SEO Score: ${score}`);
console.log(checks);

// Validate content
const { isValid, warnings } = validateSEOContent({
  title: pageTitle,
  description: metaDescription,
  h1: mainHeading,
  keywords: keywords
});
```

**Target Score:** 70+ for good SEO

---

## Common SEO Mistakes

❌ **AVOID:**
1. Duplicate meta descriptions
2. Keyword stuffing
3. Irrelevant keywords
4. Missing alt text on images
5. Poor heading structure
6. Broken internal links
7. Thin content (< 300 words)
8. Not mobile-friendly
9. Slow page speed
10. No schema markup

✅ **DO:**
1. Unique, compelling meta tags
2. 3-8 relevant keywords
3. High-quality, relevant content
4. Descriptive alt text with keywords
5. Proper H1→H2→H3 hierarchy
6. Regular link maintenance
7. Comprehensive content (500+ words)
8. Mobile-first design
9. Optimize for Core Web Vitals
10. Always include schema markup

---

## Tools for Testing

### Validation
```
Google Rich Results Tester
https://search.google.com/test/rich-results

Schema.org Validator
https://validator.schema.org

Mobile-Friendly Test
https://search.google.com/mobile-friendly
```

### Performance
```
PageSpeed Insights
https://pagespeed.web.dev

GTmetrix
https://gtmetrix.com

WebPageTest
https://webpagetest.org
```

### Analysis
```
Google Search Console
https://search.google.com/search-console

Google Analytics
https://analytics.google.com

Screaming Frog SEO Spider
https://www.screamingfrog.co.uk/
```

---

## Monitoring Checklist

### Weekly
- [ ] Check Search Console for crawl errors
- [ ] Monitor top 10 keywords in rankings
- [ ] Check traffic trends

### Monthly
- [ ] Review Core Web Vitals
- [ ] Analyze bounce rate by page
- [ ] Check backlinks for new entries
- [ ] Verify all internal links work

### Quarterly
- [ ] Update old blog posts
- [ ] Refresh competitor keywords
- [ ] SEO audit
- [ ] Content performance review

---

## Quick SEO Tips

1. **Content is King** - Focus on valuable, unique content first
2. **Mobile First** - Test on mobile, optimize for mobile
3. **Speed Matters** - Aim for LCP < 2.5s
4. **User Intent** - Match content to what users actually search for
5. **Quality Over Quantity** - 1 great page beats 10 mediocre ones
6. **Local Focus** - Emphasize Bhongir + Telangana in content
7. **Internal Linking** - Link related pages strategically
8. **Fresh Content** - Regularly update and add new content
9. **Monitor and Adjust** - Use data to improve strategy
10. **Be Patient** - SEO takes 3-6 months to show significant results

---

## If Search Rankings Drop

1. Check Search Console for manual actions or errors
2. Verify pages are still indexed (site: query)
3. Check for duplicate content issues
4. Review competitor rankings for the keyword
5. Verify backlinks haven't dropped
6. Check if content is still relevant/up-to-date
7. Verify page speed hasn't degraded
8. Check for technical issues
9. Review if algorithm update happened
10. Consider freshening up the content

---

## Need More Help?

- **See:** `SEO_IMPLEMENTATION_GUIDE.md` for detailed documentation
- **Code:** Review `src/utils/` for SEO utility functions
- **Schemas:** Check `src/utils/seoSchemas.js` for all available schemas
- **Config:** See `src/utils/seoConfig.js` for keywords and page metadata

---

**Last Updated:** February 20, 2026  
**For Quick Reference Only** - See full guide for detailed information
