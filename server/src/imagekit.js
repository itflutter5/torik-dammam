const uploadUrl = 'https://upload.imagekit.io/api/v1/files/upload';

export async function uploadImage(file, userId) {
  const privateKey = process.env.IMAGEKIT_PRIVATE_KEY;
  const endpoint = process.env.IMAGEKIT_URL_ENDPOINT?.replace(/\/$/, '');
  if (!privateKey || !endpoint) throw new Error('ImageKit is not configured');

  const form = new FormData();
  form.append('file', new Blob([file.buffer], { type: file.mimetype }));
  form.append('fileName', `${Date.now()}-${file.originalname}`);
  form.append('folder', `/scrapmarket/posts/${userId}`);
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
