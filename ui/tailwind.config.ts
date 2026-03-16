import type { Config } from 'tailwindcss';

export default {
    content: ['./src/**/*.{html,js,svelte,ts}'],
    theme: {
        extend: {
            colors: {
                background: '#0a0a0a',
                surface: '#171717',
                primary: '#3b82f6',
                accent: '#8b5cf6',
                danger: '#ef4444',
                success: '#22c55e'
            },
            fontFamily: {
                sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
            }
        },
    },
    plugins: [],
} satisfies Config;
