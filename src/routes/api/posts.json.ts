import type { EndpointOutput, RequestHandler } from '@sveltejs/kit';

import allPosts from '$lib/posts/allPosts';
import type { PostMetadata } from '$lib/posts/allPosts';

/** @type {RequestHandler} */
export async function get(): Promise<EndpointOutput<PostMetadata[]>> {
	const posts = await allPosts();
	return {
		status: 200,
		body: posts.map(({ slug, metadata }) => ({ slug, metadata })),
	};
}
