import { colors, typography } from '@/lib/brand'

export default function Home() {
  return (
    <main style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '100vh' }}>
      <h1 style={{ fontFamily: typography.display, color: colors.terra, fontSize: '2.5rem', fontWeight: 400 }}>
        SpecFlow
      </h1>
    </main>
  )
}
