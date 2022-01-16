export default async function allPosts() {
	const posts = Object.entries(import.meta.glob('./*.svelte.md'));
	return Promise.all(
		posts.map(async ([path, resolver]) => {
			const slug = path.slice(2, -10);
			const post = await resolver();
			return { slug, post };
		}),
	);
}
