import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

// Registro público: SIEMPRE crea cuentas de club. Los roles privilegiados
// (ADMIN / REFEREE) no se pueden auto-asignar; se crean por seed o por el admin.
export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsString()
  fullName!: string;

  @IsOptional()
  @IsString()
  phone?: string;
}

export class LoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  password!: string;
}

export class RefreshDto {
  @IsString()
  refreshToken!: string;
}

// Creación de un co-administrador (solo un admin puede hacerlo).
export class CreateAdminDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  password!: string;

  @IsString()
  fullName!: string;
}
