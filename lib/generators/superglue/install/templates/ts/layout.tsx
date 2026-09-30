import type { ReactNode } from 'react'
import type { Handlers } from '@thoughtbot/superglue'
import { useAppFlash } from '@javascript/flash'

export const Layout = ({children, onClick, onSubmit}: {children: ReactNode} & Partial<Handlers>) => {
  const flash = useAppFlash()

  return (
    <div onClick={onClick} onSubmit={onSubmit}>
      {flash.success && <p>{flash.success}</p>}
      {flash.notice && <p>{flash.notice}</p>}
      {flash.error && <p>{flash.error}</p>}

      {children}
    </div>
  )
}
