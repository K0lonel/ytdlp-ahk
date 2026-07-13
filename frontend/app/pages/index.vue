<script setup>
import { ref, onMounted, watch, nextTick } from 'vue'

// UI State
const activeTab = ref('download') // 'download' | 'editor' | 'rules'
const logMessages = ref([])

const defaultRules = [
  { pattern: '\\u274C', replacement: 'x' },
  { pattern: '\\(.*?\\)|\\s*\\[.*?\\]', replacement: '' },
  { pattern: 'BUZZ HOUSE OST', replacement: '' },
  { pattern: 'Manele', replacement: '' },
  { pattern: 'Mentolate', replacement: '' },
  { pattern: 'Oficial', replacement: '' },
  { pattern: 'Official', replacement: '' },
  { pattern: 'Video', replacement: '' },
  { pattern: 'Videoclip', replacement: '' },
  { pattern: 'Part 1', replacement: '' },
  { pattern: 'Original', replacement: '' },
  { pattern: 'tiktok', replacement: '' },
  { pattern: 'version', replacement: '' },
  { pattern: 'extended', replacement: '' },
  { pattern: 'ft\\.', replacement: '' },
  { pattern: 'Remix', replacement: '' }
]

const rules = ref([])

const saveRules = () => {
  localStorage.setItem('ytdlp_rename_rules', JSON.stringify(rules.value))
}

const addRule = () => {
  rules.value.push({ pattern: '', replacement: '' })
  saveRules()
}

const removeRule = (index) => {
  rules.value.splice(index, 1)
  saveRules()
}

const resetRules = () => {
  rules.value = defaultRules.map(r => ({ ...r }))
  saveRules()
}

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
const audioFormat = ref('m4a')
const videoFormat = ref('mp4')
const isPlaylist = ref(false)
const playlistAll = ref(true)
const playlistRange = ref([1, 3])
const outputDir = ref('../../../yt-download')
const embedThumbnail = ref(true)
const addMetadata = ref(true)

watch(downloadUrl, (newUrl) => {
  if (newUrl) {
    if (newUrl.includes('list=') || newUrl.includes('/playlist')) {
      isPlaylist.value = true
    } else {
      isPlaylist.value = false
    }
  }
})

const consoleBox = ref(null)

watch(logMessages, () => {
  if (consoleBox.value) {
    nextTick(() => {
      consoleBox.value.scrollTop = consoleBox.value.scrollHeight
    })
  }
}, { deep: true })

const downloadState = ref({
  active: false,
  percent: 0,
  totalSize: '',
  speed: '',
  eta: '',
  status: ''
})

const playlistIndex = ref(0)
const playlistTotal = ref(0)
const downloadTimeStr = ref('00:00')
let downloadStartTime = 0
let downloadTimeInterval = null

const startDownloadTimer = () => {
  playlistIndex.value = 0
  playlistTotal.value = 0
  downloadTimeStr.value = '00:00'
  downloadStartTime = Date.now()
  if (downloadTimeInterval) clearInterval(downloadTimeInterval)
  downloadTimeInterval = setInterval(() => {
    const elapsed = Math.floor((Date.now() - downloadStartTime) / 1000)
    const mins = String(Math.floor(elapsed / 60)).padStart(2, '0')
    const secs = String(elapsed % 60).padStart(2, '0')
    downloadTimeStr.value = `${mins}:${secs}`
  }, 1000)
}

const stopDownloadTimer = () => {
  if (downloadTimeInterval) {
    clearInterval(downloadTimeInterval)
    downloadTimeInterval = null
  }
}

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
const editOutputDir = ref('../../../yt-download')

const processState = ref({
  active: false,
  status: ''
})

// Callbacks from AutoHotkey (registered globally)
onMounted(() => {
  // Load Rules
  const savedRules = localStorage.getItem('ytdlp_rename_rules')
  if (savedRules) {
    rules.value = JSON.parse(savedRules)
  } else {
    rules.value = defaultRules.map(r => ({ ...r }))
    localStorage.setItem('ytdlp_rename_rules', JSON.stringify(rules.value))
  }

  window.onLogUpdate = (text) => {
    const lines = text.split('\n').map(l => l.replace(/\r$/, ''))
    if (lines.length > 0 && lines[lines.length - 1] === '') {
      lines.pop()
    }
    logMessages.value = lines
    
    // Parse playlist progress like "[download] Downloading item X of Y"
    for (let i = lines.length - 1; i >= 0; i--) {
      const match = lines[i].match(/\[download\]\s+Downloading\s+(?:item|video)\s+(\d+)\s+of\s+(\d+)/i)
      if (match) {
        playlistIndex.value = parseInt(match[1])
        playlistTotal.value = parseInt(match[2])
        break
      }
    }
  }

  window.onDirectorySelected = (path) => {
    outputDir.value = path
    editOutputDir.value = path
  }

  window.setInitialDir = (path) => {
    outputDir.value = path
    editOutputDir.value = path
  }

  if (window.initialDir) {
    window.setInitialDir(window.initialDir)
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

  window.onDownloadComplete = (pathsStr = '') => {
    stopDownloadTimer()
    downloadState.value.active = false
    downloadUrl.value = ''
    if (pathsStr) {
      const paths = pathsStr.split('|')
      if (paths.length === 1) {
        const parts = paths[0].split('\\')
        const fileName = parts[parts.length - 1]
        showNotification('Success!', `Downloaded and renamed to: ${fileName}`, 'success')
      } else {
        const files = paths.map(p => {
          const parts = p.split('\\')
          return parts[parts.length - 1]
        })
        showNotification('Success!', `Downloaded and renamed ${files.length} files:\n${files.join('\n')}`, 'success')
      }
    } else {
      showNotification('Success!', 'Download completed successfully!', 'success')
    }
  }

  window.onDownloadError = (message) => {
    stopDownloadTimer()
    downloadState.value.active = false
    showNotification('Download Failed', message, 'error')
  }

  window.onProcessComplete = (pathsStr = '') => {
    processState.value.active = false
    if (pathsStr.includes('|')) {
      const parts = pathsStr.split('|')
      const sourceName = parts[0].split('\\').pop()
      const outputName = parts[1].split('\\').pop()
      showNotification('Success!', `Converted/Edited:\n"${sourceName}" ➔ "${outputName}"`, 'success')
    } else {
      const parts = pathsStr.split('\\')
      const fileName = parts[parts.length - 1]
      showNotification('Success!', `Saved to: ${fileName}`, 'success')
    }
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

  startDownloadTimer()

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
    videoFormat: videoFormat.value,
    isPlaylist: isPlaylist.value,
    playlistAll: playlistAll.value,
    playlistRange: playlistRange.value,
    rules: rules.value,
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
    rules: rules.value,
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
        <button
          class="py-4 px-3 font-medium text-sm border-b-2 transition-colors flex items-center gap-2"
          :class="activeTab === 'rules' ? 'border-primary text-primary' : 'border-transparent text-neutral-400 hover:text-neutral-200'"
          @click="activeTab = 'rules'"
        >
          <UIcon name="i-lucide-settings-2" class="w-4 h-4" /> Renaming Rules
        </button>
      </div>

      <div></div>
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
    <div class="grow overflow-y-auto p-6">
      <div class="max-w-6xl mx-auto">
        
        <!-- Two-Column Layout for Download and Editor tabs -->
        <div v-if="activeTab === 'download' || activeTab === 'editor'" class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          
          <!-- Left Column: Inputs & Controls -->
          <div class="lg:col-span-7 space-y-6">
            
            <!-- DOWNLOAD TAB -->
            <div v-if="activeTab === 'download'" class="space-y-6 animate-fadeIn">
              <!-- Input URL Card -->
              <div class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-4">
                <div class="space-y-1.5">
                  <div class="flex justify-between items-center">
                    <label class="text-xs font-bold uppercase tracking-wider text-neutral-400">YouTube URL</label>
                    <div class="flex items-center gap-3">
                      <!-- Playlist Range Container (Borderless) -->
                      <div v-if="isPlaylist" class="flex items-center gap-2 text-xs transition-all duration-300 ease-out animate-fadeIn">
                        <UCheckbox
                          v-model="playlistAll"
                          label="All"
                          :disabled="downloadState.active"
                        />
                        
                        <span v-if="!playlistAll" class="h-4 w-px bg-neutral-800 mx-1"></span>

                        <div v-if="!playlistAll" class="flex items-center gap-1.5 animate-fadeIn">
                          <span class="text-[10px] text-neutral-500 font-bold uppercase whitespace-nowrap">Range:</span>
                          <UInput
                            v-model.number="playlistRange[0]"
                            type="number"
                            min="1"
                            size="xs"
                            class="w-12 text-center"
                            :disabled="downloadState.active"
                          />
                          <span class="text-neutral-500 text-xs">-</span>
                          <UInput
                            v-model.number="playlistRange[1]"
                            type="number"
                            min="1"
                            size="xs"
                            class="w-12 text-center"
                            :disabled="downloadState.active"
                          />
                        </div>
                      </div>
                      <!-- Checkbox -->
                      <UCheckbox
                        v-model="isPlaylist"
                        label="Playlist"
                        :disabled="downloadState.active"
                      />
                    </div>
                  </div>
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
                        Video
                      </UButton>
                      <UButton
                        class="flex-1 justify-center py-2.5"
                        :color="downloadFormat === 'audio' ? 'primary' : 'neutral'"
                        :variant="downloadFormat === 'audio' ? 'solid' : 'outline'"
                        icon="i-lucide-music"
                        :disabled="downloadState.active"
                        @click="downloadFormat = 'audio'"
                      >
                        Audio
                      </UButton>
                    </div>
                  </div>

                  <!-- Extension Select (based on format choice) -->
                  <div class="space-y-2">
                    <template v-if="downloadFormat === 'video'">
                      <label class="text-xs font-semibold text-neutral-400">Video Extension</label>
                      <USelect
                        v-model="videoFormat"
                        :items="['mp4', 'mkv', 'webm']"
                        size="md"
                        class="w-full"
                        :disabled="downloadState.active"
                      />
                    </template>
                    <template v-else-if="downloadFormat === 'audio'">
                      <label class="text-xs font-semibold text-neutral-400">Audio Extension</label>
                      <USelect
                        v-model="audioFormat"
                        :items="['mp3', 'm4a', 'wav', 'opus', 'flac']"
                        size="md"
                        class="w-full"
                        :disabled="downloadState.active"
                      />
                    </template>
                  </div>
                </div>

                <!-- Options Toggles -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 border-t border-neutral-800 pt-4">
                  <div class="flex items-center justify-between p-3 bg-neutral-950 rounded-lg border border-neutral-800">
                    <div>
                      <h4 class="text-xs font-semibold">Embed Thumbnail</h4>
                      <p class="text-[10px] text-neutral-400 mt-0.5">Attach YouTube cover as track art</p>
                    </div>
                    <USwitch v-model="embedThumbnail" :disabled="downloadState.active" />
                  </div>

                  <div class="flex items-center justify-between p-3 bg-neutral-950 rounded-lg border border-neutral-800">
                    <div>
                      <h4 class="text-xs font-semibold">Embed Metadata</h4>
                      <p class="text-[10px] text-neutral-400 mt-0.5">Write track info, uploader & year</p>
                    </div>
                    <USwitch v-model="addMetadata" :disabled="downloadState.active" />
                  </div>
                </div>
              </div>

              <!-- Start Download Button (Only visible when not active) -->
              <div v-if="!downloadState.active" class="space-y-4">
                <UButton
                  size="xl"
                  color="primary"
                  class="w-full py-4 justify-center text-md font-bold shadow-xl shadow-primary-950/20"
                  icon="i-lucide-download"
                  @click="triggerDownload"
                >
                  Start Download
                </UButton>
              </div>
            </div>

            <!-- METADATA EDITOR & CONVERTER TAB -->
            <div v-if="activeTab === 'editor'" class="space-y-6 animate-fadeIn">
              <!-- Processing Status Card (Shown first when active) -->
              <div v-if="processState.active" class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl flex items-center justify-center gap-3">
                <UIcon name="i-lucide-refresh-cw" class="w-5 h-5 text-primary animate-spin" />
                <span class="font-bold text-sm text-neutral-200">{{ processState.status }}</span>
              </div>

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
                    :items="['mp3', 'm4a', 'wav', 'mp4', 'mkv']"
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

              <!-- Start Button (Only visible when not active) -->
              <div v-if="!processState.active" class="space-y-4">
                <UButton
                  size="xl"
                  color="primary"
                  class="w-full py-4 justify-center text-md font-bold shadow-xl shadow-primary-950/20"
                  icon="i-lucide-settings"
                  @click="triggerProcess"
                >
                  Apply Changes
                </UButton>
              </div>
            </div>

          </div>

          <!-- Right Column: Output Console & Download Info -->
          <div class="lg:col-span-5 space-y-4">
            <div class="bg-neutral-950 border border-neutral-800 rounded-xl p-4 shadow-xl space-y-2 font-mono text-xs h-[400px] flex flex-col">
              <div class="flex justify-between items-center text-neutral-400 border-b border-neutral-800 pb-1.5 mb-2 shrink-0">
                <span class="flex items-center gap-1.5">
                  <UIcon name="i-lucide-terminal" class="w-3.5 h-3.5 animate-pulse text-primary" v-if="downloadState.active || processState.active" />
                  <UIcon name="i-lucide-terminal" class="w-3.5 h-3.5" v-else />
                  Output Console
                </span>
                <UButton
                  v-if="logMessages.length > 0"
                  size="xs"
                  color="neutral"
                  variant="ghost"
                  @click="logMessages = []"
                >
                  Clear Log
                </UButton>
              </div>
              <div ref="consoleBox" class="grow overflow-y-auto space-y-1 scrollbar-thin scrollbar-thumb-neutral-800 scrollbar-track-transparent">
                <div v-for="(line, idx) in logMessages" :key="idx" class="whitespace-pre-wrap leading-relaxed select-text font-mono text-left">
                  {{ line }}
                </div>
                <!-- Idle Placeholder -->
                <div v-if="logMessages.length === 0" class="text-neutral-500 text-center py-24 select-none">
                  Console is idle. Download logs will appear here.
                </div>
              </div>
            </div>

            <!-- Downloading Status Card (Shown under the console when downloading) -->
            <div v-if="downloadState.active" class="bg-neutral-900 border border-neutral-800 rounded-xl p-4 shadow-xl space-y-3 animate-fadeIn">
              <div class="flex items-center justify-between text-xs text-neutral-400">
                <span class="flex items-center gap-1.5 text-primary font-bold animate-pulse">
                  <UIcon name="i-lucide-refresh-cw" class="w-3.5 h-3.5 animate-spin" />
                  {{ downloadState.status || 'Downloading...' }}
                </span>
                <div class="flex items-center gap-2.5 font-bold text-neutral-200">
                  <span v-if="playlistTotal > 0" class="text-xs text-neutral-400 font-semibold bg-neutral-950 px-2 py-0.5 rounded border border-neutral-800">
                    {{ playlistIndex }}/{{ playlistTotal }}
                  </span>
                  <span>{{ downloadState.percent }}%</span>
                </div>
              </div>

              <!-- Progress Bar -->
              <UProgress :value="downloadState.percent" color="primary" class="h-2" />

              <!-- Stats Block (4 Columns: Speed, Time, ETA, Size) -->
              <div class="grid grid-cols-4 gap-2 pt-2 text-center border-t border-neutral-800">
                <div>
                  <p class="text-[9px] uppercase font-bold text-neutral-400">Speed</p>
                  <p class="text-xs font-semibold text-neutral-200 mt-0.5">{{ downloadState.speed || '-' }}</p>
                </div>
                <div>
                  <p class="text-[9px] uppercase font-bold text-neutral-400">Time</p>
                  <p class="text-xs font-semibold text-neutral-200 mt-0.5">{{ downloadTimeStr }}</p>
                </div>
                <div>
                  <p class="text-[9px] uppercase font-bold text-neutral-400">ETA</p>
                  <p class="text-xs font-semibold text-neutral-200 mt-0.5">{{ downloadState.eta || '-' }}</p>
                </div>
                <div>
                  <p class="text-[9px] uppercase font-bold text-neutral-400">Size</p>
                  <p class="text-xs font-semibold text-neutral-200 mt-0.5">{{ downloadState.totalSize || '-' }}</p>
                </div>
              </div>
            </div>
          </div>

        </div>

        <!-- Rules Tab Layout (Single Column) -->
        <div v-else-if="activeTab === 'rules'" class="max-w-2xl mx-auto space-y-6 animate-fadeIn">
          <div class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-4">
            <div>
              <h3 class="text-sm font-bold uppercase tracking-widest text-neutral-400 flex items-center gap-2">
                <UIcon name="i-lucide-settings-2" class="w-4 h-4 text-primary" /> Filename Renaming Rules
              </h3>
              <p class="text-xs text-neutral-400 mt-1 leading-relaxed">
                Define regular expression patterns to automatically clean up filenames after downloading or converting. Rules are executed in order.
              </p>
            </div>

            <!-- Rules List -->
            <div class="space-y-3">
              <div v-for="(rule, idx) in rules" :key="idx" class="flex gap-2 items-center p-3 bg-neutral-950 rounded-lg border border-neutral-800">
                <div class="grow grid grid-cols-2 gap-3">
                  <div class="space-y-1">
                    <span class="text-[10px] text-neutral-500 font-bold uppercase">Pattern (Regex)</span>
                    <UInput
                      v-model="rule.pattern"
                      placeholder="e.g. \((.*?)\)"
                      size="sm"
                      class="font-mono w-full"
                      @change="saveRules"
                    />
                  </div>
                  <div class="space-y-1">
                    <span class="text-[10px] text-neutral-500 font-bold uppercase">Replacement</span>
                    <UInput
                      v-model="rule.replacement"
                      placeholder="Empty to remove"
                      size="sm"
                      class="font-mono w-full"
                      @change="saveRules"
                    />
                  </div>
                </div>
                <div class="pt-4">
                  <UButton
                    icon="i-lucide-trash-2"
                    color="danger"
                    variant="ghost"
                    size="sm"
                    class="text-red-500 hover:text-red-400"
                    @click="removeRule(idx)"
                  />
                </div>
              </div>

              <!-- Empty State -->
              <div v-if="rules.length === 0" class="text-center py-6 text-neutral-500 text-xs">
                No custom rules defined. Click "Add Rule" to create one.
              </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex justify-between pt-2">
              <UButton
                icon="i-lucide-plus"
                color="primary"
                variant="subtle"
                size="sm"
                @click="addRule"
              >
                Add Rule
              </UButton>
              <UButton
                icon="i-lucide-rotate-ccw"
                color="neutral"
                variant="ghost"
                size="sm"
                @click="resetRules"
              >
                Reset Defaults
              </UButton>
            </div>
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
