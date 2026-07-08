# Design System Document: Mint & Marigold

## 1. Creative North Star: "The Social Veranda"
This design system departs from the high-stakes, smoke-filled "Midnight Dealer" aesthetic to embrace a feeling of afternoon sunlight, fresh air, and communal play. We are building a "Social Veranda"—an airy, light-filled space where the architecture is defined by soft edges and breezy color shifts rather than rigid barriers. 

To achieve a high-end editorial feel, we reject the "template" look of standard mobile apps. Instead of a strict vertical list, we utilize **intentional asymmetry**, **overlapping card stacks**, and **dynamic scale shifts**. The goal is to make the UI feel like a premium physical deck of cards spread across a clean linen table—approachable, tactile, and vibrantly alive.

---

### 2. Colors & Surface Philosophy
The palette is a curated mix of mint, amber, and teal, designed to evoke energy without causing eye fatigue.

*   **Primary (`#00694b`):** The Mint Forest. Used for key actions and brand presence.
*   **Secondary (`#765600` / `#ffca53`):** Sunny Amber. Reserved for moments of delight, winning states, and "Golden Moments."
*   **Tertiary (`#006762`):** Soft Teal. Used for social features and secondary UI elements.
*   **Background (`#f5f7f5`):** A crisp, off-white "linen" base that prevents the starkness of pure white.

#### The "No-Line" Rule
**Explicit Instruction:** Prohibit the use of 1px solid borders for sectioning. Boundaries must be defined solely through background color shifts. To separate a player’s hand from the game board, transition from `surface` to `surface-container-low`. 

#### The Glass & Gradient Rule
To move beyond "flat" design, use **Signature Textures**. Main CTAs should not be flat hex codes; they should utilize subtle linear gradients (e.g., `primary` to `primary-container` at a 135-degree angle). For floating UI elements like settings or chat bubbles, apply **Glassmorphism**: use `surface_container_lowest` at 80% opacity with a `20px` backdrop blur.

---

### 3. Typography: The Editorial Voice
We use a dual-font pairing to balance personality with high-end readability.

*   **Display & Headlines (Plus Jakarta Sans):** Our "Modern Friendly" voice. It features wide apertures and a geometric soul. Use `display-lg` (3.5rem) for big win announcements, allowing the letters to breathe with wide tracking (-2%).
*   **Title & Body (Be Vietnam Pro):** A highly legible, contemporary sans-serif. It provides a sophisticated "editorial" contrast to the more playful headlines.
*   **Hierarchy as Identity:** Use extreme scale contrast. A `display-sm` headline sitting next to a `label-sm` metadata tag creates a high-fashion, premium look that standard "medium-everything" apps lack.

---

### 4. Elevation & Depth: Tonal Layering
In this system, depth is organic, not artificial. We discard the "floating box" shadow-heavy look in favor of physical stacking.

*   **The Layering Principle:** 
    *   Base Layer: `surface`
    *   Section Layer: `surface-container-low`
    *   Interactive Card Layer: `surface-container-lowest` (White)
    *   This "nesting" creates a soft, natural lift that feels like high-quality paper stock.
*   **Ambient Shadows:** If a card must float (e.g., a dragged game card), use an "Amber Glow" shadow: `0px 20px 40px rgba(118, 86, 0, 0.08)`. This mimics natural light bouncing off the sunny secondary palette rather than a muddy grey shadow.
*   **The Ghost Border:** If accessibility requires a stroke, use `outline-variant` at **15% opacity**. It should be felt, not seen.

---

### 5. Components: Tactile Play

#### Buttons
*   **Primary:** A gradient-filled pill shape using `xl` (3rem) roundedness. No border. On-tap, the button should physically scale down to 96% to mimic the press of a soft button.
*   **Tertiary:** Text-only in `primary` weight, but placed on a `surface-container-high` rounded chip for a sophisticated, subtle "ghost" feel.

#### Cards & Lists
*   **Forbid Dividers:** Do not use lines between player names or card stats. Use `1.5rem` of vertical white space or alternate backgrounds between `surface-container-low` and `surface-container-lowest`.
*   **The Game Card:** Use the `lg` (2rem) corner radius. The typography on the card should use `headline-sm` for the value and `label-md` for the suit, pushed to the extreme corners to maximize white space.

#### Chips (Player Tags/Filters)
*   Use `full` (9999px) roundedness. For active states, use the `secondary_container` (Amber) to highlight the "active player" or "current bet," creating a warm focal point.

#### Input Fields
*   Soft, `md` (1.5rem) rounded containers with a `surface-container-highest` background. No border. On focus, transition the background to `primary_container` with a subtle 2px "Ghost Border" of `primary`.

---

### 6. Do's and Don'ts

**Do:**
*   **Embrace Asymmetry:** Let your "Player Hand" cards overlap slightly or sit at a 2-degree tilt. It feels human and playful.
*   **Use White Space as a Tool:** Give the "Deal" button enough breathing room to feel like the most important thing on the screen.
*   **Color Transitions:** Use `surface-tint` overlays (5% opacity) on top of imagery to make photos feel like they belong to the mint/teal world.

**Don't:**
*   **Don't use pure black (#000000):** Use `on_surface` (#2c2f2e) for text to maintain the soft, breezy vibe.
*   **Don't use sharp corners:** Nothing in this system should have a radius smaller than `sm` (0.5rem). Sharp corners break the "Social Veranda" promise.
*   **Don't clutter:** If the screen feels busy, remove a background color, don't add a border. Simplify through subtraction.

---

### 7. Signature Interaction: The "Social Bloom"
Whenever a user wins or performs a social action (like a "High Five"), use a radial gradient expansion of `secondary_fixed` that blooms from the center of the interaction, momentarily washing the UI in sunny amber warmth before receding back to the minty off-white base.
