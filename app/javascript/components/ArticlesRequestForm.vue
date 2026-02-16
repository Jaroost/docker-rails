<template>
  <div>
    <h4 class="mb-3">Articles</h4>

    <!-- Iterate over all articles to maintain correct indices -->
    <template v-for="(article, index) in articles" :key="article.uniqueId">
      <!-- Hidden fields for destroyed articles -->
      <div v-if="article._destroy" style="display: none;">
        <input type="hidden" :name="`articles_request[articles_attributes][${index}][id]`" :value="article.id">
        <input type="hidden" :name="`articles_request[articles_attributes][${index}][_destroy]`" value="1">
      </div>

      <!-- Visible article card -->
      <div v-else class="card mb-3">
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-start mb-3">
            <h5 class="card-title mb-0">Article {{ getVisibleIndex(index) + 1 }}</h5>
            <button
              type="button"
              class="btn btn-sm btn-outline-danger"
              @click="removeArticle(index)"
              :disabled="visibleArticlesCount === 1"
            >
              ✕ Supprimer
            </button>
          </div>

          <!-- Hidden ID field for persisted articles -->
          <input
            v-if="article.id"
            type="hidden"
            :name="`articles_request[articles_attributes][${index}][id]`"
            :value="article.id"
          >

          <div class="mb-3">
            <label :for="`article-title-${article.uniqueId}`" class="form-label">
              Titre de l'article
            </label>
            <input
              :id="`article-title-${article.uniqueId}`"
              type="text"
              class="form-control"
              :name="`articles_request[articles_attributes][${index}][title]`"
              v-model="article.title"
              placeholder="Titre de l'article"
            >
          </div>

          <div class="mb-3">
            <label :for="`article-content-${article.uniqueId}`" class="form-label">
              Contenu
            </label>
            <textarea
              :id="`article-content-${article.uniqueId}`"
              class="form-control"
              :name="`articles_request[articles_attributes][${index}][content]`"
              v-model="article.content"
              rows="3"
              placeholder="Contenu de l'article"
            ></textarea>
          </div>
        </div>
      </div>
    </template>

    <div class="mb-4">
      <button
        type="button"
        class="btn btn-outline-primary"
        @click="addArticle"
      >
        + Ajouter un article
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

interface Article {
  uniqueId: string
  id?: number
  title: string
  content: string
  _destroy?: boolean
}

const props = defineProps<{
  initialArticles?: any[] | string
}>()

const articles = ref<Article[]>([])
let nextUniqueId = 1

// Count visible articles (not marked for destruction)
const visibleArticlesCount = computed(() => {
  return articles.value.filter(article => !article._destroy).length
})

// Get the visual index (1-based) for a given article index
function getVisibleIndex(index: number): number {
  let visibleCount = 0
  for (let i = 0; i < articles.value.length; i++) {
    if (!articles.value[i]._destroy) {
      if (i === index) return visibleCount
      visibleCount++
    }
  }
  return visibleCount
}

// Initialize articles from Rails data or create one empty article
onMounted(() => {
  console.log('[ArticlesRequestForm] Mounting component...')
  console.log('[ArticlesRequestForm] props.initialArticles:', props.initialArticles)

  if (props.initialArticles) {
    try {
      // vue-mounter already parses JSON from data-attributes, so check type
      const parsed = Array.isArray(props.initialArticles)
        ? props.initialArticles
        : JSON.parse(props.initialArticles)

      console.log('[ArticlesRequestForm] Parsed articles:', parsed)
      articles.value = parsed.map((article: any) => ({
        uniqueId: `existing-${article.id || nextUniqueId++}`,
        id: article.id,
        title: article.title || '',
        content: article.content || '',
        _destroy: false
      }))
      console.log('[ArticlesRequestForm] Articles loaded:', articles.value.length)
    } catch (e) {
      console.error('[ArticlesRequestForm] Failed to parse initial articles:', e)
      addArticle()
    }
  } else {
    console.log('[ArticlesRequestForm] No initial articles, creating empty one')
    // Start with one empty article
    addArticle()
  }

  console.log('[ArticlesRequestForm] Final articles count:', articles.value.length)
})

function addArticle() {
  articles.value.push({
    uniqueId: `new-${nextUniqueId++}`,
    title: '',
    content: '',
    _destroy: false
  })
}

function removeArticle(index: number) {
  const article = articles.value[index]

  if (article.id) {
    // Mark persisted article for destruction (force reactivity by reassigning)
    articles.value[index] = { ...article, _destroy: true }
  } else {
    // Remove new article from list
    articles.value.splice(index, 1)
  }

  // Ensure at least one visible article remains
  if (visibleArticlesCount.value === 0) {
    addArticle()
  }
}
</script>

<style scoped>
.card {
  transition: all 0.2s ease;
}

.card:hover {
  box-shadow: 0 0.125rem 0.5rem rgba(0, 0, 0, 0.1);
}
</style>
