/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        // Brand Primary (Deep Green)
        primary: {
          50: '#E6F4EF',
          100: '#CDE9DF',
          200: '#9ED1C1',
          300: '#6FB9A3',
          400: '#3FA184',
          500: '#17795A',
          600: '#0F6B4B',
          700: '#0B5C44',
          800: '#084A36',
          900: '#063A2A',
        },
        // Brand Accent (Vibrant Red)
        accent: {
          50: '#FFE8E6',
          100: '#FFD1CD',
          200: '#FFAAA6',
          300: '#FF827F',
          400: '#FF5A56',
          500: '#FF3B3B',
          600: '#E03232',
          700: '#C12727',
          800: '#9E1F1F',
          900: '#7A1818',
        },
        // Brand Lemon (Warm Yellow background)
        lemon: {
          50: '#FFF8CC',
          100: '#FFF2A6',
          200: '#FFE97A',
          300: '#FFE066',
          400: '#FFD64D',
          500: '#FFC933',
          600: '#E6B22E',
          700: '#CC9C29',
          800: '#A37C20',
          900: '#7A5D18',
        },
        // Optional secondary
        secondary: {
          500: '#0ea5e9',
          600: '#0284c7',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Poppins', 'system-ui', 'sans-serif'],
      },
      animation: {
        'float': 'float 3s ease-in-out infinite',
        'slide-up': 'slideUp 0.6s ease-out',
        'fade-in': 'fadeIn 0.6s ease-out',
        'bounce-slow': 'bounce 3s infinite',
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-20px)' },
        },
        slideUp: {
          '0%': { transform: 'translateY(30px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
      },
    },
  },
  plugins: [],
};