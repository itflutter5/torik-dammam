import { z } from 'zod';

export const postSchema = z.object({
  category: z.string().trim().min(2).max(30),
  title: z.string().trim().min(3).max(150),
  description: z.string().trim().min(10).max(5000),
  price: z.union([z.string().trim().min(1), z.number()])
    .pipe(z.coerce.number().nonnegative().max(9999999999)),
  unit: z.enum(['Ton', 'kg', 'pics', '']).optional().default(''),
  storeNumber: z.string().regex(/^\d{1,4}$/),
}).superRefine((input, ctx) => {
  if (!['Need Worker', 'Need Job'].includes(input.category) && !input.unit) {
    ctx.addIssue({ code: 'custom', path: ['unit'], message: 'Select a unit' });
  }
});

export const postPhotosSchema = z.array(z.unknown()).min(1, 'Add at least one photo').max(3);
