import { Injectable, Logger } from '@nestjs/common';

import { AuthenticatedUser } from '../../common/auth/authenticated-user';
import { ContactDto } from './dto/contact.dto';
import faqData from './data/faq.json';

/** Entrée de FAQ exposée à l'API (le contenu interne est filtré/trié). */
export interface FaqEntryDto {
  id: string;
  category: string;
  question: string;
  answer: string;
}

/** Forme brute d'une entrée dans `faq.json` (avec champs d'édition internes). */
interface RawFaqEntry {
  id: string;
  category: string;
  order: number;
  published: boolean;
  question: string;
  answer: string;
}

@Injectable()
export class HelpService {
  private readonly logger = new Logger(HelpService.name);

  /**
   * FAQ du centre d'aide. Source = fichier `data/faq.json` versionné (édition
   * manuelle, sans base ni redéploiement de schéma). Seules les entrées
   * publiées sont renvoyées, triées par `order`, sans les champs internes.
   */
  listFaq(): FaqEntryDto[] {
    const entries = faqData.entries as RawFaqEntry[];
    return entries
      .filter((entry) => entry.published)
      .sort((a, b) => a.order - b.order)
      .map((entry) => ({
        id: entry.id,
        category: entry.category,
        question: entry.question,
        answer: entry.answer,
      }));
  }

  /**
   * Réception d'un message « Nous contacter ». Pour l'instant on journalise le
   * message avec l'identité (id + anonyme) et la version d'app ; l'envoi d'un
   * e-mail réel au support sera branché ultérieurement.
   */
  submitContact(user: AuthenticatedUser, dto: ContactDto): { status: 'received' } {
    this.logger.log(
      {
        userId: user.id,
        isAnonymous: user.isAnonymous,
        appVersion: dto.appVersion ?? 'unknown',
        subject: dto.subject,
        message: dto.message,
      },
      'Nouveau message de contact',
    );
    return { status: 'received' };
  }
}
