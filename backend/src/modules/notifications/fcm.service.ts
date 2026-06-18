import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { PushMessage } from './notification-messages';

/**
 * Envoltura sobre Firebase Cloud Messaging con degradación elegante: si no hay
 * credenciales (`FIREBASE_SERVICE_ACCOUNT`), opera en modo log y la app sigue
 * funcionando (útil en desarrollo, CI y tests). En producción se inyecta el JSON
 * de la cuenta de servicio por variable de entorno.
 */
@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private enabled = false;

  onModuleInit() {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (!raw) {
      this.logger.warn('FCM deshabilitado (sin FIREBASE_SERVICE_ACCOUNT) — modo log');
      return;
    }
    try {
      const cred = JSON.parse(raw);
      if (getApps().length === 0) {
        initializeApp({ credential: cert(cred) });
      }
      this.enabled = true;
      this.logger.log('FCM inicializado');
    } catch (e) {
      this.logger.error('FCM no inicializado: credenciales inválidas', e as Error);
    }
  }

  async sendToTopic(topic: string, msg: PushMessage): Promise<void> {
    if (!this.enabled) {
      this.logger.log(`[FCM stub] topic=${topic} :: ${msg.title} — ${msg.body}`);
      return;
    }
    await getMessaging().send({
      topic,
      notification: { title: msg.title, body: msg.body },
      data: msg.data,
    });
  }

  async sendToTopics(topics: string[], msg: PushMessage): Promise<void> {
    await Promise.all([...new Set(topics)].map((t) => this.sendToTopic(t, msg)));
  }

  async subscribe(tokens: string[], topic: string): Promise<void> {
    if (!this.enabled) {
      this.logger.log(`[FCM stub] subscribe ${tokens.length} token(s) → ${topic}`);
      return;
    }
    await getMessaging().subscribeToTopic(tokens, topic);
  }

  async unsubscribe(tokens: string[], topic: string): Promise<void> {
    if (!this.enabled) {
      this.logger.log(`[FCM stub] unsubscribe ${tokens.length} token(s) → ${topic}`);
      return;
    }
    await getMessaging().unsubscribeFromTopic(tokens, topic);
  }
}
