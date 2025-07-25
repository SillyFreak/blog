/** @type {import('prettier').Config} */
module.exports = {
  printWidth: 100,
  semi: true,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: 'all',
  useTabs: false,

  plugins: [require.resolve('prettier-plugin-astro')],

  overrides: [{ files: '*.astro', options: { parser: 'astro' } }],
};
