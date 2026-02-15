<template>
  <div class="card">
    <div class="card-header">
      <h5 class="mb-0">{{ title }}</h5>
    </div>
    <div class="card-body">
      <div class="input-group mb-3">
        <input
          v-model="newTodo"
          type="text"
          class="form-control"
          placeholder="Nouvelle tâche..."
          @keyup.enter="addTodo"
        >
        <button class="btn btn-primary" @click="addTodo">
          Ajouter
        </button>
      </div>

      <ul class="list-group">
        <li
          v-for="(todo, index) in todos"
          :key="index"
          class="list-group-item d-flex justify-content-between align-items-center"
          :class="{ 'text-decoration-line-through text-muted': todo.completed }"
        >
          <div class="form-check">
            <input
              v-model="todo.completed"
              class="form-check-input"
              type="checkbox"
              :id="`todo-${index}`"
            >
            <label class="form-check-label" :for="`todo-${index}`">
              {{ todo.text }}
            </label>
          </div>
          <button
            class="btn btn-sm btn-outline-danger"
            @click="removeTodo(index)"
          >
            Supprimer
          </button>
        </li>
      </ul>

      <div v-if="todos.length === 0" class="text-center text-muted py-3">
        Aucune tâche pour le moment
      </div>

      <div v-else class="mt-3">
        <small class="text-muted">
          {{ completedCount }} / {{ todos.length }} tâche(s) complétée(s)
        </small>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from "vue"

interface Todo {
  text: string
  completed: boolean
}

interface Props {
  title?: string
  initialTodos?: string[]
}

const props = withDefaults(defineProps<Props>(), {
  title: "Ma liste de tâches",
  initialTodos: () => []
})

const newTodo = ref<string>("")
const todos = ref<Todo[]>(
  props.initialTodos.map(text => ({ text, completed: false }))
)

const completedCount = computed(() => todos.value.filter(t => t.completed).length)

function addTodo() {
  if (newTodo.value.trim()) {
    todos.value.push({
      text: newTodo.value.trim(),
      completed: false
    })
    newTodo.value = ""
  }
}

function removeTodo(index: number) {
  todos.value.splice(index, 1)
}
</script>
