<script lang="ts">
	import type { PostMetadata } from '$lib/posts/allPosts';
	import { postUrl } from '$lib/posts/allPosts';

	export let posts: PostMetadata[];
</script>

<ul class="m-0 flex flex-col flex-wrap gap-1">
	{#each posts as post (post.slug)}
		{@const meta = post.metadata}
		<li class="block m-0">
			<h1 class="plain">
				<a href="/{postUrl(post)}">{meta.title}</a>
			</h1>

			<p class="plain text-sm italic">Published {meta.published.toLocaleDateString()}</p>

			<ul class="m-0 text-sm flex flex-wrap gap-1">
				{#each meta.categories as category}
					<li class="m-0">
						<a href="/categories/{category.toLowerCase()}" class="bg-gray-200 px-1">{category}</a>
					</li>
				{/each}
			</ul>
		</li>
	{/each}
</ul>
