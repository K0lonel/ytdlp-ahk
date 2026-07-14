<script setup>
import { ref, onMounted, watch, nextTick, computed } from 'vue'

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
const toast = useToast()
const showNotification = (title, message, type = 'info') => {
  let toastColor = 'primary'
  if (type === 'success') toastColor = 'success'
  else if (type === 'error') toastColor = 'danger'
  else if (type === 'warning') toastColor = 'warning'

  toast.add({
    title: title,
    description: message,
    color: toastColor
  })
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

// Crop Section State
const enableSection = ref(false)
const sectionRange = ref([0, 100])
const videoDuration = ref(0)
const videoTitle = ref('')
const isLoadingInfo = ref(false)
const startStr = ref('00:00')
const endStr = ref('00:00')

// YouTube Preview Embed Computed Properties
const youtubeId = computed(() => {
  if (!downloadUrl.value) return null
  const regExp = /^.*(youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/
  const match = downloadUrl.value.match(regExp)
  return (match && match[2].length === 11) ? match[2] : null
})

const embedUrl = computed(() => {
  if (!youtubeId.value) return null
  return `https://www.youtube.com/embed/${youtubeId.value}?enablejsapi=1`
})

// Playlist State
const playlistVideos = ref([])
const selectedPlaylistIndices = ref([])
const expandedPlaylistIndex = ref(null)
const isPlaylistLoading = ref(false)
const selectAllPlaylist = ref(true)
const playlistCropRanges = ref({})
const downloadQueue = ref([])
const isQueueDownloading = ref(false)

const visiblePlaylistCount = ref(30)
const visiblePlaylistVideos = computed(() => {
  return playlistVideos.value.slice(0, visiblePlaylistCount.value)
})

const onPlaylistScroll = (event) => {
  const { scrollTop, scrollHeight, clientHeight } = event.target
  if (scrollHeight - scrollTop - clientHeight < 50) {
    if (visiblePlaylistCount.value < playlistVideos.value.length) {
      visiblePlaylistCount.value = Math.min(
        visiblePlaylistCount.value + 30,
        playlistVideos.value.length
      )
    }
  }
}

let fetchInfoTimeout = null

const formatDuration = (sec) => {
  if (isNaN(sec) || sec < 0) return '00:00'
  const h = Math.floor(sec / 3600)
  const m = Math.floor((sec % 3600) / 60)
  const s = Math.floor(sec % 60)
  if (h > 0) {
    return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
  }
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

const parseTimeToSeconds = (val) => {
  if (typeof val === 'number') return val
  if (!val) return 0
  const parts = val.split(':').map(Number)
  if (parts.length === 3) {
    return parts[0] * 3600 + parts[1] * 60 + parts[2]
  } else if (parts.length === 2) {
    return parts[0] * 60 + parts[1]
  } else if (parts.length === 1) {
    return parts[0] || 0
  }
  return 0
}

const updateRangeFromInputs = () => {
  const startSec = parseTimeToSeconds(startStr.value)
  const endSec = parseTimeToSeconds(endStr.value)
  const newStart = Math.max(0, Math.min(startSec, videoDuration.value))
  const newEnd = Math.max(newStart, Math.min(endSec, videoDuration.value))
  sectionRange.value = [newStart, newEnd]
}

const fetchVideoInfo = () => {
  if (!downloadUrl.value || isPlaylist.value) return
  isLoadingInfo.value = true
  videoTitle.value = ''
  videoDuration.value = 0
  enableSection.value = false
  if (window.chrome?.webview?.hostObjects) {
    window.chrome.webview.hostObjects.getVideoInfo(downloadUrl.value)
  } else {
    // Mock for browser testing
    setTimeout(() => {
      window.onVideoInfoSuccess('Sample YouTube Video Title', '345')
    }, 1000)
  }
}

const resetPlaylistState = () => {
  playlistVideos.value = []
  selectedPlaylistIndices.value = []
  expandedPlaylistIndex.value = null
  isPlaylistLoading.value = false
  selectAllPlaylist.value = true
  playlistCropRanges.value = {}
  visiblePlaylistCount.value = 30
}

const fetchPlaylistInfo = () => {
  if (!downloadUrl.value) return
  isPlaylistLoading.value = true
  playlistVideos.value = []
  playlistCropRanges.value = {}
  if (window.chrome?.webview?.hostObjects) {
    window.chrome.webview.hostObjects.getPlaylistInfo(downloadUrl.value)
  } else {
    // Mock for browser testing
    setTimeout(() => {
      window.onPlaylistInfoSuccess([
        {
          id: 'yPYZpwSpKmA',
          title: 'Coldplay - The Scientist (Official 4K Video)',
          duration: 260,
          duration_string: '4:20',
          uploader: 'Coldplay',
          thumbnails: [{ url: 'https://i.ytimg.com/vi/yPYZpwSpKmA/hqdefault.jpg' }]
        },
        {
          id: 'yPYZpwSpKmA',
          title: 'Coldplay - Yellow (Official 4K Video)',
          duration: 268,
          duration_string: '4:28',
          uploader: 'Coldplay',
          thumbnails: [{ url: 'https://i.ytimg.com/vi/yPYZpwSpKmA/hqdefault.jpg' }]
        }
      ])
    }, 1500)
  }
}

const toggleSelectAllPlaylist = (val) => {
  selectAllPlaylist.value = val
  if (val) {
    selectedPlaylistIndices.value = playlistVideos.value.map((_, i) => i + 1)
  } else {
    selectedPlaylistIndices.value = []
  }
}

const togglePlaylistItem = (index, isChecked) => {
  if (isChecked) {
    if (!selectedPlaylistIndices.value.includes(index)) {
      selectedPlaylistIndices.value.push(index)
    }
  } else {
    selectedPlaylistIndices.value = selectedPlaylistIndices.value.filter(i => i !== index)
  }
}

watch(selectedPlaylistIndices, (newVal) => {
  if (playlistVideos.value.length === 0) {
    selectAllPlaylist.value = false
  } else {
    selectAllPlaylist.value = newVal.length === playlistVideos.value.length
  }
}, { deep: true })

const toggleExpandVideo = async (index) => {
  if (expandedPlaylistIndex.value === index) {
    expandedPlaylistIndex.value = null
  } else {
    expandedPlaylistIndex.value = index
    const video = playlistVideos.value[index - 1]
    if (!playlistCropRanges.value[index]) {
      playlistCropRanges.value[index] = {
        enableSection: false,
        range: [0, video.duration || 100],
        startStr: '00:00',
        endStr: formatDuration(video.duration || 100)
      }
    }

    await nextTick()
    const el = document.getElementById(`playlist-item-${index}`)
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }
}

const onPlaylistSectionToggle = async (index, val) => {
  if (val) {
    await nextTick()
    const el = document.getElementById(`playlist-item-${index}`)
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }
}

const onPlaylistSliderChange = (index, newRange) => {
  const crop = playlistCropRanges.value[index]
  if (!crop) return
  
  const oldRange = crop.range
  let seekTarget = newRange[0]
  if (oldRange && oldRange.length === 2) {
    if (newRange[0] !== oldRange[0]) {
      seekTarget = newRange[0]
    } else if (newRange[1] !== oldRange[1]) {
      seekTarget = newRange[1]
    }
  }
  
  const iframe = document.getElementById('yt-player-iframe')
  if (iframe && iframe.contentWindow) {
    iframe.contentWindow.postMessage(JSON.stringify({
      event: 'command',
      func: 'seekTo',
      args: [seekTarget, true]
    }), '*')
  }
  
  crop.range = newRange
  crop.startStr = formatDuration(newRange[0])
  crop.endStr = formatDuration(newRange[1])
}

const onPlaylistInputChange = (index) => {
  const crop = playlistCropRanges.value[index]
  if (!crop) return
  const video = playlistVideos.value[index - 1]
  const dur = video.duration || 100
  
  const startSec = parseTimeToSeconds(crop.startStr)
  const endSec = parseTimeToSeconds(crop.endStr)
  
  const newStart = Math.max(0, Math.min(startSec, dur))
  const newEnd = Math.max(newStart, Math.min(endSec, dur))
  
  crop.range = [newStart, newEnd]
  crop.startStr = formatDuration(newStart)
  crop.endStr = formatDuration(newEnd)
  
  const iframe = document.getElementById('yt-player-iframe')
  if (iframe && iframe.contentWindow) {
    iframe.contentWindow.postMessage(JSON.stringify({
      event: 'command',
      func: 'seekTo',
      args: [newStart, true]
    }), '*')
  }
}

const resetVideoState = () => {
  videoDuration.value = 0
  videoTitle.value = ''
  enableSection.value = false
}

watch(downloadUrl, (newUrl) => {
  if (newUrl) {
    const hasPlaylist = newUrl.includes('list=') || newUrl.includes('/playlist')
    if (hasPlaylist) {
      if (isPlaylist.value === true) {
        if (fetchInfoTimeout) clearTimeout(fetchInfoTimeout)
        fetchInfoTimeout = setTimeout(() => {
          fetchPlaylistInfo()
        }, 1000)
      } else {
        isPlaylist.value = true
      }
    } else {
      if (isPlaylist.value === false) {
        if (fetchInfoTimeout) clearTimeout(fetchInfoTimeout)
        fetchInfoTimeout = setTimeout(() => {
          fetchVideoInfo()
        }, 1000)
      } else {
        isPlaylist.value = false
      }
    }
  } else {
    resetPlaylistState()
    resetVideoState()
    if (fetchInfoTimeout) clearTimeout(fetchInfoTimeout)
  }
})

watch(isPlaylist, (newVal) => {
  if (!downloadUrl.value) return
  if (newVal) {
    resetVideoState()
    if (fetchInfoTimeout) clearTimeout(fetchInfoTimeout)
    fetchInfoTimeout = setTimeout(() => {
      fetchPlaylistInfo()
    }, 500)
  } else {
    resetPlaylistState()
    if (fetchInfoTimeout) clearTimeout(fetchInfoTimeout)
    fetchInfoTimeout = setTimeout(() => {
      fetchVideoInfo()
    }, 500)
  }
})

watch(sectionRange, (newRange, oldRange) => {
  startStr.value = formatDuration(newRange[0])
  endStr.value = formatDuration(newRange[1])
  
  const iframe = document.getElementById('yt-player-iframe')
  if (iframe && iframe.contentWindow) {
    try {
      let seekTarget = newRange[0]
      if (oldRange && oldRange.length === 2) {
        if (newRange[0] !== oldRange[0]) {
          seekTarget = newRange[0]
        } else if (newRange[1] !== oldRange[1]) {
          seekTarget = newRange[1]
        }
      }
      
      iframe.contentWindow.postMessage(JSON.stringify({
        event: 'command',
        func: 'seekTo',
        args: [seekTarget, true]
      }), '*')
    } catch (e) {
      console.error("Seek postMessage error:", e)
    }
  }
}, { immediate: true, deep: true })

const consoleBox = ref(null)
const pageContainer = ref(null)

watch(logMessages, () => {
  if (consoleBox.value) {
    nextTick(() => {
      consoleBox.value.scrollTop = consoleBox.value.scrollHeight
    })
  }
}, { deep: true })

// Download Progress & Info State
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

// Media Converter / Editor State
const mediaPath = ref('')
const editAction = ref('convert') // 'metadata' | 'convert'
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
  window.setInitialDir = (path) => {
    outputDir.value = path
    editOutputDir.value = path
  }

  if (window.initialDir) {
    window.setInitialDir(window.initialDir)
  }

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

  window.onFileSelected = (path, type) => {
    if (type === 'media') {
      mediaPath.value = path
      // Extract filename without path and extension as default Title tag
      const parts = path.split('\\')
      const fileNameWithExt = parts[parts.length - 1]
      const extIdx = fileNameWithExt.lastIndexOf('.')
      const fileName = extIdx !== -1 ? fileNameWithExt.substring(0, extIdx) : fileNameWithExt
      metaTitle.value = fileName
    } else {
      coverPath.value = path
    }
  }

  window.onDownloadProgress = (percentage, size, speed, eta) => {
    downloadState.value.percent = Math.floor(parseFloat(percentage)) || 0
    downloadState.value.totalSize = size || 'Connecting...'
    downloadState.value.speed = speed || '--'
    downloadState.value.eta = eta || '--'
  }

  window.onDownloadComplete = (pathsStr = '') => {
    // Process next queue item
    if (downloadQueue.value.length > 0) {
      downloadQueue.value.shift()
    }
    
    if (downloadQueue.value.length > 0) {
      runNextQueueItem()
    } else {
      isQueueDownloading.value = false
      stopDownloadTimer()
      downloadState.value.active = false
      downloadState.value.percent = 100
      downloadState.value.status = 'Download complete!'
      
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
  }

  window.onDownloadError = (message) => {
    downloadQueue.value = []
    isQueueDownloading.value = false
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

  window.onVideoInfoSuccess = async (title, durationStr) => {
    isLoadingInfo.value = false
    const dur = Math.floor(parseFloat(durationStr)) || 0
    videoTitle.value = title
    videoDuration.value = dur
    sectionRange.value = [0, dur]

    await nextTick()
    const card = document.getElementById('video-info-card')
    if (card) {
      card.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  window.onVideoInfoError = (err) => {
    isLoadingInfo.value = false
    console.error("Failed to fetch video details:", err)
    videoDuration.value = 0
    videoTitle.value = ''
  }

  window.onPlaylistInfoSuccess = async (videos) => {
    isPlaylistLoading.value = false
    playlistVideos.value = videos
    visiblePlaylistCount.value = Math.min(30, videos.length)
    selectedPlaylistIndices.value = videos.map((_, i) => i + 1)
    selectAllPlaylist.value = true

    await nextTick()
    const card = document.getElementById('playlist-videos-card')
    if (card) {
      card.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  }

  window.onPlaylistInfoError = (err) => {
    isPlaylistLoading.value = false
    showNotification('Playlist Error', err, 'error')
    playlistVideos.value = []
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

  if (pageContainer.value) {
    pageContainer.value.scrollTo({ top: 0, behavior: 'smooth' })
  }

  downloadQueue.value = []
  isQueueDownloading.value = true

  if (!isPlaylist.value) {
    const task = {
      url: downloadUrl.value,
      format: downloadFormat.value,
      audioFormat: audioFormat.value,
      videoFormat: videoFormat.value,
      isPlaylist: false,
      enableSection: enableSection.value,
      sectionRange: sectionRange.value,
      rules: rules.value,
      outputDir: outputDir.value,
      embedThumbnail: embedThumbnail.value,
      addMetadata: addMetadata.value
    }
    downloadQueue.value.push(task)
  } else {
    const nonCroppedIndices = []
    const croppedTasks = []

    selectedPlaylistIndices.value.forEach(idx => {
      const video = playlistVideos.value[idx - 1]
      const crop = playlistCropRanges.value[idx]

      if (crop && crop.enableSection) {
        croppedTasks.push({
          url: `https://www.youtube.com/watch?v=${video.id}`,
          format: downloadFormat.value,
          audioFormat: audioFormat.value,
          videoFormat: videoFormat.value,
          isPlaylist: false,
          enableSection: true,
          sectionRange: crop.range,
          rules: rules.value,
          outputDir: outputDir.value,
          embedThumbnail: embedThumbnail.value,
          addMetadata: addMetadata.value,
          batchLabel: `Item ${idx}: ${video.title}`
        })
      } else {
        nonCroppedIndices.push(idx)
      }
    })

    if (nonCroppedIndices.length > 0) {
      downloadQueue.value.push({
        url: downloadUrl.value,
        format: downloadFormat.value,
        audioFormat: audioFormat.value,
        videoFormat: videoFormat.value,
        isPlaylist: true,
        playlistAll: false,
        playlistItems: nonCroppedIndices.sort((a, b) => a - b).join(','),
        enableSection: false,
        rules: rules.value,
        outputDir: outputDir.value,
        embedThumbnail: embedThumbnail.value,
        addMetadata: addMetadata.value,
        batchLabel: `Playlist Items [${nonCroppedIndices.join(', ')}]`
      })
    }

    croppedTasks.forEach(task => {
      downloadQueue.value.push(task)
    })
  }

  if (downloadQueue.value.length === 0) {
    isQueueDownloading.value = false
    showNotification('No Items Selected', 'Please select at least one playlist item to download.', 'warning')
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

  runNextQueueItem()
}

const runNextQueueItem = () => {
  if (downloadQueue.value.length === 0) {
    isQueueDownloading.value = false
    stopDownloadTimer()
    downloadState.value.active = false
    return
  }

  const config = downloadQueue.value[0]
  if (config.batchLabel) {
    downloadState.value.status = `Downloading: ${config.batchLabel}`
  } else {
    downloadState.value.status = 'Initializing yt-dlp...'
  }

  if (window.chrome?.webview?.hostObjects) {
    window.chrome.webview.hostObjects.startDownload(JSON.stringify(config))
  } else {
    // Mock for browser
    setTimeout(() => {
      window.onDownloadProgress(100, '15.4MiB', '4.2MiB/s', '00:03')
      setTimeout(() => {
        window.onDownloadComplete()
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
    action: editAction.value,
    mediaPath: mediaPath.value,
    convertFormat: convertFormat.value,
    metaTitle: metaTitle.value,
    metaArtist: metaArtist.value,
    metaAlbum: metaAlbum.value,
    metaYear: metaYear.value,
    metaGenre: metaGenre.value,
    coverPath: coverPath.value,
    outputDir: editOutputDir.value,
    rules: rules.value
  }

  if (window.chrome?.webview?.hostObjects) {
    window.chrome.webview.hostObjects.triggerFFmpeg(JSON.stringify(config))
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

    <!-- Tab Contents (Scrollable Pane) -->
    <div ref="pageContainer" class="grow overflow-y-auto p-6">
      <div class="max-w-6xl mx-auto">
        
        <div v-if="activeTab === 'download' || activeTab === 'editor'" class="flex flex-col gap-6">
          
          <!-- Left Column: Inputs & Controls -->
          <div class="space-y-6 w-full">
            <!-- DOWNLOAD TAB -->
            <div v-if="activeTab === 'download'" class="space-y-6 animate-fadeIn">
              <!-- Controls -->
              <DownloadControls
                v-model:downloadUrl="downloadUrl"
                v-model:downloadFormat="downloadFormat"
                v-model:audioFormat="audioFormat"
                v-model:videoFormat="videoFormat"
                v-model:isPlaylist="isPlaylist"
                v-model:outputDir="outputDir"
                v-model:embedThumbnail="embedThumbnail"
                v-model:addMetadata="addMetadata"
                :downloadActive="downloadState.active"
                @select-directory="selectDirectory"
                @trigger-download="triggerDownload"
              />

              <!-- Single Video Card -->
              <SingleVideoCard
                v-if="!isPlaylist && (isLoadingInfo || videoTitle)"
                v-model:enableSection="enableSection"
                v-model:sectionRange="sectionRange"
                v-model:startStr="startStr"
                v-model:endStr="endStr"
                :isLoadingInfo="isLoadingInfo"
                :videoTitle="videoTitle"
                :videoDuration="videoDuration"
                :youtubeId="youtubeId"
                :embedUrl="embedUrl"
                :downloadActive="downloadState.active"
                :formatDuration="formatDuration"
                @update-range="updateRangeFromInputs"
              />

              <!-- Playlist Card -->
              <PlaylistCard
                v-if="isPlaylist && (isPlaylistLoading || playlistVideos.length > 0)"
                :isPlaylistLoading="isPlaylistLoading"
                :playlistVideos="playlistVideos"
                :visiblePlaylistVideos="visiblePlaylistVideos"
                :selectedPlaylistIndices="selectedPlaylistIndices"
                :selectAllPlaylist="selectAllPlaylist"
                :expandedPlaylistIndex="expandedPlaylistIndex"
                :playlistCropRanges="playlistCropRanges"
                :downloadActive="downloadState.active"
                :formatDuration="formatDuration"
                @toggle-select-all="toggleSelectAllPlaylist"
                @toggle-playlist-item="togglePlaylistItem"
                @toggle-expand-video="toggleExpandVideo"
                @on-playlist-scroll="onPlaylistScroll"
                @on-slider-change="onPlaylistSliderChange"
                @on-input-change="onPlaylistInputChange"
                @on-section-toggle="onPlaylistSectionToggle"
              />
            </div>

            <!-- METADATA EDITOR TAB -->
            <MetadataEditor
              v-if="activeTab === 'editor'"
              v-model:editAction="editAction"
              v-model:convertFormat="convertFormat"
              v-model:metaTitle="metaTitle"
              v-model:metaArtist="metaArtist"
              v-model:metaAlbum="metaAlbum"
              v-model:metaYear="metaYear"
              v-model:metaGenre="metaGenre"
              :mediaPath="mediaPath"
              :coverPath="coverPath"
              :editOutputDir="editOutputDir"
              :processState="processState"
              @select-file="selectFile"
              @select-directory="selectDirectory"
              @trigger-process="triggerProcess"
            />
          </div>

          <!-- Right Column: Output Console & Progress -->
          <ConsolePanel
            :downloadState="downloadState"
            :processState="processState"
            :isPlaylist="isPlaylist"
            :playlistIndex="playlistIndex"
            :playlistTotal="playlistTotal"
            :downloadTimeStr="downloadTimeStr"
            :logMessages="logMessages"
            :isQueueDownloading="isQueueDownloading"
            :downloadQueue="downloadQueue"
            @clear-log="logMessages = []"
          />
        </div>

        <!-- RENAMING RULES TAB -->
        <RulesManager
          v-else-if="activeTab === 'rules'"
          :rules="rules"
          @add-rule="addRule"
          @remove-rule="removeRule"
          @reset-rules="resetRules"
          @save-rules="saveRules"
        />

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

/* Playlist Scrollbar Styles */
.playlist-scroll-container::-webkit-scrollbar {
  width: 16px;
  height: 16px;
}
.playlist-scroll-container::-webkit-scrollbar-track {
  background: var(--color-neutral-950);
}
.playlist-scroll-container::-webkit-scrollbar-thumb {
  background: var(--color-neutral-800);
  border-radius: 8px;
  border: 4px solid var(--color-neutral-950);
}
.playlist-scroll-container::-webkit-scrollbar-thumb:hover {
  background: var(--color-neutral-700);
}
</style>
