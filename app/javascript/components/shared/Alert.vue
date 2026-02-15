<template>
  <div :class="alertClass" role="alert">
    <strong v-if="title">{{ title }}</strong>
    <span>{{ message }}</span>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue"

interface Props {
  title?: string
  message?: string
  type?: "info" | "success" | "warning" | "danger"
}

const props = withDefaults(defineProps<Props>(), {
  message: "This is an alert message",
  type: "info"
})

const alertClass = computed(() => {
  return `alert alert-${props.type}`
})
</script>
