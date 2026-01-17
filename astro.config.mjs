// @ts-check
import { defineConfig } from 'astro/config';
import { typst } from 'astro-typst';
import sitemap from '@astrojs/sitemap';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  site: 'https://blog.ensko.at',
  base: '/',

  // Whether to prefetch links while hovering.
  // See: https://docs.astro.build/en/guides/prefetch/
  prefetch: {
    prefetchAll: true,
  },

  integrations: [
    sitemap(),
    typst({
      // Always builds HTML files
      target: 'html',
      // conditionally build HTML or SVG
      // target: () => "html",
    }),
  ],

  vite: {
    plugins: [
      tailwindcss(),
    ],
    build: {
      assetsInlineLimit(filePath, content) {
        const KB = 1024;
        return content.length < (filePath.endsWith('.css') ? 100 * KB : 4 * KB);
      },
    },
    ssr: {
      external: ['@myriaddreamin/typst-ts-node-compiler'],
    },
  },
});
