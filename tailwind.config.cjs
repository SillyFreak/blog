const config = {
	mode: 'jit',
	purge: ['./src/**/*.{html,js,svelte,ts}'],
	theme: {
		extend: {
			fontFamily: {
				'mono': ["Consolas","Monaco", "Andale Mono", "Ubuntu Mono", "monospace"],
			},
		},
	},
	plugins: [require('daisyui')],
};

module.exports = config;
