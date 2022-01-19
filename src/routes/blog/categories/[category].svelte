<script context="module" lang="ts">
	import type { PostMetadata } from '$lib/posts/allPosts';

	/** @type {import('@sveltejs/kit').Load} */
	export async function load({ params, fetch }) {
		const { category } = params;
		const response = await fetch('/api/posts.json');
		const posts = ((await response.json()) as any[])
			.map((post) => {
				let {
					slug,
					metadata: { published, edited, ...more },
				} = post;

				published = new Date(published);
				edited = edited === null ? null : new Date(edited);

				return { slug, metadata: { published, edited, ...more } } as PostMetadata;
			})
			.filter((post) => {
				function compareCategory(c: string) {
					return c.localeCompare(category, undefined, { sensitivity: 'base' }) === 0;
				}
				return post.metadata.categories.filter(compareCategory).length !== 0;
			});

		return { props: { posts } };
	}
</script>

<script lang="ts">
	export let posts: PostMetadata[];

	function postUrl(post: PostMetadata): string {
		const published = post.metadata.published;
		console.log(published);
		const yyyy = String(published.getUTCFullYear()).padStart(4, '0');
		const mm = String(published.getUTCMonth() + 1).padStart(2, '0');
		const dd = String(published.getUTCDate()).padStart(2, '0');

		return `${yyyy}/${mm}/${dd}/${post.slug}/`;
	}
</script>

<ul>
	{#each posts as post (post.slug)}
		<li>
			<a href={postUrl(post)}>{post.metadata.title}</a>
		</li>
	{/each}
</ul>
