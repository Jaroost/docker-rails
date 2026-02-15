<template>
  <div class="alert alert-info">
    <h4 class="alert-heading">{{ greeting }}</h4>
    <p>{{ message }}</p>
    <hr>
    <p class="mb-0">
      <small>Ce composant a été monté dynamiquement via data-behavior="vue-greeting"</small>
    </p>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue"

interface Props {
  name?: string
  message?: string
}

const props = withDefaults(defineProps<Props>(), {
  name: "Visiteur",
  message: "Bienvenue sur cette application Vue montée dynamiquement !"
})

const greeting = computed(() => `Bonjour, ${props.name} !`)
</script>
