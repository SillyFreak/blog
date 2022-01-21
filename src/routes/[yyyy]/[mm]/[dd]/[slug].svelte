<script context="module" lang="ts">
	import type { SvelteComponent } from 'svelte';

	import allPosts from '$lib/posts/allPosts';

	/** @type {import('@sveltejs/kit').Load} */
	export async function load({ params }) {
		const { yyyy, mm, dd, slug } = params;
		const date = new Date(`${yyyy}-${mm}-${dd}`);

		const posts = await allPosts();
		const post = posts.filter(({ slug: slugCandidate, metadata }) => {
			return slug === slugCandidate && +date - +metadata.published === 0;
		});

		if (post.length === 1) {
			const { slug, metadata, content } = post[0];
			return { props: { slug, ...metadata, content } };
		}

		return {
			status: 404,
			error: new Error(`no post at /${yyyy}/${mm}/${dd}/${slug}`),
		};
	}
</script>

<script lang="ts">
	// export let slug: string;
	export let title: string;
	export let published: Date;
	export let edited: Date;
	export let categories: string[];
	// export let excerpt: string;
	export let content: typeof SvelteComponent;
</script>

<h1 class="text-4xl">{title}</h1>

<p class="text-sm italic">
	Published {published.toLocaleDateString()}
	{#if edited !== null}- last edited: {edited.toLocaleDateString()}{/if}
</p>

<p class="text-sm">
	{#each categories as category}
		<a href="/categories/{category.toLowerCase()}" class="bg-gray-200 px-1 mx-0.5">{category}</a>
	{/each}
</p>

<svelte:component this={content} />
