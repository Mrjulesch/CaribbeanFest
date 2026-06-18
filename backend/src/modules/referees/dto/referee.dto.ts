import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateRefereeProfileDto {
  @IsString() userId!: string; // usuario con rol REFEREE
  @IsOptional() @IsString() license?: string;
  @IsOptional() @IsString() level?: string;
}

export class AssignRefereeDto {
  @IsString() refereeId!: string; // RefereeProfile.id
  @IsOptional() @IsString() role?: string; // first | second | scorer | line
}

export class CreateRefereeDto {
  @IsString() fullName!: string;
  @IsEmail() email!: string;
  @IsString() @MinLength(8) password!: string;
  @IsOptional() @IsString() license?: string;
  @IsOptional() @IsString() level?: string;
}
