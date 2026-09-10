import { ConfigService } from '@nestjs/config';

import { UnsplashService } from './unsplash.service';

const config = (accessKey: string | undefined) =>
  ({ get: () => accessKey }) as unknown as ConfigService;

describe('UnsplashService', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('search', () => {
    it('renvoie une liste vide sans access key (pas d’appel réseau)', async () => {
      const fetchSpy = jest.spyOn(global, 'fetch');
      const service = new UnsplashService(config(undefined));
      const results = await service.search('tarte');
      expect(results).toEqual([]);
      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('ajoute les paramètres utm au lien du photographe et mappe le download_location', async () => {
      jest.spyOn(global, 'fetch').mockResolvedValue({
        ok: true,
        json: async () => ({
          results: [
            {
              id: 'photo-1',
              urls: { thumb: 'https://images.unsplash.com/thumb', regular: 'https://images.unsplash.com/regular' },
              user: { name: 'Annie Spratt', links: { html: 'https://unsplash.com/@anniespratt' } },
              links: { download_location: 'https://api.unsplash.com/photos/photo-1/download' },
            },
          ],
        }),
      } as Response);
      const service = new UnsplashService(config('test-key'));
      const [suggestion] = await service.search('tarte');
      expect(suggestion.authorName).toBe('Annie Spratt');
      expect(suggestion.authorUrl).toBe(
        'https://unsplash.com/@anniespratt?utm_source=cocotte_minute&utm_medium=referral',
      );
      expect(suggestion.downloadLocation).toBe(
        'https://api.unsplash.com/photos/photo-1/download',
      );
    });
  });

  describe('trackDownload', () => {
    it('ignore une URL qui ne pointe pas vers api.unsplash.com (défense en profondeur)', async () => {
      const fetchSpy = jest.spyOn(global, 'fetch');
      const service = new UnsplashService(config('test-key'));
      await service.trackDownload('https://evil.example.com/steal');
      expect(fetchSpy).not.toHaveBeenCalled();
    });

    it('appelle download_location avec le Client-ID quand l’URL est valide', async () => {
      const fetchSpy = jest
        .spyOn(global, 'fetch')
        .mockResolvedValue({ ok: true } as Response);
      const service = new UnsplashService(config('test-key'));
      await service.trackDownload('https://api.unsplash.com/photos/photo-1/download');
      expect(fetchSpy).toHaveBeenCalledWith(
        'https://api.unsplash.com/photos/photo-1/download',
        { headers: { Authorization: 'Client-ID test-key' } },
      );
    });
  });
});
