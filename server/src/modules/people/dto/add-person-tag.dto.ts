import { IsUUID } from 'class-validator';

export class AddPersonTagDto {
  @IsUUID()
  tagId!: string;
}
