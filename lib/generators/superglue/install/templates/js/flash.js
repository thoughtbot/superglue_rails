import { useFlash } from "@thoughtbot/superglue"

/**
 * A typed wrapper around useFlash. Customize the return shape
 * to match the flash keys your application uses.
 */
export const useAppFlash = () => useFlash()
