import { Body, Controller, Get, HttpCode, Post } from '@nestjs/common';
import { Role } from '@prisma/client';
import { AuthService } from './auth.service';
import { CreateAdminDto, LoginDto, RefreshDto, RegisterDto } from './dto/auth.dto';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser, AuthUser } from '../../common/decorators/current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  /** Solo un admin puede crear otro co-administrador. */
  @Roles(Role.ADMIN)
  @Post('admins')
  createAdmin(@Body() dto: CreateAdminDto) {
    return this.auth.createAdmin(dto);
  }

  @Public()
  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Public()
  @HttpCode(200)
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Public()
  @HttpCode(200)
  @Post('refresh')
  refresh(@Body() dto: RefreshDto) {
    return this.auth.refresh(dto.refreshToken);
  }

  /** Requiere JWT (guard global). Devuelve el usuario del token. */
  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return user;
  }
}
