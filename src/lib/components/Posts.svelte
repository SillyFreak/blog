<script lang="ts">
	import type { PostMetadata } from '$lib/posts/allPosts';
	import { postUrl } from '$lib/posts/allPosts';

	export let posts: PostMetadata[];
</script>

<ul class="list-none flex flex-col flex-wrap gap-1">
	{#each posts as post (post.slug)}
		{@const meta = post.metadata}
		<li class="block">
			<h1>
				<a href="/{postUrl(post)}" class="font-semibold">{meta.title}</a>
			</h1>

			<p class="text-sm italic">Published {meta.published.toLocaleDateString()}</p>

			<ul class="text-sm list-none flex flex-wrap gap-1">
				{#each meta.categories as category}
					<li>
						<a href="/categories/{category.toLowerCase()}" class="bg-gray-200 px-1">{category}</a>
					</li>
				{/each}
			</ul>
		</li>
	{/each}
</ul>
