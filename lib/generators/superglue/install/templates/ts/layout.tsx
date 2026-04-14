import React, {ReactNode} from 'react'
import { useAppFlash } from '@javascript/flash'

export const Layout = ({children}: {children: ReactNode}) => {
  const flash = useAppFlash()

  return (
    <div>
      {flash.success && <p>{flash.success}</p>}
      {flash.notice && <p>{flash.notice}</p>}
      {flash.error && <p>{flash.error}</p>}

      {children}
    </div>
  )
}
