import { z } from 'zod';

const password = z.string().min(1).max(100);

export const passwordLoginSchema = z.union([
  z.object({
    email: z.string().trim().toLowerCase().email().max(254),
    password,
  }).strict(),
  z.object({
    phone: z.string().trim().regex(/^\+9665\d{8}$/),
    password,
  }).strict(),
]);
