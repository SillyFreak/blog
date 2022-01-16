<script context="module" lang="ts">
	import allPosts from '$lib/posts/allPosts';

	/** @type {import('@sveltejs/kit').Load} */
	export async function load({ params }) {
		const { yyyy, mm, dd, slug } = params;
		const date = new Date(`${yyyy}-${mm}-${dd}`);

		const posts = await allPosts();
		const post_ = posts.filter(({ slug: slugCandidate, post }) => {
			const candidateDate = new Date(post.metadata.published);
			return slug === slugCandidate && (+date - +candidateDate) === 0;
		});

		if (post_.length === 1) {
			const { slug, post } = post_[0];
			let { title, published, edited } = post.metadata;
			const content = post.default;
			published = new Date(published);
			edited = edited === null ? null : new Date(edited);
			return { props: { slug, title, published, edited, content } };
		}

		return {
			status: 404,
			error: new Error(`Could not load /${yyyy}/${mm}/${dd}/${slug}`),
		};
	}
</script>
<script lang="ts">
	export let slug: string;
	export let title: string;
	export let published: Date;
	export let edited: Date;
	export let content;
</script>

# {title}

Published {published.toLocaleDateString()}{#if edited !== null} - last edited: {edited.toLocaleDateString()}{/if}

<svelte:component this={content} />
