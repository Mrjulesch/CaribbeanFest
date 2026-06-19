import {
  IsBoolean,
  IsEnum,
  IsIn,
  IsISO8601,
  IsOptional,
  IsString,
  IsUrl,
  MinLength,
} from 'class-validator';
import { CompetitionFormat, Gender } from '@prisma/client';

export class CreateTournamentDto {
  @IsString()
  @MinLength(3)
  name!: string;

  @IsISO8601()
  startDate!: string;

  @IsISO8601()
  endDate!: string;

  @IsOptional()
  @IsUrl()
  logoUrl?: string;

  @IsOptional()
  @IsUrl()
  rulebookUrl?: string;

  @IsOptional()
  @IsString()
  paymentLink?: string;
}

export class UpdateTournamentDto {
  @IsOptional() @IsString() @MinLength(3) name?: string;
  @IsOptional() @IsISO8601() startDate?: string;
  @IsOptional() @IsISO8601() endDate?: string;
  @IsOptional() @IsUrl() logoUrl?: string;
  @IsOptional() @IsUrl() rulebookUrl?: string;
  @IsOptional() @IsBoolean() isPublished?: boolean;
  @IsOptional() @IsString() paymentLink?: string;
}

export class CreateCategoryDto {
  @IsString()
  name!: string; // "Sub 14", "Universitario", "Libre"

  @IsEnum(Gender)
  gender!: Gender;

  @IsOptional()
  @IsEnum(CompetitionFormat)
  format?: CompetitionFormat;

  @IsOptional()
  @IsIn([3, 5])
  bestOf?: number; // 3 = mejor de 3 ; 5 = mejor de 5
}

export class CreateVenueDto {
  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  address?: string;
}

export class CreateCourtDto {
  @IsString()
  name!: string;
}
