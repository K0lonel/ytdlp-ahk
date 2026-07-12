<script setup>
// Webview window caption handlers mapped to AHK functions
const dragWindow = () => window.chrome?.webview?.hostObjects?.DragWindow()
const minimizeWindow = () => window.chrome?.webview?.hostObjects?.minimizeWindow()
const maximizeWindow = () => window.chrome?.webview?.hostObjects?.maximizeWindow()
const closeWindow = () => window.chrome?.webview?.hostObjects?.closeWindow()

useHead({
  meta: [
    { name: 'viewport', content: 'width=device-width, initial-scale=1' }
  ],
  link: [
    { rel: 'icon', href: '/favicon.ico' }
  ],
  htmlAttrs: {
    lang: 'en'
  }
})

const title = 'YT-DLP & FFmpeg Tool'
const description = 'AutoHotkey powered YouTube Downloader and Media Converter'

useSeoMeta({
  title,
  description,
  ogTitle: title,
  ogDescription: description
})
</script>

<template>
  <UApp>
    <!-- Custom Web-based TitleBar -->
    <div class="ahk-titleBar flex items-center justify-between select-none bg-neutral-950 h-[35px] border-b border-neutral-800 text-neutral-400">
      <span class="font-semibold pl-4 tracking-[0.5px] text-[0.8rem] flex items-center gap-1.5 text-primary">
        <UIcon name="i-lucide-download" class="w-4 h-4" /> YT-DLP & FFMPEG TOOL
      </span>
      <!-- Middle drag handle -->
      <span class="grow h-full cursor-move" @mousedown="dragWindow"></span>
      <div class="flex h-full items-center">
        <!-- Minimize Button -->
        <UButton
          icon="i-lucide-minus"
          color="neutral"
          variant="ghost"
          class="h-full w-10 flex justify-center rounded-none text-neutral-400 hover:text-neutral-200 hover:bg-neutral-800"
          aria-label="Minimize"
          @click="minimizeWindow"
        />
        <!-- Maximize Button -->
        <UButton
          icon="i-lucide-square"
          color="neutral"
          variant="ghost"
          class="h-full w-10 flex justify-center rounded-none text-neutral-400 hover:text-neutral-200 hover:bg-neutral-800"
          aria-label="Maximize"
          @click="maximizeWindow"
        />
        <!-- Close Button -->
        <UButton
          icon="i-lucide-x"
          color="neutral"
          variant="ghost"
          class="h-full w-10 flex justify-center rounded-none text-neutral-400 hover:text-white hover:bg-red-500"
          aria-label="Close"
          @click="closeWindow"
        />
      </div>
    </div>

    <!-- Main Content Canvas -->
    <UMain class="p-0 bg-neutral-950 min-h-[calc(100vh-35px)] text-neutral-100">
      <NuxtPage />
    </UMain>
  </UApp>
</template>

<style>
body {
  margin: 0;
  overflow: hidden;
  background-color: #0a0a0a;
}
</style>

