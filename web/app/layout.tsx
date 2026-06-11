import type { Metadata } from 'next'
import { typography, colors } from '@/lib/brand'

export const metadata: Metadata = {
  title: 'SpecFlow',
  description: 'Turn customer feedback into product specs.',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body style={{ fontFamily: typography.body, background: colors.paper, color: colors.charcoal, margin: 0 }}>
        {children}
      </body>
    </html>
  )
}
