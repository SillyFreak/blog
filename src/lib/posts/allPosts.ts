import type { SvelteComponent } from 'svelte';

export type Metadata = {
	title: string;
	published: Date;
	edited: Date | null;
	categories: string[];
};

export type PostMetadata = {
	slug: string;
	metadata: Metadata;
};

export type Post = PostMetadata & {
	content: typeof SvelteComponent;
};

export default async function allPosts(): Promise<Post[]> {
	const postPromises = Object.entries(import.meta.glob('./*.svelte.md'));
	const posts = await Promise.all(
		postPromises.map(async ([path, resolver]) => {
			const post = await resolver();

			const slug = path.slice(2, -10).split('-', 2).pop();
			const content = post.default;

			let { published, edited, ...more } = post.metadata;
			published = new Date(published);
			edited = edited === null ? null : new Date(edited);
			const metadata = { published, edited, ...more };

			return { slug, metadata, content };
		}),
	);

	return posts.sort((a, b) => +a.metadata.published - +b.metadata.published);
}
