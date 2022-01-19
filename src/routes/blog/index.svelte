<script context="module" lang="ts">
	import type { PostMetadata } from '$lib/posts/allPosts';
	import { unpackPostMetadata, postUrl } from '$lib/posts/allPosts';

	/** @type {import('@sveltejs/kit').Load} */
	export async function load({ fetch }) {
		const response = await fetch('/api/posts.json');
		const posts = ((await response.json()) as any[]).map(unpackPostMetadata).reverse();

		return { props: { posts } };
	}
</script>

<script lang="ts">
	export let posts: PostMetadata[];
</script>

<ul>
	{#each posts as post (post.slug)}
		<li>
			<a href={postUrl(post)}>{post.metadata.title}</a>
		</li>
	{/each}
</ul>
