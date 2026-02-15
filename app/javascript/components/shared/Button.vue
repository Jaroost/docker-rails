<template>
  <button :class="buttonClass" @click="handleClick">
    {{ label }}
  </button>
</template>

<script setup lang="ts">
import { computed } from "vue"

interface Props {
  label?: string
  variant?: "primary" | "secondary" | "success" | "danger"
  size?: "sm" | "md" | "lg"
}

const props = withDefaults(defineProps<Props>(), {
  label: "Click me",
  variant: "primary",
  size: "md"
})

const emit = defineEmits<{
  click: []
}>()

const buttonClass = computed(() => {
  const classes = ["btn", `btn-${props.variant}`]
  if (props.size !== "md") {
    classes.push(`btn-${props.size}`)
  }
  return classes.join(" ")
})

function handleClick() {
  emit("click")
}
</script>
