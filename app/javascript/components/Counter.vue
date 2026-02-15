<template>
  <div class="card">
    <div class="card-body">
      <h5 class="card-title">{{ title }}</h5>
      <p class="card-text">Compteur : {{ count }}</p>
      <button class="btn btn-primary" @click="count++">Incrémenter</button>
      <button class="btn btn-outline-secondary ms-2" @click="count = 0">Reset</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue"

interface Props {
  title?: string
  initialCount?: number
}

const props = withDefaults(defineProps<Props>(), {
  title: "Compteur Vue.js",
  initialCount: 0
})

const count = ref<number>(props.initialCount)
</script>
