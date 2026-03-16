# Landing Page Image Shot List and Asset Map

Single source of truth for design/photo. Align all hero, feature, mode, and community imagery with this brief.

---

## 1. Hero

**Section:** Top hero / waitlist CTA  
**Use:** `hero-couple.jpg` (or replace with a stronger version)

**Shot direction**
- Close-up Black couple
- Intimate eye contact or shared smile
- Warm dusk/golden-hour lighting
- Premium editorial feel
- Soft background blur
- Enough negative space for centered wordmark + CTA

**Why:** Matches the app auth emotional tone; strongest conversion image.

---

## 2. Why Choose Afropeep

### Card: Authentic Connections
**Use:** `authentic-connections.jpg`

**Ideal shot:** Two people in a real, candid connection moment; not over-posed; emotionally warm; relationship-first, tasteful.

### Card: Safe & Secure
**Use:** `safe-secure.jpg` (new asset)

**Ideal shot:** Black woman using phone indoors, calm and confident; bright but warm lighting; clean background; trustworthy, modern feel.

**Why:** Trust/safety works better with a solo, composed portrait than a generic abstract visual.

### Card: Global Community
**Use:** `global-community.jpg` (new asset)

**Ideal shot:** Diverse African diaspora friends in an urban outdoor setting; smiling, walking, or gathered casually; modern city context; warm and inclusive.

**Why:** “Global community” should look social and international, not romantic only.

### Card: Modern Experience
**Use:** `modern-experience.jpg` (new asset)

**Ideal shot:** Close-up of user holding phone with modern lifestyle setting; no fake app UI baked into screen; soft modern interior or cafe setting; premium product-ad feel.

**Why:** Reinforces product quality without old-school app marketing look.

### Card: Events & Social
**Use:** `events-meetups.jpg`

**Ideal shot:** Afrocentric social gathering; intimate but lively; stylish, warm lighting; community-centered.

### Card: Premium Features
**Use:** `premium-features.jpg` (new asset)

**Ideal shot:** Elegant solo portrait or upscale lifestyle detail; polished fashion, refined environment; premium but not flashy.

**Why:** “Premium” should feel elevated, not generic feature-grid filler.

---

## 3. Three Ways to Connect

### Dating
**Use:** `dating-mode.jpg` (new asset)

**Ideal shot:** Stylish couple on a date; elegant but natural; warm evening light; not cheesy or overly intimate.

### Friendship
**Use:** `hero-friends.jpg`

**Ideal shot:** 2 to 4 friends laughing or walking together; authentic, energetic, social.

### Networking
**Use:** `hero-networking.jpg`

**Ideal shot:** Two professionals in conversation; modern workspace/cafe; confident and friendly, not stiff.

---

## 4. Community / Stats Section

**Section:** “Join Our Growing Community”  
**Use:** `community-stats.jpg` (optional new asset)

**Ideal shot:** Broad community image with multiple people; event/lounge/outdoor cultural setting; warm ambient light; aspirational but believable.

**Why:** Stats feel stronger when visually tied to a community moment.

---

## 5. Footer / Contact

**Optional:** No image needed if footer is clean. If desired, use a very subtle soft portrait or event crop in low opacity background. Footer should not compete with the hero.

---

# Final Asset Map

| # | Section / Card | Filename |
|---|----------------|----------|
| 1 | Hero | `hero-couple.jpg` |
| 2 | Authentic Connections | `authentic-connections.jpg` |
| 3 | Safe & Secure | `safe-secure.jpg` |
| 4 | Global Community | `global-community.jpg` |
| 5 | Modern Experience | `modern-experience.jpg` |
| 6 | Events & Social | `events-meetups.jpg` |
| 7 | Premium Features | `premium-features.jpg` |
| 8 | Dating mode | `dating-mode.jpg` |
| 9 | Friendship mode | `hero-friends.jpg` |
| 10 | Networking mode | `hero-networking.jpg` |
| 11 | Community/stats | `community-stats.jpg` (optional) |

---

# Visual Consistency Rules

Every image should share:
- Warm color grade
- Natural skin tones
- Premium editorial styling
- Shallow depth of field
- Clean composition
- African diaspora casting
- Authentic, non-stock energy

---

# Implementation (HTML / build)

**Where filenames are used in `web/index.html`:**
- **Hero:** CSS `background-image: url('hero-couple.jpg')` on `.hero-bg`
- **Feature cards:** `<img src="...">` inside `.feature-image` for: `authentic-connections.jpg`, `safe-secure.jpg`, `global-community.jpg`, `modern-experience.jpg`, `events-meetups.jpg`, `premium-features.jpg`
- **Mode cards:** `<img src="...">` inside `.mode-card-image` for: `dating-mode.jpg`, `hero-friends.jpg`, `hero-networking.jpg`
- **Stats (optional):** `community-stats.jpg` if a community image is added above/below the stats grid or as background

**OG / Twitter social preview:** Meta tags point to `https://naijasingles-74a75.web.app/assets/afropeep-hero.jpg`. For the build, ensure the canonical hero asset is available at that path (e.g. copy or symlink `hero-couple.jpg` to `assets/afropeep-hero.jpg` in `web/`, or set OG/Twitter image to `hero-couple.jpg` and use that URL in meta tags). Document here which file is the canonical social preview asset so design and deploy stay in sync.
