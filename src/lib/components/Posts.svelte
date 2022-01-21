<script lang="ts">
	import type { PostMetadata } from '$lib/posts/allPosts';
	import { postUrl } from '$lib/posts/allPosts';

	export let posts: PostMetadata[];
</script>

<ul>
	{#each posts as post (post.slug)}
		<li>
			<a href="/{postUrl(post)}" class="font-semibold">{post.metadata.title}</a>
		</li>
	{/each}
</ul>
