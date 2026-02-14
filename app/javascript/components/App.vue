<template>
  <div class="card">
    <div class="card-body">
      <h5 class="card-title">{{ title }}</h5>
      <p class="card-text">Compteur : {{ count }}</p>
      <button class="btn btn-primary" @click="count++">Incrémenter</button>
      <button class="btn btn-outline-secondary ms-2" @click="count = 0">Reset</button>
      <button class="btn btn-outline-secondary ms-2" @click="count = 0">Reset2</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue"

const title = ref<string>("Vue.js + TypeScript + Vite")
const count = ref<number>(0)
</script>
