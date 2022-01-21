<script context="module" lang="ts">
	import { unpackPostMetadata } from '$lib/posts/allPosts';

	/** @type {import('@sveltejs/kit').Load} */
	export async function load({ params, fetch }) {
		const { category } = params;
		const response = await fetch('/api/posts.json');
		const posts = ((await response.json()) as any[])
			.map(unpackPostMetadata)
			.filter((post) => {
				function compareCategory(c: string) {
					return c.localeCompare(category, undefined, { sensitivity: 'base' }) === 0;
				}
				return post.metadata.categories.filter(compareCategory).length !== 0;
			})
			.reverse();

		return { props: { posts } };
	}
</script>

<script lang="ts">
	import type { PostMetadata } from '$lib/posts/allPosts';

	import Posts from '$lib/components/Posts.svelte';

	export let posts: PostMetadata[];
</script>

<Posts {posts} />
