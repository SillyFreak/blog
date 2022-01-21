<script context="module" lang="ts">
	import { unpackPostMetadata } from '$lib/posts/allPosts';

	/** @type {import('@sveltejs/kit').Load} */
	export async function load({ fetch }) {
		const response = await fetch('/api/posts.json');
		const posts = ((await response.json()) as any[]).map(unpackPostMetadata).reverse();

		return { props: { posts } };
	}
</script>

<script lang="ts">
	import type { PostMetadata } from '$lib/posts/allPosts';

	import Posts from '$lib/components/Posts.svelte';

	export let posts: PostMetadata[];
</script>

<p>Guess what, this is my blog.</p>

<Posts {posts} />
