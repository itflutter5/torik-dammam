import crypto from 'node:crypto';
import sharp from 'sharp';

const uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

export async function uploadImage(file, userId, folder = 'posts') {
  const privateKey = process.env.IMAGEKIT_PRIVATE_KEY;
  const endpoint = process.env.IMAGEKIT_URL_ENDPOINT?.replace(/\/$/, '');
  if (!privateKey || !endpoint) throw new Error('ImageKit is not configured');

  const compressed = await sharp(file.buffer, { failOn: 'error' })
    .rotate()
    .resize({ width: 1800, height: 1800, fit: 'inside', withoutEnlargement: true })
    .webp({ quality: 80, effort: 4 })
    .toBuffer();

  const form = new FormData();
  form.append('file', new Blob([compressed], { type: 'image/webp' }));
  form.append('fileName', `${Date.now()}-${crypto.randomUUID()}.webp`);
  form.append('folder', `/scrapmarket/${folder}/${userId}`);
  form.append('useUniqueFileName', 'true');

  const response = await fetch(uploadUrl, {
    method: 'POST',
    headers: { Authorization: `Basic ${Buffer.from(`${privateKey}:`).toString('base64')}` },
    body: form,
  });
  const result = await response.json();
  if (!response.ok) throw new Error(result.message ?? 'ImageKit upload failed');
  return result.url ?? `${endpoint}/${result.filePath}`;
}
