export const colors = {
  paper:    '#F8F4EF',
  terra:    '#E8561B',
  sage:     '#3D6B5E',
  charcoal: '#0D0D0D',
} as const

export const typography = {
  display:  "'Instrument Serif', Georgia, serif",
  body:     "'DM Sans', system-ui, sans-serif",
  metadata: "'ui-monospace', 'SFMono-Regular', monospace",
} as const

export const radius = {
  input:   '4px',
  button:  '4px',
  card:    '8px',
  overlay: '12px',
} as const

export const border = {
  default: '1px solid rgba(13,13,13,0.12)',
} as const

export const shadow = {
  card:    'none',
  overlay: '0 8px 30px rgba(13,13,13,0.12)',
} as const

export const glass = {
  overlay: {
    backdropFilter: 'blur(12px)',
    background:     'rgba(248,244,239,0.7)',
  },
} as const

export const focus = {
  ring: `0 0 0 2px ${colors.terra}`,
} as const

export const states = {
  skeletonBase:    colors.paper,
  destructiveBg:   colors.terra,
  destructiveText: colors.paper,
} as const
