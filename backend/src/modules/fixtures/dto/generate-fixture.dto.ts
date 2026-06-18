import { IsInt, IsISO8601, IsOptional, Max, Min } from 'class-validator';

export class GenerateFixtureDto {
  @IsISO8601()
  startDate!: string;

  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(8)
  groupCount?: number;

  @IsOptional()
  @IsInt()
  @Min(30)
  @Max(240)
  slotMinutes?: number;

  @IsOptional()
  @IsInt()
  @Min(6)
  @Max(22)
  firstSlotHour?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  slotsPerDay?: number;
}
