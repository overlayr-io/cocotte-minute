import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { BillingController } from './billing.controller';
import { BillingService } from './billing.service';

const SECRET = 'valeur-secrete-du-dashboard';

function make() {
  const billing = {
    applyWebhook: jest.fn().mockResolvedValue('applied'),
  } as unknown as jest.Mocked<Pick<BillingService, 'applyWebhook'>>;
  const config = {
    getOrThrow: jest.fn().mockReturnValue(SECRET),
  } as unknown as ConfigService;
  const controller = new BillingController(billing as unknown as BillingService, config);
  return { controller, billing };
}

describe('BillingController — POST /billing/revenuecat', () => {
  it('rejette en 401 sans header Authorization', async () => {
    const { controller, billing } = make();
    await expect(controller.revenueCatWebhook(undefined, {})).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(billing.applyWebhook).not.toHaveBeenCalled();
  });

  it('rejette en 401 avec un header Authorization erroné', async () => {
    const { controller, billing } = make();
    await expect(controller.revenueCatWebhook('mauvaise-valeur', {})).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(billing.applyWebhook).not.toHaveBeenCalled();
  });

  it('accepte le header exact et délègue au service', async () => {
    const { controller, billing } = make();
    const body = { api_version: '1.0', event: { type: 'TEST' } };

    await expect(controller.revenueCatWebhook(SECRET, body)).resolves.toEqual({
      received: true,
    });
    expect(billing.applyWebhook).toHaveBeenCalledWith(body);
  });
});
