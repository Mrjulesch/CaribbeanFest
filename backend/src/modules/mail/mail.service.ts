import { Injectable, Logger } from '@nestjs/common';

/**
 * Envío de correos con degradación elegante. Soporta Resend o SendGrid según la
 * variable de entorno disponible; si no hay ninguna, opera en "modo registro"
 * (loguea el correo) para no romper el flujo en desarrollo/sin configurar.
 *
 * Variables:
 *   MAIL_FROM           remitente (ej. "Caribbean Fest <no-reply@tudominio.com>")
 *   RESEND_API_KEY      (opcional) usa Resend  — requiere dominio verificado
 *   SENDGRID_API_KEY    (opcional) usa SendGrid — basta verificar un remitente
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);

  private get from(): string {
    return process.env.MAIL_FROM ?? 'Caribbean Fest <onboarding@resend.dev>';
  }

  async send(to: string, subject: string, html: string): Promise<void> {
    const resendKey = process.env.RESEND_API_KEY;
    const sendgridKey = process.env.SENDGRID_API_KEY;

    if (resendKey) return this.sendResend(resendKey, to, subject, html);
    if (sendgridKey) return this.sendSendgrid(sendgridKey, to, subject, html);

    this.logger.warn(`[MAIL stub] (sin proveedor) Para: ${to} | Asunto: ${subject}`);
  }

  private async sendResend(key: string, to: string, subject: string, html: string) {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: this.from, to, subject, html }),
    });
    if (!res.ok) this.logger.error(`Resend falló (${res.status}): ${await res.text()}`);
    else this.logger.log(`Correo enviado (Resend) a ${to}`);
  }

  private async sendSendgrid(key: string, to: string, subject: string, html: string) {
    // MAIL_FROM puede venir como "Nombre <correo>"; extraemos el correo.
    const match = this.from.match(/<(.+)>/);
    const fromEmail = match ? match[1] : this.from;
    const res = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: to }] }],
        from: { email: fromEmail },
        subject,
        content: [{ type: 'text/html', value: html }],
      }),
    });
    if (!res.ok) this.logger.error(`SendGrid falló (${res.status}): ${await res.text()}`);
    else this.logger.log(`Correo enviado (SendGrid) a ${to}`);
  }
}
