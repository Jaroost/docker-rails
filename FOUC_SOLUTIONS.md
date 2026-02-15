# Solutions FOUC (Flash of Unstyled Content)

Ce document décrit les solutions implémentées pour éviter l'artefact visuel pendant le chargement de Bootstrap.

## ✅ Solution 1 : Fade-in au chargement (Implémentée)

### Comment ça fonctionne

1. **CSS Inline** (dans `application.html.erb`) :
   - Le `<body>` est caché par défaut avec `visibility: hidden` et `opacity: 0`
   - Une transition douce de 0.3s est appliquée
   - Un fallback de 2s garantit l'affichage même si JS échoue

2. **JavaScript** (dans `application.ts`) :
   - Au `DOMContentLoaded`, la classe `.loaded` est ajoutée au body
   - Le body devient visible avec une transition douce

### Avantages
- ✅ Très léger (quelques lignes de CSS/JS)
- ✅ Transition élégante
- ✅ Fallback de sécurité
- ✅ Pas de dépendance externe

### Inconvénients
- ⚠️ Écran blanc pendant ~100-300ms

---

## 🎨 Solution 2 : Loader avec Spinner (Alternative)

Pour un effet plus professionnel, vous pouvez afficher un spinner pendant le chargement.

### Implémentation

**1. Modifier `app/views/layouts/application.html.erb`**

Remplacer le `<style>` par :

```html
<style>
  /* Loader overlay */
  #app-loader {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background: #fff;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 9999;
    transition: opacity 0.3s ease-out;
  }

  #app-loader.hidden {
    opacity: 0;
    pointer-events: none;
  }

  /* Spinner */
  .spinner {
    width: 50px;
    height: 50px;
    border: 4px solid #f3f3f3;
    border-top: 4px solid #0d6efd;
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }

  /* Hide loader after 2s fallback */
  #app-loader {
    animation: fallback-hide 0s 2s forwards;
  }

  @keyframes fallback-hide {
    to {
      display: none;
    }
  }
</style>
```

**2. Ajouter le loader dans le `<body>`**

Juste après la balise `<body>` :

```html
<body>
  <!-- Loading spinner -->
  <div id="app-loader">
    <div class="spinner"></div>
  </div>

  <!-- Rest of the body content -->
  <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    ...
```

**3. Modifier `app/javascript/entrypoints/application.ts`**

```typescript
import "bootstrap/dist/css/bootstrap.min.css"
import "bootstrap"

import { createApp } from "vue"
import App from "@/components/App.vue"

// Hide loader once everything is loaded
document.addEventListener("DOMContentLoaded", () => {
  const loader = document.getElementById("app-loader")
  if (loader) {
    // Add a small delay to ensure CSS is fully applied
    setTimeout(() => {
      loader.classList.add("hidden")
      // Remove from DOM after transition
      setTimeout(() => loader.remove(), 300)
    }, 100)
  }
})

const el = document.getElementById("vue-app")
if (el) {
  createApp(App).mount(el)
}
```

### Avantages
- ✅ Look professionnel
- ✅ Indication claire du chargement
- ✅ Pas de contenu non stylé visible
- ✅ Personnalisable (logo, couleurs, etc.)

### Inconvénients
- ⚠️ Plus de code
- ⚠️ Peut ralentir la perception de chargement

---

## 🚀 Solution 3 : Préchargement CSS (Avancée)

Pour les performances ultimes, précharger Bootstrap via Propshaft au lieu de Vite.

### Implémentation

**1. Copier Bootstrap CSS dans `app/assets/stylesheets/`**

```bash
# Dans le container
docker compose exec web bash -c "
  mkdir -p app/assets/stylesheets/vendor
  cp node_modules/bootstrap/dist/css/bootstrap.min.css app/assets/stylesheets/vendor/
"
```

**2. Modifier `application.html.erb`**

```html
<head>
  <!-- ... -->

  <!-- Preload Bootstrap CSS via Propshaft (instant load) -->
  <%= stylesheet_link_tag "vendor/bootstrap.min", "data-turbo-track": "reload" %>

  <%= vite_client_tag %>
  <%= vite_typescript_tag "application" %>
</head>
```

**3. Retirer Bootstrap CSS de `application.ts`**

```typescript
// Remove this line:
// import "bootstrap/dist/css/bootstrap.min.css"

import "bootstrap"
import { createApp } from "vue"
import App from "@/components/App.vue"

// ... rest of the code
```

### Avantages
- ✅ Chargement instantané (pas de FOUC du tout)
- ✅ CSS disponible avant JavaScript
- ✅ Meilleur score Lighthouse

### Inconvénients
- ⚠️ Bootstrap n'est plus géré par Vite
- ⚠️ Nécessite de copier manuellement à chaque update
- ⚠️ Deux systèmes d'assets à gérer

---

## 📊 Comparaison

| Solution | Complexité | Performance | UX | Recommandée pour |
|----------|------------|-------------|-----|------------------|
| **Fade-in** | Faible | Bonne | Simple | La plupart des apps |
| **Spinner** | Moyenne | Bonne | Professionnelle | Apps orientées utilisateur |
| **Preload CSS** | Élevée | Excellente | Parfaite | Apps critiques en perf |

---

## 🎯 Recommandation

**Solution 1 (Fade-in)** est déjà implémentée et suffisante pour la plupart des cas.

Si vous voulez un look plus professionnel, passez à la **Solution 2 (Spinner)**.

La **Solution 3** n'est nécessaire que si vous visez un score Lighthouse parfait ou avez des contraintes de performance strictes.

---

## 🧪 Test

Testez le résultat en :
1. Ouvrant la page : `https://rails.localtest.me`
2. Rafraîchissant avec **Cmd/Ctrl + Shift + R** (hard refresh)
3. Ouvrant DevTools → Network → Slow 3G pour simuler une connexion lente

Vous ne devriez plus voir de contenu non stylé ! ✨
