import {
  IsEmail,
  IsEnum,
  IsInt,
  IsISO8601,
  IsOptional,
  IsString,
  IsUrl,
  Max,
  Min,
  MinLength,
} from 'class-validator';
import { PlayerPosition } from '@prisma/client';

export class CreateClubDto {
  @IsString() @MinLength(2) name!: string;
  @IsOptional() @IsString() city?: string;
  @IsOptional() @IsString() country?: string;
  @IsOptional() @IsUrl() crestUrl?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() phone?: string;
}

export class CreateTeamDto {
  @IsString() @MinLength(2) name!: string;
  @IsString() categoryId!: string;
  @IsOptional() @IsString() coachName?: string;
  @IsOptional() @IsString() delegateName?: string;
}

export class CreatePlayerDto {
  @IsString() fullName!: string;
  @IsOptional() @IsUrl() photoUrl?: string;
  @IsOptional() @IsString() document?: string;
  @IsOptional() @IsISO8601() birthDate?: string;
  @IsOptional() @IsEnum(PlayerPosition) position?: PlayerPosition;
  @IsOptional() @IsInt() @Min(1) @Max(99) jerseyNumber?: number;
  @IsOptional() @IsInt() @Min(100) @Max(260) heightCm?: number;
  @IsOptional() @IsInt() @Min(30) @Max(200) weightKg?: number;
}

export class CreateStaffDto {
  @IsString() fullName!: string;
  @IsString() role!: string; // coach | assistant | doctor | delegate
}
