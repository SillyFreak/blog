import type { EndpointOutput, RequestHandler } from '@sveltejs/kit';

import allPosts, { postUrl } from '$lib/posts/allPosts';

const title = 'Blog';
const description = 'Personal Blog';
const url = 'https://sillyfreak.space';

/** @type {RequestHandler} */
export async function get(): Promise<EndpointOutput<string>> {
	const posts = await allPosts();

	const headers = {
		'Cache-Control': 'max-age=0, s-maxage=3600',
		'Content-Type': 'application/xml',
	};

	const body = `<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
<title>${title}</title>
<description>${description}</description>
<link>${url}</link>
<atom:link href="${url}/rss.xml" rel="self" type="application/rss+xml"/>
${posts
	.map(
		(post) => `<item>
<guid isPermaLink="true">${url}/blog/${postUrl(post)}</guid>
<title>${post.metadata.title}</title>
<link>${url}/blog/${postUrl(post)}</link>
<description>${post.metadata.excerpt}</description>
<pubDate>${post.metadata.published.toUTCString()}</pubDate>
</item>`,
	)
	.join('')}
</channel>
</rss>`;

	return {
		status: 200,
		headers,
		body,
	};
}
