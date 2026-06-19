import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEmail,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class RegistrationPlayerDto {
  @IsString() @MinLength(2) fullName!: string;
  @IsOptional() @IsString() document?: string;
  @IsOptional() @IsInt() @Min(5) @Max(80) age?: number;
  @IsOptional() @IsString() eps?: string;
  @IsOptional() @IsInt() @Min(1) @Max(99) jerseyNumber?: number;
  @IsOptional() @IsString() position?: string;
}

export class CreateRegistrationDto {
  @IsString() tournamentId!: string;
  @IsString() categoryId!: string;
  @IsString() @MinLength(2) teamName!: string;
  @IsOptional() @IsString() clubName?: string;
  @IsOptional() @IsString() city?: string;

  // Datos de contacto del delegado.
  @IsString() @MinLength(2) contactName!: string;
  @IsEmail() contactEmail!: string;
  @IsString() @MinLength(5) contactPhone!: string;

  @IsArray()
  @ArrayMaxSize(14, { message: 'Máximo 14 jugadores por equipo' })
  @ValidateNested({ each: true })
  @Type(() => RegistrationPlayerDto)
  players!: RegistrationPlayerDto[];
}

export class RejectRegistrationDto {
  @IsOptional() @IsString() notes?: string;
}

export class ApproveRegistrationDto {
  @IsOptional() @IsString() paymentLink?: string;
}
