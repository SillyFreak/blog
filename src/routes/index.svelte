<script context="module" lang="ts">
	/** @type {import('@sveltejs/kit').Load} */
	export async function load({ fetch }) {
		return { status: 301, redirect: '/blog/' };
	}
</script>
