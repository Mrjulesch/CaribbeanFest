import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDeviceDto {
  @IsString() token!: string;
  @IsOptional() @IsString() platform?: string; // android | ios | web
}

export class FollowDto {
  @IsString() token!: string;
  @IsIn(['team', 'tournament']) kind!: 'team' | 'tournament';
  @IsString() id!: string;
}

export class AnnouncementDto {
  @IsString() @MinLength(3) title!: string;
  @IsString() @MinLength(1) body!: string;
}
