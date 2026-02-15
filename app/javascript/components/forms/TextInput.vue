<template>
  <div class="mb-3">
    <label v-if="label" :for="inputId" class="form-label">
      {{ label }}
      <span v-if="required" class="text-danger">*</span>
    </label>
    <input
      :id="inputId"
      v-model="inputValue"
      :type="type"
      :placeholder="placeholder"
      :required="required"
      :disabled="disabled"
      class="form-control"
      @input="handleInput"
    >
    <div v-if="helpText" class="form-text">{{ helpText }}</div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue"

interface Props {
  label?: string
  placeholder?: string
  type?: "text" | "email" | "password" | "number"
  modelValue?: string | number
  required?: boolean
  disabled?: boolean
  helpText?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: "text",
  modelValue: "",
  required: false,
  disabled: false
})

const emit = defineEmits<{
  'update:modelValue': [value: string | number]
}>()

const inputValue = ref(props.modelValue)
const inputId = computed(() => `input-${Math.random().toString(36).substr(2, 9)}`)

function handleInput(event: Event) {
  const target = event.target as HTMLInputElement
  const value = props.type === "number" ? Number(target.value) : target.value
  inputValue.value = value
  emit('update:modelValue', value)
}
</script>
