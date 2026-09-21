const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
    content: [
        './public/*.html',
        './app/helpers/**/*.rb',
        './app/javascript/**/*.js',
        './app/views/**/*.{erb,haml,html,slim}'
    ],
    theme: {
        extend: {
            colors: {
                'brand-bg': '#F8F6F0', // Светлый бежевый фон
                'brand-green': '#2F5951', // Темно-зеленый (карточки и текст)
                'brand-peach': '#F0D5C6', // Персиковый (карточка каталога)
                'brand-light-green': '#E7EFEA', // Светло-зеленый для UI элементов
            },
            fontFamily: {
                serif: ['"Playfair Display"', ...defaultTheme.fontFamily.serif],
                sans: ['Inter', ...defaultTheme.fontFamily.sans],
            },
        },
    },
    plugins: [
        require('@tailwindcss/forms'),
        require('@tailwindcss/typography'),
        require('@tailwindcss/container-queries'),
    ]
}