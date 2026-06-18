import { IsIn, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export const EVENT_TYPES = ['ATTACK', 'BLOCK', 'SERVE_ACE', 'POINT', 'ERROR'] as const;

export class RecordEventDto {
  @IsString()
  teamId!: string;

  @IsOptional()
  @IsString()
  playerId?: string;

  @IsIn(EVENT_TYPES)
  type!: (typeof EVENT_TYPES)[number];

  @IsInt()
  @Min(1)
  @Max(5)
  setNumber!: number;
}
