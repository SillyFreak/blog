import adapter from '@sveltejs/adapter-static';
import preprocess from 'svelte-preprocess';

import { mdsvex } from 'mdsvex';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	extensions: ['.svelte', '.svelte.md'],

	// Consult https://github.com/sveltejs/svelte-preprocess
	// for more information about preprocessors
	preprocess: [
		mdsvex({ extensions: ['.svelte.md', '.svx'] }),
		preprocess({
			postcss: true,
		}),
	],

	kit: {
		adapter: adapter(),

		// hydrate the <body> element in src/app.html
		target: 'body',
	},
};

export default config;
