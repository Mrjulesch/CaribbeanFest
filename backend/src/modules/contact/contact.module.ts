import { Body, Controller, Get, Post } from '@nestjs/common';
import { IsEmail, IsString, MinLength } from 'class-validator';
import { Module } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';

class CreateContactDto {
  @IsString() @MinLength(2) name!: string;
  @IsEmail() email!: string;
  @IsString() @MinLength(5) message!: string;
}

@Controller('contact')
class ContactController {
  constructor(private readonly prisma: PrismaService) {}

  /** Envío público del formulario "Contáctanos". */
  @Public() @Post()
  create(@Body() dto: CreateContactDto) {
    return this.prisma.contactMessage.create({ data: dto });
  }

  /** La organización lee los mensajes recibidos. */
  @Roles(Role.ADMIN) @Get()
  list() {
    return this.prisma.contactMessage.findMany({ orderBy: { createdAt: 'desc' } });
  }
}

@Module({ controllers: [ContactController] })
export class ContactModule {}
