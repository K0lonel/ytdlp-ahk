<script setup>
defineProps({
  isPlaylistLoading: {
    type: Boolean,
    required: true
  },
  playlistVideos: {
    type: Array,
    required: true
  },
  visiblePlaylistVideos: {
    type: Array,
    required: true
  },
  selectedPlaylistIndices: {
    type: Array,
    required: true
  },
  selectAllPlaylist: {
    type: Boolean,
    required: true
  },
  expandedPlaylistIndex: {
    type: Number,
    required: false,
    default: null
  },
  playlistCropRanges: {
    type: Object,
    required: true
  },
  downloadActive: {
    type: Boolean,
    required: true
  },
  formatDuration: {
    type: Function,
    required: true
  }
})

defineEmits([
  'toggle-select-all',
  'toggle-playlist-item',
  'toggle-expand-video',
  'on-playlist-scroll',
  'on-slider-change',
  'on-input-change',
  'on-section-toggle'
])
</script>

<template>
  <!-- Playlist Videos List Card -->
  <div id="playlist-videos-card" class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-4 animate-fadeIn">
    <!-- Loader -->
    <div v-if="isPlaylistLoading" class="flex items-center gap-3 py-4 text-neutral-400 justify-center">
      <UIcon name="i-lucide-refresh-cw" class="w-5 h-5 animate-spin text-primary" />
      <span class="text-sm font-semibold">Loading playlist videos...</span>
    </div>

    <div v-else class="space-y-4">
      <!-- Header with Select All -->
      <div class="flex items-center justify-between border-b border-neutral-800 pb-3">
        <h3 class="text-xs font-bold uppercase tracking-widest text-neutral-400 flex items-center gap-2">
          <UIcon name="i-lucide-list" class="w-4 h-4 text-primary" /> Playlist Videos ({{ playlistVideos.length }})
        </h3>
        <UCheckbox
          :model-value="selectAllPlaylist"
          @update:model-value="val => $emit('toggle-select-all', val)"
          label="Select All"
          :disabled="downloadActive"
        />
      </div>

      <!-- Stripes List -->
      <div class="space-y-2 max-h-[700px] overflow-y-auto pr-1 playlist-scroll-container" @scroll="e => $emit('on-playlist-scroll', e)">
        <div
          v-for="(video, idx) in visiblePlaylistVideos"
          :key="video.id"
          :id="`playlist-item-${idx + 1}`"
          class="border border-neutral-800 rounded-lg overflow-hidden bg-neutral-950/40 transition-colors"
          :class="expandedPlaylistIndex === idx + 1 ? 'border-primary/50' : 'hover:bg-neutral-900/40'"
        >
          <!-- Main Stripe -->
          <div class="flex items-center gap-3 p-3 select-none">
            <!-- Checkbox -->
            <UCheckbox
              :model-value="selectedPlaylistIndices.includes(idx + 1)"
              @update:model-value="val => $emit('toggle-playlist-item', idx + 1, val)"
              :disabled="downloadActive"
            />

            <!-- Video Index -->
            <span class="text-xs font-mono font-bold text-neutral-500 w-5 text-right">{{ idx + 1 }}</span>

            <!-- Thumbnail (Duration Badge inside bottom-right) -->
            <div class="relative w-16 h-10 bg-neutral-900 rounded overflow-hidden border border-neutral-800 shrink-0">
              <img
                :src="video.thumbnail || (video.thumbnails && video.thumbnails[0] ? video.thumbnails[0].url : 'https://i.ytimg.com/vi/placeholder/hqdefault.jpg')"
                class="w-full h-full object-cover"
              />
              <span class="absolute bottom-0.5 right-0.5 bg-black/80 px-1 rounded text-[8px] font-bold text-neutral-200">
                <template v-if="playlistCropRanges[idx + 1]?.enableSection">
                  {{ playlistCropRanges[idx + 1].startStr }} - {{ playlistCropRanges[idx + 1].endStr }}
                </template>
                <template v-else>
                  {{ video.duration_string || formatDuration(video.duration) }}
                </template>
              </span>
            </div>

            <!-- Video Info -->
            <div class="grow min-w-0" @click="$emit('toggle-expand-video', idx + 1)">
              <h4 class="text-xs font-bold text-neutral-200 line-clamp-1 hover:text-primary cursor-pointer leading-snug text-left">
                {{ video.title }}
              </h4>
              <p class="text-[10px] text-neutral-400 mt-0.5 text-left">{{ video.uploader || 'Unknown Channel' }}</p>
            </div>

            <!-- Expand Chevron -->
            <UButton
              :icon="expandedPlaylistIndex === idx + 1 ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
              color="neutral"
              variant="ghost"
              size="xs"
              @click="$emit('toggle-expand-video', idx + 1)"
            />
          </div>

          <!-- Expanded Area (Player & Crop Details) -->
          <div v-if="expandedPlaylistIndex === idx + 1" class="border-t border-neutral-800 bg-neutral-950 p-4 space-y-4 animate-fadeIn">
            <!-- Video Player Iframe -->
            <div class="overflow-hidden rounded-lg border border-neutral-800 bg-neutral-950 aspect-video w-full max-w-xl mx-auto">
              <iframe
                id="yt-player-iframe"
                :src="`https://www.youtube.com/embed/${video.id}?enablejsapi=1`"
                class="w-full h-full border-0"
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
                allowfullscreen
              ></iframe>
            </div>

            <!-- Enable Section Toggle -->
            <div class="flex items-center justify-between p-3 bg-neutral-900 rounded-lg border border-neutral-800 max-w-xl mx-auto">
              <div>
                <h4 class="text-xs font-semibold text-left">Download Specific Section</h4>
                <p class="text-[10px] text-neutral-400 mt-0.5 text-left">Clip a specific time range from this video</p>
              </div>
              <USwitch
                v-model="playlistCropRanges[idx + 1].enableSection"
                :disabled="downloadActive"
                @update:model-value="val => $emit('on-section-toggle', idx + 1, val)"
              />
            </div>

            <!-- Range Slider & Inputs -->
            <div v-if="playlistCropRanges[idx + 1]?.enableSection" class="space-y-4 p-3 bg-neutral-900 rounded-lg border border-neutral-800 max-w-xl mx-auto animate-fadeIn">
              <div class="flex items-center justify-between text-xs text-neutral-400 font-semibold mb-1">
                <span>Crop Range</span>
                <span class="text-primary font-bold">
                  {{ playlistCropRanges[idx + 1].startStr }} - {{ playlistCropRanges[idx + 1].endStr }}
                </span>
              </div>

              <div class="px-2 py-1">
                <USlider
                  :model-value="playlistCropRanges[idx + 1].range"
                  @update:model-value="val => $emit('on-slider-change', idx + 1, val)"
                  :min="0"
                  :max="video.duration || 100"
                  :step="1"
                  :disabled="downloadActive"
                  color="primary"
                />
              </div>

              <!-- Time Inputs -->
              <div class="grid grid-cols-2 gap-3 pt-2">
                <div class="space-y-1">
                  <span class="text-[9px] uppercase font-bold text-neutral-400">Start Time</span>
                  <UInput
                    v-model="playlistCropRanges[idx + 1].startStr"
                    placeholder="00:00"
                    size="xs"
                    class="w-full font-mono text-center"
                    :disabled="downloadActive"
                    @blur="$emit('on-input-change', idx + 1)"
                    @keyup.enter="$emit('on-input-change', idx + 1)"
                  />
                </div>
                <div class="space-y-1">
                  <span class="text-[9px] uppercase font-bold text-neutral-400">End Time</span>
                  <UInput
                    v-model="playlistCropRanges[idx + 1].endStr"
                    placeholder="00:00"
                    size="xs"
                    class="w-full font-mono text-center"
                    :disabled="downloadActive"
                    @blur="$emit('on-input-change', idx + 1)"
                    @keyup.enter="$emit('on-input-change', idx + 1)"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
