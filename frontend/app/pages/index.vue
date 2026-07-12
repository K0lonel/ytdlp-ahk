<script setup>
import { ref, onMounted } from 'vue'

// UI State
const activeTab = ref('download') // 'download' | 'editor'
const logMessages = ref([])

// Toast/Alert Notifications
const notification = ref({ show: false, title: '', message: '', type: 'info' })
const showNotification = (title, message, type = 'info') => {
  notification.value = { show: true, title, message, type }
  setTimeout(() => {
    notification.value.show = false
  }, 6000)
}

// Download Tab State
const downloadUrl = ref('')
const downloadFormat = ref('video') // 'video' | 'audio'
const audioFormat = ref('mp3')
const outputDir = ref('D:\\scripts\\ytdlp-ahk')
const embedThumbnail = ref(true)
const addMetadata = ref(true)

const downloadState = ref({
  active: false,
  percent: 0,
  totalSize: '',
  speed: '',
  eta: '',
  status: ''
})

// Editor Tab State
const mediaPath = ref('')
const editAction = ref('metadata') // 'metadata' | 'convert'
const convertFormat = ref('mp3')
const metaTitle = ref('')
const metaArtist = ref('')
const metaAlbum = ref('')
const metaYear = ref('')
const metaGenre = ref('')
const coverPath = ref('')
const editOutputDir = ref('D:\\scripts\\ytdlp-ahk')

const processState = ref({
  active: false,
  status: ''
})

// Callbacks from AutoHotkey (registered globally)
onMounted(() => {
  window.onDirectorySelected = (path) => {
    outputDir.value = path
    editOutputDir.value = path
  }

  window.onFileSelected = (type, path) => {
    if (type === 'media') {
      mediaPath.value = path
      // Extract file name without extension to pre-fill metadata title
      const parts = path.split('\\')
      const fileName = parts[parts.length - 1]
      const dotIndex = fileName.lastIndexOf('.')
      metaTitle.value = dotIndex !== -1 ? fileName.substring(0, dotIndex) : fileName
    } else if (type === 'cover') {
      coverPath.value = path
    }
  }

  window.onDownloadProgress = (percent, totalSize, speed, eta, status = '') => {
    downloadState.value = {
      active: true,
      percent: parseFloat(percent) || 0,
      totalSize: totalSize || 'Unknown size',
      speed: speed || '--',
      eta: eta || '--',
      status: status || 'Downloading...'
    }
  }

  window.onDownloadComplete = () => {
    downloadState.value.active = false
    downloadUrl.value = ''
    showNotification('Success!', 'Download completed successfully!', 'success')
  }

  window.onDownloadError = (message) => {
    downloadState.value.active = false
    showNotification('Download Failed', message, 'error')
  }

  window.onProcessComplete = (outputPath) => {
    processState.value.active = false
    showNotification('Processing Complete', `File saved to: ${outputPath}`, 'success')
  }

  window.onProcessError = (message) => {
    processState.value.active = false
    showNotification('Processing Failed', message, 'error')
  }
})

// AHK Host Object Triggers
const selectDirectory = () => {
  if (window.chrome?.webview?.hostObjects) {
    window.chrome.webview.hostObjects.selectDirectory('selectDirectory')
  } else {
    // Fallback for browser testing
    const path = prompt('Enter Output Directory:', outputDir.value)
    if (path) outputDir.value = path
  }
}

const selectFile = (type) => {
  if (window.chrome?.webview?.hostObjects) {
    window.chrome.webview.hostObjects.selectFile(type)
  } else {
    // Fallback for browser testing
    const path = prompt(`Enter ${type} File Path:`)
    if (path) {
      if (type === 'media') mediaPath.value = path
      else coverPath.value = path
    }
  }
}

const triggerDownload = () => {
  if (!downloadUrl.value) {
    showNotification('Warning', 'Please enter a valid YouTube URL.', 'warning')
    return
  }

  downloadState.value = {
    active: true,
    percent: 0,
    totalSize: 'Connecting...',
    speed: '--',
    eta: '--',
    status: 'Initializing yt-dlp...'
  }

  const config = {
    url: downloadUrl.value,
    format: downloadFormat.value,
    audioFormat: audioFormat.value,
    outputDir: outputDir.value,
    embedThumbnail: embedThumbnail.value,
    addMetadata: addMetadata.value
  }

  if (window.chrome?.webview?.hostObjects) {
    window.chrome.webview.hostObjects.startDownload(JSON.stringify(config))
  } else {
    // Mock for browser
    setTimeout(() => {
      window.onDownloadProgress(35, '15.4MiB', '4.2MiB/s', '00:03')
      setTimeout(() => {
        window.onDownloadProgress(80, '15.4MiB', '3.8MiB/s', '00:01')
        setTimeout(() => {
          window.onDownloadComplete()
        }, 1500)
      }, 1500)
    }, 1000)
  }
}

const triggerProcess = () => {
  if (!mediaPath.value) {
    showNotification('Warning', 'Please select a media file to process.', 'warning')
    return
  }

  processState.value.active = true
  processState.value.status = 'Running FFmpeg task...'

  const config = {
    filePath: mediaPath.value,
    action: editAction.value,
    format: convertFormat.value,
    title: metaTitle.value,
    artist: metaArtist.value,
    album: metaAlbum.value,
    year: metaYear.value,
    genre: metaGenre.value,
    coverPath: coverPath.value,
    outputDir: editOutputDir.value
  }

  if (window.chrome?.webview?.hostObjects) {
    window.chrome.webview.hostObjects.processFile(JSON.stringify(config))
  } else {
    // Mock for browser
    setTimeout(() => {
      window.onProcessComplete(mediaPath.value + '_processed.' + convertFormat.value)
    }, 2000)
  }
}
</script>

<template>
  <div class="h-[calc(100vh-35px)] flex flex-col bg-neutral-950 overflow-hidden font-sans">
    <!-- Navigation Tabs -->
    <div class="flex items-center justify-between px-6 bg-neutral-900 border-b border-neutral-800 shrink-0">
      <div class="flex gap-4">
        <button
          class="py-4 px-3 font-medium text-sm border-b-2 transition-colors flex items-center gap-2"
          :class="activeTab === 'download' ? 'border-primary text-primary' : 'border-transparent text-neutral-400 hover:text-neutral-200'"
          @click="activeTab = 'download'"
        >
          <UIcon name="i-lucide-download" class="w-4 h-4" /> Download
        </button>
        <button
          class="py-4 px-3 font-medium text-sm border-b-2 transition-colors flex items-center gap-2"
          :class="activeTab === 'editor' ? 'border-primary text-primary' : 'border-transparent text-neutral-400 hover:text-neutral-200'"
          @click="activeTab = 'editor'"
        >
          <UIcon name="i-lucide-edit" class="w-4 h-4" /> Metadata & Converter
        </button>
      </div>

      <div class="flex gap-2">
        <UButton
          icon="i-lucide-terminal"
          color="neutral"
          variant="ghost"
          size="sm"
          @click="() => { if(window.chrome?.webview?.hostObjects) window.chrome.webview.hostObjects.OpenDevTools() }"
        >
          DevTools
        </UButton>
      </div>
    </div>

    <!-- Notification Banner -->
    <div
      v-if="notification.show"
      class="mx-6 mt-4 p-4 rounded-lg flex items-start gap-3 border transition-all duration-300"
      :class="{
        'bg-green-950/40 border-green-800 text-green-200': notification.type === 'success',
        'bg-red-950/40 border-red-800 text-red-200': notification.type === 'error',
        'bg-yellow-950/40 border-yellow-800 text-yellow-200': notification.type === 'warning',
        'bg-neutral-900 border-neutral-800 text-neutral-200': notification.type === 'info'
      }"
    >
      <UIcon
        :name="notification.type === 'success' ? 'i-lucide-check-circle' : notification.type === 'error' ? 'i-lucide-alert-triangle' : 'i-lucide-info'"
        class="w-5 h-5 shrink-0 mt-0.5"
      />
      <div>
        <h4 class="font-bold text-sm">{{ notification.title }}</h4>
        <p class="text-xs text-neutral-300 mt-0.5 leading-relaxed">{{ notification.message }}</p>
      </div>
    </div>

    <!-- Tab Contents (Scrollable Pane) -->
    <div class="grow overflow-y-auto p-6 space-y-6">
      
      <!-- DOWNLOAD TAB -->
      <div v-if="activeTab === 'download'" class="max-w-2xl mx-auto space-y-6">
        
        <!-- Input URL Card -->
        <div class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-4">
          <div class="space-y-1.5">
            <label class="text-xs font-bold uppercase tracking-wider text-neutral-400">YouTube URL</label>
            <UInput
              v-model="downloadUrl"
              icon="i-lucide-link"
              placeholder="https://www.youtube.com/watch?v=..."
              size="lg"
              class="w-full"
              :disabled="downloadState.active"
              color="primary"
            />
          </div>

          <!-- Target Output Directory -->
          <div class="space-y-1.5">
            <label class="text-xs font-bold uppercase tracking-wider text-neutral-400 font-sans">Save Destination</label>
            <div class="flex gap-2">
              <UInput
                v-model="outputDir"
                readonly
                placeholder="Select output folder..."
                class="grow"
                size="md"
                :disabled="downloadState.active"
              />
              <UButton
                icon="i-lucide-folder"
                color="neutral"
                variant="subtle"
                class="px-4"
                :disabled="downloadState.active"
                @click="selectDirectory"
              >
                Browse
              </UButton>
            </div>
          </div>
        </div>

        <!-- Settings Card -->
        <div class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-6">
          <h3 class="text-sm font-bold uppercase tracking-widest text-neutral-400 border-b border-neutral-800 pb-2 flex items-center gap-2">
            <UIcon name="i-lucide-sliders" class="w-4 h-4 text-primary" /> Settings
          </h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Format Choice -->
            <div class="space-y-2">
              <label class="text-xs font-semibold text-neutral-400">Download Format</label>
              <div class="flex gap-3">
                <UButton
                  class="flex-1 justify-center py-2.5"
                  :color="downloadFormat === 'video' ? 'primary' : 'neutral'"
                  :variant="downloadFormat === 'video' ? 'solid' : 'outline'"
                  icon="i-lucide-video"
                  :disabled="downloadState.active"
                  @click="downloadFormat = 'video'"
                >
                  Video (MP4)
                </UButton>
                <UButton
                  class="flex-1 justify-center py-2.5"
                  :color="downloadFormat === 'audio' ? 'primary' : 'neutral'"
                  :variant="downloadFormat === 'audio' ? 'solid' : 'outline'"
                  icon="i-lucide-music"
                  :disabled="downloadState.active"
                  @click="downloadFormat = 'audio'"
                >
                  Audio Extract
                </UButton>
              </div>
            </div>

            <!-- Audio Format Select (visible only for audio extraction) -->
            <div class="space-y-2" :class="{ 'opacity-40 pointer-events-none': downloadFormat !== 'audio' }">
              <label class="text-xs font-semibold text-neutral-400">Audio Extension</label>
              <USelect
                v-model="audioFormat"
                :options="['mp3', 'm4a', 'wav', 'opus', 'flac']"
                size="md"
                class="w-full"
                :disabled="downloadState.active || downloadFormat !== 'audio'"
              />
            </div>
          </div>

          <!-- Options Toggles -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 border-t border-neutral-800 pt-4">
            <div class="flex items-center justify-between p-3 bg-neutral-950 rounded-lg border border-neutral-850">
              <div>
                <h4 class="text-xs font-semibold">Embed Thumbnail</h4>
                <p class="text-[10px] text-neutral-400 mt-0.5">Attach YouTube cover as track art</p>
              </div>
              <USwitch v-model="embedThumbnail" :disabled="downloadState.active" />
            </div>

            <div class="flex items-center justify-between p-3 bg-neutral-950 rounded-lg border border-neutral-850">
              <div>
                <h4 class="text-xs font-semibold">Embed Metadata</h4>
                <p class="text-[10px] text-neutral-400 mt-0.5">Write track info, uploader & year</p>
              </div>
              <USwitch v-model="addMetadata" :disabled="downloadState.active" />
            </div>
          </div>
        </div>

        <!-- Download Action / Progress -->
        <div class="space-y-4">
          <!-- Start Download Button -->
          <UButton
            v-if="!downloadState.active"
            size="xl"
            color="primary"
            class="w-full py-4 justify-center text-md font-bold shadow-xl shadow-primary-950/20"
            icon="i-lucide-download"
            @click="triggerDownload"
          >
            Start Download
          </UButton>

          <!-- Downloading Status Card -->
          <div v-else class="bg-neutral-900 border border-primary-900/40 rounded-xl p-6 shadow-xl space-y-4">
            <div class="flex items-center justify-between text-xs text-neutral-400">
              <span class="flex items-center gap-1.5 text-primary font-bold animate-pulse">
                <UIcon name="i-lucide-refresh-cw" class="w-3.5 h-3.5 animate-spin" />
                {{ downloadState.status }}
              </span>
              <span class="font-bold text-neutral-200">{{ downloadState.percent }}%</span>
            </div>

            <!-- Progress Bar -->
            <UProgress :value="downloadState.percent" color="primary" class="h-2" />

            <!-- Stats Block -->
            <div class="grid grid-cols-3 gap-4 pt-2 text-center border-t border-neutral-800">
              <div>
                <p class="text-[10px] uppercase font-bold text-neutral-400">Speed</p>
                <p class="text-sm font-semibold text-neutral-200 mt-0.5">{{ downloadState.speed }}</p>
              </div>
              <div>
                <p class="text-[10px] uppercase font-bold text-neutral-400">Size</p>
                <p class="text-sm font-semibold text-neutral-200 mt-0.5">{{ downloadState.totalSize }}</p>
              </div>
              <div>
                <p class="text-[10px] uppercase font-bold text-neutral-400">ETA</p>
                <p class="text-sm font-semibold text-neutral-200 mt-0.5">{{ downloadState.eta }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- METADATA EDITOR & CONVERTER TAB -->
      <div v-if="activeTab === 'editor'" class="max-w-2xl mx-auto space-y-6">
        
        <!-- Input File Card -->
        <div class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-4">
          <div class="space-y-1.5">
            <label class="text-xs font-bold uppercase tracking-wider text-neutral-400">Source Media File</label>
            <div class="flex gap-2">
              <UInput
                v-model="mediaPath"
                readonly
                placeholder="Click browse to select a media file..."
                class="grow"
                size="md"
                :disabled="processState.active"
              />
              <UButton
                icon="i-lucide-file"
                color="neutral"
                variant="subtle"
                class="px-4"
                :disabled="processState.active"
                @click="selectFile('media')"
              >
                Browse
              </UButton>
            </div>
          </div>
        </div>

        <!-- Configuration Card -->
        <div class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-6">
          <h3 class="text-sm font-bold uppercase tracking-widest text-neutral-400 border-b border-neutral-800 pb-2 flex items-center gap-2">
            <UIcon name="i-lucide-settings" class="w-4 h-4 text-primary" /> Processing Tasks
          </h3>

          <!-- Choose Action -->
          <div class="space-y-2">
            <label class="text-xs font-semibold text-neutral-400">Action Type</label>
            <div class="flex gap-3">
              <UButton
                class="flex-1 justify-center py-2.5"
                :color="editAction === 'metadata' ? 'primary' : 'neutral'"
                :variant="editAction === 'metadata' ? 'solid' : 'outline'"
                icon="i-lucide-edit"
                :disabled="processState.active"
                @click="editAction = 'metadata'"
              >
                Edit Metadata Only
              </UButton>
              <UButton
                class="flex-1 justify-center py-2.5"
                :color="editAction === 'convert' ? 'primary' : 'neutral'"
                :variant="editAction === 'convert' ? 'solid' : 'outline'"
                icon="i-lucide-refresh-cw"
                :disabled="processState.active"
                @click="editAction = 'convert'"
              >
                Convert & Edit
              </UButton>
            </div>
          </div>

          <!-- Format Choice (visible only when converting) -->
          <div v-if="editAction === 'convert'" class="space-y-2 animate-fadeIn">
            <label class="text-xs font-semibold text-neutral-400">Target Output Format</label>
            <USelect
              v-model="convertFormat"
              :options="['mp3', 'm4a', 'wav', 'mp4', 'mkv']"
              size="md"
              class="w-full"
              :disabled="processState.active"
            />
          </div>

          <!-- Metadata Fields -->
          <div class="border-t border-neutral-800 pt-4 space-y-4">
            <h4 class="text-xs font-bold uppercase tracking-wider text-neutral-400 mb-2">Write Metadata tags</h4>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="space-y-1.5">
                <label class="text-[11px] text-neutral-400">Title</label>
                <UInput v-model="metaTitle" placeholder="Song/Video Title" size="md" :disabled="processState.active" />
              </div>
              <div class="space-y-1.5">
                <label class="text-[11px] text-neutral-400">Artist / Channel</label>
                <UInput v-model="metaArtist" placeholder="Artist Name" size="md" :disabled="processState.active" />
              </div>
              <div class="space-y-1.5">
                <label class="text-[11px] text-neutral-400">Album</label>
                <UInput v-model="metaAlbum" placeholder="Album Name" size="md" :disabled="processState.active" />
              </div>
              <div class="grid grid-cols-2 gap-3">
                <div class="space-y-1.5">
                  <label class="text-[11px] text-neutral-400">Year</label>
                  <UInput v-model="metaYear" placeholder="e.g. 2026" size="md" :disabled="processState.active" />
                </div>
                <div class="space-y-1.5">
                  <label class="text-[11px] text-neutral-400">Genre</label>
                  <UInput v-model="metaGenre" placeholder="e.g. Rock" size="md" :disabled="processState.active" />
                </div>
              </div>
            </div>

            <!-- Cover Art Selector -->
            <div class="space-y-1.5 pt-2">
              <label class="text-[11px] text-neutral-400">Attach Custom Cover Image (Album Art)</label>
              <div class="flex gap-2">
                <UInput
                  v-model="coverPath"
                  readonly
                  placeholder="Select JPEG/PNG/WebP cover image..."
                  class="grow"
                  size="md"
                  :disabled="processState.active"
                />
                <UButton
                  icon="i-lucide-image"
                  color="neutral"
                  variant="subtle"
                  class="px-4"
                  :disabled="processState.active"
                  @click="selectFile('cover')"
                >
                  Browse
                </UButton>
              </div>
            </div>
          </div>

          <!-- Target Output Directory -->
          <div class="border-t border-neutral-800 pt-4 space-y-1.5">
            <label class="text-xs font-bold uppercase tracking-wider text-neutral-400">Output Folder</label>
            <div class="flex gap-2">
              <UInput
                v-model="editOutputDir"
                readonly
                placeholder="Select output folder..."
                class="grow"
                size="md"
                :disabled="processState.active"
              />
              <UButton
                icon="i-lucide-folder"
                color="neutral"
                variant="subtle"
                class="px-4"
                :disabled="processState.active"
                @click="selectDirectory"
              >
                Browse
              </UButton>
            </div>
          </div>
        </div>

        <!-- Action / Processing Status -->
        <div class="space-y-4">
          <!-- Start Button -->
          <UButton
            v-if="!processState.active"
            size="xl"
            color="primary"
            class="w-full py-4 justify-center text-md font-bold shadow-xl shadow-primary-950/20"
            icon="i-lucide-settings"
            @click="triggerProcess"
          >
            Apply Changes
          </UButton>

          <!-- Loading Card -->
          <div v-else class="bg-neutral-900 border border-primary-900/40 rounded-xl p-6 shadow-xl flex items-center justify-center gap-3">
            <UIcon name="i-lucide-refresh-cw" class="w-5 h-5 text-primary animate-spin" />
            <span class="font-bold text-sm text-neutral-200">{{ processState.status }}</span>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(5px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fadeIn {
  animation: fadeIn 0.25s ease-out forwards;
}
</style>
