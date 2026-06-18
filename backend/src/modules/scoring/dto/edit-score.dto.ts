import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsInt, Min, ValidateNested } from 'class-validator';

export class EditSetItemDto {
  @IsInt() @Min(1) setNumber!: number;
  @IsInt() @Min(0) homePoints!: number;
  @IsInt() @Min(0) awayPoints!: number;
}

export class EditScoreDto {
  @IsArray()
  @ArrayMaxSize(5)
  @ValidateNested({ each: true })
  @Type(() => EditSetItemDto)
  sets!: EditSetItemDto[];
}
