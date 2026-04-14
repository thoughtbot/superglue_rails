import { useFlash } from "@thoughtbot/superglue";

/**
 * Customize this type to match the flash keys your application uses.
 */
export type AppFlash = {
  success?: string;
  notice?: string;
  alert?: string;
  error?: string;
  [key: string]: unknown;
};

/**
 * A typed wrapper around useFlash. Returns flash narrowed to
 * your application's flash shape.
 */
export const useAppFlash = () => useFlash<AppFlash>();
