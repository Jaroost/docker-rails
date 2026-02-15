# Vue Dynamic Mounting System

## 🎯 Vue d'ensemble

Ce système permet de monter dynamiquement plusieurs applications Vue sur une page Rails en utilisant des **data-attributes**. Plus besoin de créer manuellement des apps Vue pour chaque composant !

**✨ Fonctionnalité clé :** **Auto-registration** de tous les composants Vue ! Créez un fichier `.vue` dans `components/`, il est immédiatement disponible avec `data-behavior="vue-{nom}"`. Zéro configuration nécessaire.

## 🚀 Utilisation Rapide

### 1. Dans votre vue Rails (.html.erb)

```erb
<!-- Composant simple -->
<div data-behavior="vue-counter"></div>

<!-- Composant avec props -->
<div
  data-behavior="vue-greeting"
  data-name="Jean"
  data-message="Bonjour depuis Rails !"
></div>

<!-- Composant avec props complexes (JSON) -->
<div
  data-behavior="vue-todo-list"
  data-title="Ma liste"
  data-initial-todos='["Tâche 1", "Tâche 2", "Tâche 3"]'
></div>
```

### 2. Le système monte automatiquement

- ✅ Tous les composants existants au chargement de la page
- ✅ Les nouveaux composants ajoutés dynamiquement (via JS, AJAX, Turbo, etc.)
- ✅ Aucune configuration supplémentaire requise !

## 📋 Convention de Nommage

| data-behavior       | Composant Vue         | Fichier                              |
|---------------------|-----------------------|--------------------------------------|
| `vue-counter`       | Counter.vue           | `app/javascript/components/Counter.vue` |
| `vue-greeting`      | Greeting.vue          | `app/javascript/components/Greeting.vue` |
| `vue-todo-list`     | TodoList.vue          | `app/javascript/components/TodoList.vue` |
| `vue-my-component`  | MyComponent.vue       | `app/javascript/components/MyComponent.vue` |

**Règle :** `data-behavior="vue-{component-name}"` → Composant enregistré avec le nom `{component-name}`

## 🔧 Ajouter un Nouveau Composant

### ⚡ Auto-registration activée !

**Le système enregistre automatiquement tous les composants** du dossier `app/javascript/components/` !

### Étape 1 : Créer le composant Vue

**Fichier :** `app/javascript/components/MyWidget.vue`

```vue
<template>
  <div class="my-widget">
    <h3>{{ title }}</h3>
    <p>{{ message }}</p>
  </div>
</template>

<script setup lang="ts">
interface Props {
  title?: string
  message?: string
}

const props = withDefaults(defineProps<Props>(), {
  title: "Mon Widget",
  message: "Message par défaut"
})
</script>
```

### Étape 2 : C'est tout ! 🎉

Le composant est **automatiquement enregistré** grâce à `import.meta.glob` de Vite.

Le nom du fichier est converti en kebab-case :
- `MyWidget.vue` → `my-widget` → utilisez `data-behavior="vue-my-widget"`
- `UserCard.vue` → `user-card` → utilisez `data-behavior="vue-user-card"`
- `TodoList.vue` → `todo-list` → utilisez `data-behavior="vue-todo-list"`

### Étape 3 : Utiliser dans votre vue Rails

```erb
<div
  data-behavior="vue-my-widget"
  data-title="Titre personnalisé"
  data-message="Message personnalisé"
></div>
```

### 🎯 Avantages

- ✅ **Aucune configuration** : Créez un `.vue`, c'est prêt !
- ✅ **Tree-shaking** : Vite optimise le bundle automatiquement
- ✅ **Convention over configuration** : Moins de code à maintenir
- ✅ **Scalable** : Ajoutez 100 composants sans toucher à `application.ts`

**Documentation détaillée :** Voir `docs/VUE_AUTO_REGISTRATION.md`

## 📦 Passer des Props

### Types de données supportés

Le système convertit automatiquement les valeurs des data-attributes :

```erb
<!-- String (par défaut) -->
<div data-behavior="vue-greeting" data-name="Jean"></div>
<!-- Props: { name: "Jean" } -->

<!-- Number -->
<div data-behavior="vue-counter" data-initial-count="42"></div>
<!-- Props: { initialCount: 42 } -->

<!-- Boolean -->
<div data-behavior="vue-widget" data-active="true"></div>
<!-- Props: { active: true } -->

<!-- Array (JSON) -->
<div data-behavior="vue-list" data-items='["a", "b", "c"]'></div>
<!-- Props: { items: ["a", "b", "c"] } -->

<!-- Object (JSON) -->
<div data-behavior="vue-config" data-settings='{"theme": "dark", "size": 10}'></div>
<!-- Props: { settings: { theme: "dark", size: 10 } } -->
```

### Conversion automatique des noms

Les noms des data-attributes sont convertis en **camelCase** :

```erb
<div
  data-behavior="vue-my-component"
  data-initial-count="10"
  data-user-name="Jean"
  data-is-active="true"
></div>
```

Devient :

```javascript
{
  initialCount: 10,
  userName: "Jean",
  isActive: true
}
```

## 🔄 Montage Dynamique

Le système utilise un **MutationObserver** pour détecter automatiquement les nouveaux éléments :

```javascript
// Ajouter un composant dynamiquement
const container = document.getElementById('my-container')
const newElement = document.createElement('div')
newElement.setAttribute('data-behavior', 'vue-counter')
newElement.setAttribute('data-initial-count', '100')
container.appendChild(newElement)

// ✅ Le composant sera automatiquement monté !
```

### Cas d'usage

- **AJAX/Fetch :** Charger du HTML contenant des composants Vue
- **Turbo Frames :** Les composants dans les frames seront montés automatiquement
- **JavaScript dynamique :** Créer des éléments avec `createElement`
- **Templates :** Cloner des templates et les insérer dans le DOM

## 🛠️ API du Système

### `registerComponent(name, component)`

Enregistre un composant Vue pour être utilisé avec data-behavior.

```typescript
import { registerComponent } from "@/utils/vue-mounter"
import MyComponent from "@/components/MyComponent.vue"

registerComponent("my-component", MyComponent)
```

### `initVueMounter(root?)`

Initialise le système de montage : monte tous les composants existants et observe les changements.

```typescript
import { initVueMounter } from "@/utils/vue-mounter"

// Monte sur document.body (par défaut)
initVueMounter()

// Ou sur un élément spécifique
const container = document.getElementById('vue-container')
initVueMounter(container)
```

### `mountAllVueApps(root?)`

Monte manuellement tous les composants dans un conteneur.

```typescript
import { mountAllVueApps } from "@/utils/vue-mounter"

// Utile après avoir chargé du contenu dynamique
fetch('/api/content')
  .then(response => response.text())
  .then(html => {
    container.innerHTML = html
    mountAllVueApps(container)
  })
```

### `observeVueApps(root?)`

Active uniquement l'observation des changements (sans monter les composants existants).

```typescript
import { observeVueApps } from "@/utils/vue-mounter"

observeVueApps(document.body)
```

## 🎨 Exemples d'Utilisation

### Composant dans une boucle Rails

```erb
<% @users.each do |user| %>
  <div
    data-behavior="vue-user-card"
    data-user-id="<%= user.id %>"
    data-name="<%= user.name %>"
    data-email="<%= user.email %>"
  ></div>
<% end %>
```

### Composant dans un partial

**app/views/shared/_vue_widget.html.erb :**

```erb
<div
  data-behavior="vue-<%= component %>"
  <% props.each do |key, value| %>
    data-<%= key.to_s.dasherize %>="<%= value.is_a?(String) ? value : value.to_json %>"
  <% end %>
></div>
```

**Utilisation :**

```erb
<%= render 'shared/vue_widget',
    component: 'counter',
    props: { title: 'Mon Compteur', initial_count: 5 } %>
```

### Composant avec données Rails

```erb
<div
  data-behavior="vue-chart"
  data-chart-data='<%= @chart_data.to_json %>'
  data-options='<%= @chart_options.to_json %>'
></div>
```

## 🐛 Debugging

### Voir les logs du système

Ouvrez la console du navigateur pour voir :

```
[VueMounter] Mounted "counter" on <div data-behavior="vue-counter"> with props: { initialCount: 10 }
[VueMounter] Mounted 3 Vue app(s)
[VueMounter] MutationObserver started - watching for new Vue apps
```

### Vérifier qu'un composant est monté

```javascript
const element = document.querySelector('[data-behavior="vue-counter"]')
console.log(element.dataset.vueMounted) // "true" si monté
```

### Voir les composants auto-enregistrés

Au chargement de la page, la console affiche tous les composants enregistrés :

```
[VueMounter] Auto-registered "app" from App.vue
[VueMounter] Auto-registered "counter" from Counter.vue
[VueMounter] Auto-registered "greeting" from Greeting.vue
[VueMounter] Auto-registered "todo-list" from TodoList.vue
[VueMounter] Auto-registered "user-card" from UserCard.vue
```

### Warnings courants

**"No component registered for 'my-component'"**
- ✅ Vérifiez que le fichier `.vue` existe bien dans `app/javascript/components/`
- ✅ Vérifiez l'orthographe du nom (PascalCase dans le fichier, kebab-case dans HTML)
- ✅ Rechargez la page après avoir créé le fichier
- ⚠️ Les composants sont auto-enregistrés, pas besoin de modifier `application.ts` !

**Le composant ne se monte pas**
- Vérifiez que `data-behavior` commence bien par `"vue-"`
- Vérifiez que l'élément n'est pas déjà monté (`data-vue-mounted="true"`)
- Vérifiez la console pour des erreurs JavaScript
- Vérifiez que le nom du fichier correspond (ex: `UserCard.vue` → `vue-user-card`)

## 🏗️ Architecture

```
app/javascript/
├── entrypoints/
│   └── application.ts         # Auto-registration avec import.meta.glob
├── components/
│   ├── App.vue                # Composants auto-enregistrés
│   ├── Counter.vue            # → vue-counter
│   ├── Greeting.vue           # → vue-greeting
│   ├── TodoList.vue           # → vue-todo-list
│   ├── UserCard.vue           # → vue-user-card
│   └── shared/                # Sous-dossiers supportés !
│       ├── Button.vue         # → vue-button
│       └── Modal.vue          # → vue-modal
└── utils/
    └── vue-mounter.ts         # Système de montage dynamique
```

**Note :** Avec `@/components/**/*.vue`, les sous-dossiers sont aussi scannés !

## 🔄 Évolution du système

### Génération 1 : Montage manuel (ancien)

```typescript
// application.ts
import { createApp } from "vue"
import App from "@/components/App.vue"

const el = document.getElementById("vue-app")
if (el) {
  createApp(App).mount(el)
}
```

```erb
<div id="vue-app"></div>
```

❌ **Limitations :** Un seul composant par page, IDs uniques nécessaires

### Génération 2 : Montage dynamique avec registration manuelle

```typescript
// application.ts
import { registerComponent, initVueMounter } from "@/utils/vue-mounter"
import Counter from "@/components/Counter.vue"
import Greeting from "@/components/Greeting.vue"

registerComponent("counter", Counter)
registerComponent("greeting", Greeting)

document.addEventListener("DOMContentLoaded", () => {
  initVueMounter()
})
```

```erb
<div data-behavior="vue-counter"></div>
<div data-behavior="vue-greeting"></div>
```

⚠️ **Mieux, mais :** Toujours besoin de modifier `application.ts` à chaque composant

### Génération 3 : Auto-registration (actuel) ⭐

```typescript
// application.ts
import { registerComponent, initVueMounter } from "@/utils/vue-mounter"

// Auto-register tous les composants
const componentModules = import.meta.glob('@/components/**/*.vue', { eager: true })
for (const path in componentModules) {
  const kebabName = // ... conversion automatique
  registerComponent(kebabName, componentModules[path].default)
}

document.addEventListener("DOMContentLoaded", () => {
  initVueMounter()
})
```

```erb
<!-- Créez UserCard.vue, utilisez-le immédiatement -->
<div data-behavior="vue-user-card"></div>
```

✅ **Parfait :** Convention over configuration, zéro maintenance !

## 🎯 Avantages du système complet

✅ **Auto-registration :** Créez un `.vue`, c'est immédiatement disponible
✅ **Simplicité :** Un seul système pour tous vos composants Vue
✅ **Flexibilité :** Montez plusieurs composants sur une même page
✅ **Dynamique :** Fonctionne avec du contenu chargé via AJAX/Turbo
✅ **Type-safe :** Support complet de TypeScript
✅ **Performant :** Tree-shaking Vite + pas de double-montage
✅ **Scalable :** 5 ou 500 composants → même code
✅ **Rails-friendly :** S'intègre naturellement avec les conventions Rails

## 📚 Ressources

- **Fichier principal :** `app/javascript/utils/vue-mounter.ts`
- **Page de démo :** `/test` (voir `app/views/home/test.html.erb`)
- **Vue.js docs :** https://vuejs.org/
- **TypeScript docs :** https://www.typescriptlang.org/
