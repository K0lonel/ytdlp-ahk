// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  // 1. Compile as a client-side Single Page Application (SPA)
  ssr: false,

  // 2. Enable hash mode routing to prevent local route 404s
  router: {
    options: {
      hashMode: true
    }
  },

  // 3. Configure assets base path for local file loading
  app: {
    baseURL: './',
    buildAssetsDir: '_nuxt/'
  },

  modules: [
    '@nuxt/eslint',
    '@nuxt/ui'
  ],

  colorMode: {
    preference: 'dark'
  },

  devtools: {
    enabled: true
  },

  css: ['~/assets/css/main.css'],

  routeRules: {
    '/': { prerender: true }
  },

  compatibilityDate: '2026-06-30',

  eslint: {
    config: {
      stylistic: {
        commaDangle: 'never',
        braceStyle: '1tbs'
      }
    }
  }
})

