import type { SvelteComponent } from 'svelte';

export type Metadata = {
	title: string;
	published: Date;
	edited: Date | null;
};

export type PostMetadata = {
	slug: string;
	metadata: Metadata;
};

export type Post = PostMetadata & {
	content: typeof SvelteComponent;
};

export default async function allPosts(): Promise<Post[]> {
	const posts = Object.entries(import.meta.glob('./*.svelte.md'));
	return Promise.all(
		posts.map(async ([path, resolver]) => {
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
}
