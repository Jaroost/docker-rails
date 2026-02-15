# Vue Auto-Registration System

## 🚀 Vue d'ensemble

Le système utilise maintenant **l'auto-registration** : tous les composants Vue dans `app/javascript/components/*.vue` sont automatiquement enregistrés et disponibles via `data-behavior`.

## ✨ Comment ça marche

### 1. Créez un composant Vue

**Fichier :** `app/javascript/components/UserCard.vue`

```vue
<template>
  <div class="card">
    <div class="card-body">
      <h5>{{ name }}</h5>
      <p>{{ email }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  name: string
  email: string
}

defineProps<Props>()
</script>
```

### 2. C'est tout ! Utilisez-le immédiatement

```erb
<div
  data-behavior="vue-user-card"
  data-name="Jean Dupont"
  data-email="jean@example.com"
></div>
```

**Aucune étape d'enregistrement nécessaire !** ✅

## 📋 Convention de nommage automatique

Le système convertit automatiquement le nom du fichier en kebab-case :

| Nom du fichier          | Nom enregistré      | data-behavior             |
|-------------------------|---------------------|---------------------------|
| `App.vue`               | `app`               | `vue-app`                 |
| `Counter.vue`           | `counter`           | `vue-counter`             |
| `TodoList.vue`          | `todo-list`         | `vue-todo-list`           |
| `UserCard.vue`          | `user-card`         | `vue-user-card`           |
| `ProductGallery.vue`    | `product-gallery`   | `vue-product-gallery`     |
| `ShoppingCart.vue`      | `shopping-cart`     | `vue-shopping-cart`       |

**Règle :** `PascalCase` → `kebab-case` automatiquement

## 🔧 Implémentation technique

**Fichier :** `app/javascript/entrypoints/application.ts`

```typescript
import { registerComponent, initVueMounter } from "@/utils/vue-mounter"

// Auto-register all components using Vite's import.meta.glob
const componentModules = import.meta.glob<{ default: any }>(
  '@/components/*.vue',
  { eager: true }
)

for (const path in componentModules) {
  const componentName = path.split('/').pop()!.replace('.vue', '')
  const kebabName = componentName
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .toLowerCase()

  registerComponent(kebabName, componentModules[path].default)
}
```

## 🎯 Avantages

### ✅ Simplicité
- Créez un fichier `.vue`, il est immédiatement disponible
- Pas besoin de modifier `application.ts` à chaque fois
- Convention over configuration

### ✅ Performance
- **Tree-shaking** : Vite optimise le bundle automatiquement
- Seuls les composants utilisés sont inclus dans le bundle final
- `eager: true` signifie que Vite peut analyser statiquement les dépendances

### ✅ Scalabilité
- Ajoutez 10, 50, 100 composants sans modifier la configuration
- Le système s'adapte automatiquement

### ✅ Maintenabilité
- Moins de code boilerplate
- Une seule source de vérité : le nom du fichier
- Renommage facile : renommez le fichier, c'est tout

## 🔄 Comparaison avec l'ancienne méthode

### Avant (Registration manuelle)

```typescript
// application.ts
import Counter from "@/components/Counter.vue"
import Greeting from "@/components/Greeting.vue"
import TodoList from "@/components/TodoList.vue"
import UserCard from "@/components/UserCard.vue"
import ProductGallery from "@/components/ProductGallery.vue"
// ... 50 autres imports

registerComponent("counter", Counter)
registerComponent("greeting", Greeting)
registerComponent("todo-list", TodoList)
registerComponent("user-card", UserCard)
registerComponent("product-gallery", ProductGallery)
// ... 50 autres enregistrements
```

❌ **Problèmes :**
- Verbeux et répétitif
- Facile d'oublier d'enregistrer un composant
- Maintenance fastidieuse avec beaucoup de composants

### Maintenant (Auto-registration)

```typescript
// application.ts
const componentModules = import.meta.glob('@/components/*.vue', { eager: true })
// ... 5 lignes de code pour tout gérer
```

✅ **Avantages :**
- 95% moins de code
- Impossible d'oublier un composant
- Scalable à l'infini

## 🛠️ Organisation des composants

### Structure recommandée

```
app/javascript/components/
├── App.vue                   # Composant principal
├── Counter.vue               # Widgets simples
├── Greeting.vue
├── TodoList.vue
├── UserCard.vue             # Composants métier
├── ProductCard.vue
├── ShoppingCart.vue
└── shared/                  # Sous-dossiers possibles (non auto-registered)
    ├── Button.vue
    └── Modal.vue
```

**Note :** Seuls les fichiers à la racine de `components/` sont auto-enregistrés. Les sous-dossiers comme `shared/` ne le sont pas (par conception, pour éviter d'exposer des composants internes).

## 📦 Lazy loading (optionnel)

Si vous voulez lazy-load des composants (utile pour de très gros composants), utilisez `eager: false` :

```typescript
const componentModules = import.meta.glob(
  '@/components/*.vue',
  { eager: false }  // Charge à la demande
)

for (const path in componentModules) {
  const componentName = // ... conversion

  // Wrapper pour lazy loading
  const lazyComponent = defineAsyncComponent(() => componentModules[path]())
  registerComponent(kebabName, lazyComponent)
}
```

⚠️ **Trade-off :**
- ✅ Bundle initial plus petit
- ❌ Petit délai au premier montage du composant

## 🐛 Debugging

### Voir les composants enregistrés

Ouvrez la console du navigateur au chargement de la page :

```
[VueMounter] Auto-registered "app" from App.vue
[VueMounter] Auto-registered "counter" from Counter.vue
[VueMounter] Auto-registered "greeting" from Greeting.vue
[VueMounter] Auto-registered "todo-list" from TodoList.vue
...
```

### Vérifier qu'un composant est bien enregistré

```javascript
// Dans la console du navigateur
console.log(window.vueComponents) // Si vous exposez le registre
```

### Problèmes courants

**Le composant ne se monte pas**
1. Vérifiez que le fichier est bien dans `app/javascript/components/*.vue`
2. Vérifiez le nom du fichier (PascalCase recommandé)
3. Rechargez la page après avoir créé le fichier
4. Vérifiez la console pour les erreurs

**Mauvais nom de composant**
- `UserCard.vue` → `vue-user-card` (pas `vue-usercard`)
- `TodoList.vue` → `vue-todo-list` (pas `vue-todolist`)

## 🎓 Exemples d'utilisation

### Exemple 1 : Créer un compteur personnalisé

**1. Créez le fichier :**

```bash
# app/javascript/components/LikeCounter.vue
```

```vue
<template>
  <button class="btn btn-primary" @click="count++">
    ❤️ {{ count }} likes
  </button>
</template>

<script setup lang="ts">
import { ref } from "vue"

interface Props {
  initialCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  initialCount: 0
})

const count = ref(props.initialCount)
</script>
```

**2. Utilisez-le immédiatement :**

```erb
<div data-behavior="vue-like-counter" data-initial-count="42"></div>
```

### Exemple 2 : Widget de notification

**1. Créez `NotificationBell.vue` :**

```vue
<template>
  <div class="position-relative">
    <button class="btn btn-link">
      🔔
      <span v-if="unreadCount > 0" class="badge bg-danger">
        {{ unreadCount }}
      </span>
    </button>
  </div>
</template>

<script setup lang="ts">
interface Props {
  unreadCount?: number
}

withDefaults(defineProps<Props>(), {
  unreadCount: 0
})
</script>
```

**2. Utilisez dans la navbar :**

```erb
<nav class="navbar">
  <div data-behavior="vue-notification-bell" data-unread-count="<%= current_user.unread_notifications_count %>"></div>
</nav>
```

## 📚 Ressources

- **Vite import.meta.glob :** https://vitejs.dev/guide/features.html#glob-import
- **Vue Dynamic Components :** https://vuejs.org/guide/essentials/component-basics.html
- **Doc complète :** `VUE_DYNAMIC_MOUNTING.md`

---

**TL;DR :** Créez un fichier `.vue`, utilisez-le avec `data-behavior="vue-{kebab-case-name}"`. C'est tout ! 🎉
