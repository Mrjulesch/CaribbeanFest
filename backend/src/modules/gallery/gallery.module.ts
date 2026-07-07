import { Body, Controller, Delete, Get, Module, Param, Post, Query } from '@nestjs/common';
import { IsIn, IsOptional, IsString, IsUrl } from 'class-validator';
import { GallerySection, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';

class CreateGalleryDto {
  @IsUrl() imageUrl!: string;
  @IsOptional() @IsString() caption?: string;
  @IsIn(['PAST', 'FUTURE']) section!: GallerySection;
}

@Controller('gallery')
class GalleryController {
  constructor(private readonly prisma: PrismaService) {}

  /** Galería pública. Filtrable por sección (PAST | FUTURE). */
  @Public() @Get()
  list(@Query('section') section?: GallerySection) {
    return this.prisma.galleryItem.findMany({
      where: section ? { section } : undefined,
      orderBy: { createdAt: 'desc' },
    });
  }

  @Roles(Role.ADMIN) @Post()
  create(@Body() dto: CreateGalleryDto) {
    return this.prisma.galleryItem.create({ data: dto });
  }

  @Roles(Role.ADMIN) @Delete(':id')
  remove(@Param('id') id: string) {
    return this.prisma.galleryItem.delete({ where: { id } });
  }
}

@Module({ controllers: [GalleryController] })
export class GalleryModule {}
