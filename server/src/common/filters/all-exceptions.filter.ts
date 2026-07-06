import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';
import { PinoLogger } from 'nestjs-pino';

/**
 * Filtre global : capte TOUTE exception, la journalise (stack complète pour les
 * 5xx, niveau warn pour les erreurs client 4xx), et renvoie une réponse JSON
 * homogène. Sans ça, une erreur DB non gérée (ex: table absente) partait en 500
 * silencieux, sans trace côté serveur.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  constructor(
    private readonly httpAdapterHost: HttpAdapterHost,
    private readonly logger: PinoLogger,
  ) {
    this.logger.setContext(AllExceptionsFilter.name);
  }

  catch(exception: unknown, host: ArgumentsHost): void {
    const { httpAdapter } = this.httpAdapterHost;
    const ctx = host.switchToHttp();
    const request = ctx.getRequest<unknown>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const rawMessage =
      exception instanceof HttpException ? exception.getResponse() : 'Internal server error';

    const method = httpAdapter.getRequestMethod(request);
    const url = httpAdapter.getRequestUrl(request);

    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      // 5xx : on veut la stack complète pour diagnostiquer.
      this.logger.error({ err: exception, method, url, status }, `✖ ${method} ${url} → ${status}`);
    } else {
      // 4xx : erreur client attendue, log allégé.
      this.logger.warn({ method, url, status, message: rawMessage }, `⚠ ${method} ${url} → ${status}`);
    }

    const message =
      typeof rawMessage === 'object' && rawMessage !== null && 'message' in rawMessage
        ? (rawMessage as { message: unknown }).message
        : rawMessage;

    httpAdapter.reply(
      ctx.getResponse<unknown>(),
      {
        statusCode: status,
        timestamp: new Date().toISOString(),
        path: url,
        message,
      },
      status,
    );
  }
}
