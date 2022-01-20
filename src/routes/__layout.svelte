<script lang="ts">
	import '$lib/styles/app.postcss';
	import 'prismjs/themes/prism.css';
</script>

<header class="bg-gray-100 py-4">
	<a href="/" class="m-4 font-semibold">Home</a>
</header>
<div class="main-width mt-8 mb-16">
	<slot />
</div>
<footer class="bg-gray-100 py-4">&nbsp;</footer>

<style lang="postcss">
	.main-width {
		@apply mx-2;
		@apply sm:mx-4;
		@apply md:w-[45rem] md:mx-auto;
		@apply lg:w-[56rem];
	}
</style>
