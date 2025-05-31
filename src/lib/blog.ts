import { type CollectionEntry, getCollection } from 'astro:content';

export type BlogEntry = CollectionEntry<'blog'>;
export type BlogMeta = BlogEntry['data'];

export type BlogSlugParts = {
	yyyy: string,
	mm: string,
	dd: string,
	slug: string,
};

export function blogEntries(filter?: (entry: BlogEntry) => unknown): Promise<BlogEntry[]> {
	return getCollection('blog', filter);
}

export function blogEntrySlugParts(entry: BlogEntry): BlogSlugParts {
	const published = entry.data.published;
	const yyyy = String(published.getUTCFullYear()).padStart(4, '0');
	const mm = String(published.getUTCMonth() + 1).padStart(2, '0');
	const dd = String(published.getUTCDate()).padStart(2, '0');
	const slug = entry.id.split('-', 2).pop()!;
	return { yyyy, mm, dd, slug };
}

export function blogEntryUrl(entry: BlogEntry): string {
	const { yyyy, mm, dd, slug } = blogEntrySlugParts(entry);
	return `/${yyyy}/${mm}/${dd}/${slug}`;
}
