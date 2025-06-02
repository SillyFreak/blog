import type { APIRoute } from "astro";

import rss from '@astrojs/rss';
import { blogEntries, blogEntryUrl } from '$lib/blog';
import { SITE_TITLE, SITE_DESCRIPTION } from '$lib/consts';

export const GET: APIRoute = async (context) => {
  const posts = await blogEntries();
  return rss({
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
    site: context.site!,
    items: posts.map((post) => {
      let { published, ...data } = post.data;
      return ({
        ...data,
        pubDate: published,
        link: blogEntryUrl(post),
      });
    }),
  });
};
