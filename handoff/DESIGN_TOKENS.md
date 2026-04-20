# Design tokens — Mnemata rediseño

Fuente canónica: los tokens que ves aquí son los mismos que se usan en los
mocks (`Mnemata Redesign.html` → `tokens.css`). Están definidos en **oklch**
para poder reasonarlos; incluyo la conversión a hex para `Color(0xFF…)` en Dart.

> Si tu IDE no muestra bien los hex de oklch, confía en el hex. El oklch está
> ahí para referencia futura y para que alguien entienda por qué son así.

---

## Color

### Neutros cálidos (modo claro)

| Token | oklch | hex | Uso |
|---|---|---|---|
| `paper` | `oklch(0.985 0.004 75)` | `#FBF9F4` | Fondo principal, scaffold |
| `paper-2` | `oklch(0.965 0.006 75)` | `#F3EFE8` | Fondo elevado, cards, sheets |
| `paper-3` | `oklch(0.94 0.008 75)` | `#EAE5DB` | Hover, chips inactivos, input bg |
| `ink` | `oklch(0.18 0.012 65)` | `#241F17` | Tinta principal — titulares, cuerpo |
| `ink-2` | `oklch(0.34 0.010 65)` | `#514A3F` | Tinta secundaria |
| `ink-3` | `oklch(0.55 0.008 65)` | `#8A8273` | Muted — meta, timestamps |
| `ink-4` | `oklch(0.74 0.006 75)` | `#BDB5A3` | Divider fuerte, iconos sutiles |
| `rule` | `oklch(0.88 0.006 75)` | `#DDD6C6` | Divider sutil |

### Acento único

| Token | oklch | hex | Uso |
|---|---|---|---|
| `accent` | `oklch(0.66 0.17 52)` | `#D18648` | Punto de la marca, switches on, highlights |
| `accent-ink` | `oklch(0.42 0.17 48)` | `#7A4818` | Texto ámbar sobre claro (kicker, links) |
| `accent-soft` | `oklch(0.93 0.05 70)` | `#F3E5CC` | Wash / background de highlight |

### Semánticos

| Token | hex | Uso |
|---|---|---|
| `danger` | `#B43828` | Delete, destructive |
| `success` | `#4A7E4A` | Sync dot, estados ok |

### Paleta de tags (claro)

6 colores, desaturados, misma luminosidad — evitan competir con el acento.

| Token | hex | Hint |
|---|---|---|
| `tag-1` | `#B07445` | ámbar tierra |
| `tag-2` | `#568F8E` | teal |
| `tag-3` | `#7A80B8` | índigo |
| `tag-4` | `#B36F8A` | rosa viejo |
| `tag-5` | `#7D9361` | oliva |
| `tag-6` | `#7D6D5C` | tabaco |

### Modo oscuro

| Token | hex |
|---|---|
| `paper` | `#201E1A` |
| `paper-2` | `#2A2824` |
| `paper-3` | `#35322D` |
| `ink` | `#F3F0EB` |
| `ink-2` | `#C9C3B8` |
| `ink-3` | `#958F83` |
| `ink-4` | `#605B51` |
| `rule` | `#3F3C37` |
| `accent` | `#E3A870` |
| `accent-ink` | `#E8B680` |
| `accent-soft` | `#453625` |

---

## Tipografía

Ver detalle completo en [`TYPOGRAPHY.md`](./TYPOGRAPHY.md).

**Tres familias, cada una con un rol claro:**

| Familia | Rol | Dónde |
|---|---|---|
| **Instrument Serif** | Editorial | Titulares, artículo, marca |
| **Geist** | Interfaz | Labels, buttons, nav, body UI |
| **JetBrains Mono** | Metadato | Timestamps, read time, sources, keybinds |

### Escala

| Token | px | Uso típico |
|---|---|---|
| `text-2xs` | 11 | Uppercase meta |
| `text-xs` | 12 | Labels pequeños |
| `text-sm` | 13 | Body UI compacto |
| `text-base` | 15 | Body UI |
| `text-md` | 17 | List row title |
| `text-lg` | 20 | H3, article subtitle |
| `text-xl` | 24 | H2 |
| `text-2xl` | 32 | H1 en screens |
| `text-3xl` | 44 | Headline móvil |
| `text-4xl` | 64 | Headline desktop |

---

## Spacing

Escala geométrica, múltiplos de 4:

```
4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 96
```

En Dart: usa `const EdgeInsets.all(16)`, `const SizedBox(height: 24)`, etc.
No añadas valores intermedios (5, 14, 18…).

---

## Radios

| Token | px | Uso |
|---|---|---|
| `r-sm` | 6 | Chips, inline pills pequeños |
| `r-md` | 10 | Inputs, botones de icono |
| `r-lg` | 14 | Cards, contenedores |
| `r-xl` | 22 | Sheets (top only), dialogs |
| `r-full` | 999 | Pills, FAB, tag chips |

---

## Elevación / shadows

Muy discretas. No uses `BoxShadow` agresivas.

```dart
// sh-1 — elevación mínima
const shadow1 = [BoxShadow(color: Color(0x0A1E190F), offset: Offset(0, 1), blurRadius: 2)];

// sh-2 — card estándar
const shadow2 = [
  BoxShadow(color: Color(0x0F1E190F), offset: Offset(0, 2), blurRadius: 8),
  BoxShadow(color: Color(0x0A1E190F), offset: Offset(0, 1), blurRadius: 2),
];

// sh-float — FAB, sheets
const shadowFloat = [
  BoxShadow(color: Color(0x141E190F), offset: Offset(0, 20), blurRadius: 40),
  BoxShadow(color: Color(0x0F1E190F), offset: Offset(0, 6), blurRadius: 16),
];
```

En oscuro:

```dart
// sh-float dark
const shadowFloatDark = [
  BoxShadow(color: Color(0x80000000), offset: Offset(0, 24), blurRadius: 48),
  BoxShadow(color: Color(0x591E190F), offset: Offset(0, 8), blurRadius: 20),
];
```

---

## Animación / duraciones

| Token | ms | Uso |
|---|---|---|
| `dur-fast` | 120 | Tap feedback, hover |
| `dur-base` | 220 | Navegación entre screens, sheets |
| `dur-slow` | 400 | Reveal, transiciones significativas |

Curvas: `Curves.easeOutCubic` por defecto, `Curves.easeInOutCubic` para
reveals simétricos.
