import adapter from '@sveltejs/adapter-static';
import preprocess from 'svelte-preprocess';

import { mdsvex } from 'mdsvex';
import addClasses from 'rehype-add-classes';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	extensions: ['.svelte', '.svelte.md'],

	// Consult https://github.com/sveltejs/svelte-preprocess
	// for more information about preprocessors
	preprocess: [
		mdsvex({
			extensions: ['.svelte.md', '.svx'],
			rehypePlugins: [[addClasses, { 'h1,h2,h3,h4,h5,p,ul,ol,li,a,blockquote,code': 'plain' }]],
		}),
		preprocess({
			postcss: true,
		}),
	],

	kit: {
		adapter: adapter(),

		// hydrate the <body> element in src/app.html
		target: 'body',

		trailingSlash: 'always',
	},
};

export default config;
