import type { SvelteComponent } from 'svelte';

export type Metadata = {
	title: string;
	published: Date;
	edited: Date | null;
	categories: string[];
	excerpt: string;
};

export type PostMetadata = {
	slug: string;
	metadata: Metadata;
};

export type Post = PostMetadata & {
	content: typeof SvelteComponent;
};

export function unpackMetadata(raw: any): Metadata {
	let { published, edited, ...more } = raw;

	published = new Date(published);
	edited = edited === null ? null : new Date(edited);

	return { published, edited, ...more };
}

export function unpackPostMetadata(raw: any): PostMetadata {
	let { slug, metadata } = raw;

	metadata = unpackMetadata(metadata);

	return { slug, metadata };
}

export function unpackPost(raw: any): Post {
	let { slug, metadata, content } = raw;

	metadata = unpackMetadata(metadata);

	return { slug, metadata, content };
}

export function postUrl(post: PostMetadata): string {
	const published = post.metadata.published;
	const yyyy = String(published.getUTCFullYear()).padStart(4, '0');
	const mm = String(published.getUTCMonth() + 1).padStart(2, '0');
	const dd = String(published.getUTCDate()).padStart(2, '0');

	return `${yyyy}/${mm}/${dd}/${post.slug}/`;
}

export default async function allPosts(): Promise<Post[]> {
	const postPromises = Object.entries(import.meta.glob('./*.svelte.md'));
	const posts = await Promise.all(
		postPromises.map(async ([path, resolver]) => {
			let slug = path.slice(2, -10);
			slug = slug.substring(slug.indexOf('-') + 1);
			const { default: content, metadata } = await resolver();
			return unpackPost({ slug, metadata, content });
		}),
	);

	return posts.sort((a, b) => +a.metadata.published - +b.metadata.published);
}
