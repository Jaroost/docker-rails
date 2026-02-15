# Vue Component Naming & Organization

## 🗂️ Organisation des composants avec sous-dossiers

Le système supporte **les sous-dossiers** pour organiser vos composants Vue. Le chemin du dossier est automatiquement inclus dans le nom du composant pour **éviter les conflits**.

## 📋 Convention de nommage avec sous-dossiers

### Règle de transformation

```
Path complet → Segments en kebab-case → Jointure avec "-"
```

### Exemples

| Chemin du fichier                              | Nom enregistré                | data-behavior                           |
|------------------------------------------------|-------------------------------|-----------------------------------------|
| `components/App.vue`                           | `app`                         | `vue-app`                               |
| `components/Counter.vue`                       | `counter`                     | `vue-counter`                           |
| `components/TodoList.vue`                      | `todo-list`                   | `vue-todo-list`                         |
| `components/shared/Button.vue`                 | `shared-button`               | `vue-shared-button`                     |
| `components/shared/Alert.vue`                  | `shared-alert`                | `vue-shared-alert`                      |
| `components/forms/TextInput.vue`               | `forms-text-input`            | `vue-forms-text-input`                  |
| `components/forms/inputs/TextInput.vue`        | `forms-inputs-text-input`     | `vue-forms-inputs-text-input`           |
| `components/admin/users/UserCard.vue`          | `admin-users-user-card`       | `vue-admin-users-user-card`             |
| `components/dashboard/widgets/SalesChart.vue`  | `dashboard-widgets-sales-chart` | `vue-dashboard-widgets-sales-chart`   |

## ✅ Gestion des conflits de noms

### Problème sans sous-dossiers

```
components/
├── Button.vue           # → "button"
└── shared/
    └── Button.vue       # → "button" ❌ CONFLIT !
```

### Solution avec le système actuel

```
components/
├── Button.vue           # → "button" ✅
└── shared/
    └── Button.vue       # → "shared-button" ✅ Pas de conflit !
```

Le chemin du dossier est **automatiquement inclus** dans le nom.

## 🎯 Cas d'usage

### 1. Composants partagés (réutilisables)

```
components/shared/
├── Button.vue          # Bouton réutilisable
├── Alert.vue           # Alertes
├── Modal.vue           # Modales
└── Card.vue            # Cards Bootstrap
```

**Utilisation :**
```erb
<div data-behavior="vue-shared-button" data-label="Cliquez ici" data-variant="primary"></div>
<div data-behavior="vue-shared-alert" data-message="Succès !" data-type="success"></div>
```

### 2. Composants de formulaires

```
components/forms/
├── TextInput.vue       # Input texte
├── SelectInput.vue     # Select dropdown
├── CheckboxGroup.vue   # Groupe de checkboxes
└── inputs/
    ├── DatePicker.vue  # Date picker
    └── FileUpload.vue  # Upload de fichiers
```

**Utilisation :**
```erb
<div data-behavior="vue-forms-text-input" data-label="Email" data-type="email"></div>
<div data-behavior="vue-forms-inputs-date-picker" data-label="Date de naissance"></div>
```

### 3. Composants métier par domaine

```
components/
├── users/
│   ├── UserCard.vue
│   ├── UserList.vue
│   └── UserProfile.vue
├── products/
│   ├── ProductCard.vue
│   ├── ProductGallery.vue
│   └── ProductDetails.vue
└── orders/
    ├── OrderSummary.vue
    └── OrderHistory.vue
```

**Utilisation :**
```erb
<div data-behavior="vue-users-user-card" data-name="Jean" data-email="jean@example.com"></div>
<div data-behavior="vue-products-product-card" data-title="Produit" data-price="29.99"></div>
```

### 4. Composants spécifiques par page/section

```
components/
├── dashboard/
│   ├── DashboardStats.vue
│   └── widgets/
│       ├── SalesChart.vue
│       └── ActivityFeed.vue
├── admin/
│   ├── AdminPanel.vue
│   └── users/
│       ├── UserManagement.vue
│       └── UserPermissions.vue
└── public/
    ├── HomePage.vue
    └── ContactForm.vue
```

## 📖 Structure recommandée

```
app/javascript/components/
├── App.vue                      # Composant racine (si besoin)
│
├── shared/                      # Composants UI réutilisables
│   ├── Button.vue
│   ├── Alert.vue
│   ├── Modal.vue
│   ├── Card.vue
│   └── Badge.vue
│
├── forms/                       # Composants de formulaires
│   ├── TextInput.vue
│   ├── SelectInput.vue
│   ├── CheckboxGroup.vue
│   └── inputs/                  # Inputs complexes
│       ├── DatePicker.vue
│       ├── ColorPicker.vue
│       └── FileUpload.vue
│
├── layout/                      # Composants de mise en page
│   ├── Navigation.vue
│   ├── Sidebar.vue
│   └── Footer.vue
│
├── {domain}/                    # Composants métier (par domaine)
│   ├── users/
│   │   ├── UserCard.vue
│   │   ├── UserList.vue
│   │   └── UserProfile.vue
│   ├── products/
│   │   ├── ProductCard.vue
│   │   └── ProductGallery.vue
│   └── orders/
│       ├── OrderSummary.vue
│       └── OrderHistory.vue
│
└── pages/                       # Composants page complète
    ├── dashboard/
    │   └── DashboardView.vue
    └── admin/
        └── AdminView.vue
```

## 🔍 Debugging : Voir les composants enregistrés

Ouvrez la console du navigateur au chargement de la page :

```
[VueMounter] Auto-registered "app" from App.vue
[VueMounter] Auto-registered "counter" from Counter.vue
[VueMounter] Auto-registered "shared-button" from shared/Button.vue
[VueMounter] Auto-registered "shared-alert" from shared/Alert.vue
[VueMounter] Auto-registered "forms-text-input" from forms/TextInput.vue
[VueMounter] Auto-registered "forms-inputs-date-picker" from forms/inputs/DatePicker.vue
```

## 💡 Conseils

### ✅ Bonnes pratiques

1. **Organisez par fonctionnalité**, pas par type
   - ✅ `components/users/UserCard.vue`
   - ❌ `components/cards/UserCard.vue`

2. **Utilisez des noms descriptifs**
   - ✅ `ProductGalleryCarousel.vue`
   - ❌ `Gallery.vue`

3. **Groupez les composants liés**
   ```
   forms/
   ├── TextInput.vue
   ├── SelectInput.vue
   └── inputs/          # Inputs complexes ensemble
       ├── DatePicker.vue
       └── ColorPicker.vue
   ```

4. **Limitez la profondeur à 3-4 niveaux max**
   - ✅ `admin/users/UserCard.vue` (2 niveaux)
   - ⚠️ `admin/dashboard/users/list/UserCard.vue` (4 niveaux - trop profond)

### ⚠️ À éviter

1. **Noms trop génériques au même niveau**
   ```
   ❌ components/Button.vue
   ❌ components/shared/Button.vue
   ```
   Préférez :
   ```
   ✅ components/shared/Button.vue (seul)
   ```

2. **Duplication inutile dans le nom**
   ```
   ❌ components/users/UsersUserCard.vue → "users-users-user-card"
   ```
   Préférez :
   ```
   ✅ components/users/UserCard.vue → "users-user-card"
   ```

## 🎨 Exemples complets

### Exemple 1 : Composants partagés

**Créez :** `components/shared/Button.vue`

```erb
<!-- Usage simple -->
<div data-behavior="vue-shared-button" data-label="Enregistrer"></div>

<!-- Avec options -->
<div
  data-behavior="vue-shared-button"
  data-label="Supprimer"
  data-variant="danger"
  data-size="sm"
></div>
```

### Exemple 2 : Formulaire avec inputs

**Créez :** `components/forms/TextInput.vue`

```erb
<form>
  <div
    data-behavior="vue-forms-text-input"
    data-label="Nom complet"
    data-placeholder="Jean Dupont"
    data-required="true"
  ></div>

  <div
    data-behavior="vue-forms-text-input"
    data-label="Email"
    data-type="email"
    data-help-text="Nous ne partagerons jamais votre email"
  ></div>
</form>
```

### Exemple 3 : Cards utilisateur

**Créez :** `components/users/UserCard.vue`

```erb
<div class="row">
  <% @users.each do |user| %>
    <div class="col-md-4">
      <div
        data-behavior="vue-users-user-card"
        data-name="<%= user.name %>"
        data-email="<%= user.email %>"
        data-avatar="<%= user.avatar_url %>"
      ></div>
    </div>
  <% end %>
</div>
```

## 🚀 Migration

Si vous avez déjà des composants à la racine et voulez les organiser :

### Avant
```
components/
├── Button.vue
└── Alert.vue
```

**Usage :**
```erb
<div data-behavior="vue-button"></div>
<div data-behavior="vue-alert"></div>
```

### Après (organisé)
```
components/shared/
├── Button.vue
└── Alert.vue
```

**Nouveau usage :**
```erb
<div data-behavior="vue-shared-button"></div>
<div data-behavior="vue-shared-alert"></div>
```

⚠️ **Important :** Mettez à jour vos vues Rails après avoir déplacé les composants !

## 📚 Ressources

- Guide complet : `VUE_DYNAMIC_MOUNTING.md`
- Auto-registration : `VUE_AUTO_REGISTRATION.md`
- Vite glob patterns : https://vitejs.dev/guide/features.html#glob-import
