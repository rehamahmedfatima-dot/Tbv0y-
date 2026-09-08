import { z } from "zod";

export const promoteToLawyerSchema = z.object({
  email: z.string().email("Enter a valid email address")
});
export type PromoteToLawyerInput = z.infer<typeof promoteToLawyerSchema>;
