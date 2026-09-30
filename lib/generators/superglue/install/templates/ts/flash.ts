import { useFlash } from "@thoughtbot/superglue";
import type { ValidationErrors } from "@thoughtbot/candy_wrapper";

/**
 * Customize this type to match the flash keys your application uses.
 */
export type AppFlash = {
  success?: string;
  notice?: string;
  alert?: string;
  error?: string;
  // Form errors the scaffold stores under e.g. flash["postFormErrors"]
  [key: `${string}FormErrors`]: ValidationErrors | undefined;
  [key: string]: unknown;
};

/**
 * A typed wrapper around useFlash. Returns flash narrowed to
 * your application's flash shape.
 */
export const useAppFlash = () => useFlash<AppFlash>();
