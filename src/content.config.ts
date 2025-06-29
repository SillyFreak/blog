import { glob } from 'astro/loaders';
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  // Load Typst files in the `content/blog/` directory.
  loader: glob({ base: './content/blog', pattern: '**/*.typ' }),
  // Type-check frontmatter using a schema
  schema: z.object({
    title: z.string(),
    author: z.string().optional(),
    description: z.any().optional(),
    published: z.coerce.date(),
    edited: z.coerce.date().optional(),
    tags: z.array(z.string()).optional(),
    heroImage: z.string().optional(),
    excerpt: z.string().optional(),
  }),
});

export const collections = { blog };
