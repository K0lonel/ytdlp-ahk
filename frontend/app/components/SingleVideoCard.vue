<script setup>
defineProps({
  isLoadingInfo: {
    type: Boolean,
    required: true
  },
  videoTitle: {
    type: String,
    required: true
  },
  videoDuration: {
    type: Number,
    required: true
  },
  youtubeId: {
    type: String,
    required: false,
    default: null
  },
  embedUrl: {
    type: String,
    required: false,
    default: null
  },
  enableSection: {
    type: Boolean,
    required: true
  },
  sectionRange: {
    type: Array,
    required: true
  },
  startStr: {
    type: String,
    required: true
  },
  endStr: {
    type: String,
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
  'update:enableSection',
  'update:sectionRange',
  'update:startStr',
  'update:endStr',
  'update-range'
])
</script>

<template>
  <!-- Video Info / Section Download Card -->
  <div id="video-info-card" class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-4 animate-fadeIn">
    <div v-if="isLoadingInfo" class="flex items-center gap-3 py-2 text-neutral-400">
      <UIcon name="i-lucide-refresh-cw" class="w-4 h-4 animate-spin text-primary" />
      <span class="text-xs font-semibold">Loading video details...</span>
    </div>
    
    <div v-else-if="videoTitle" class="space-y-4">
      <!-- Video Header / Details -->
      <div class="flex gap-3 items-start bg-neutral-950 p-3 rounded-lg border border-neutral-800 max-w-xl mx-auto">
        <UIcon name="i-lucide-youtube" class="w-6 h-6 text-red-500 shrink-0 mt-0.5" />
        <div class="space-y-0.5">
          <h4 class="text-xs font-bold text-neutral-200 line-clamp-2 leading-snug text-left">{{ videoTitle }}</h4>
          <p class="text-[10px] text-neutral-400 font-medium text-left">Duration: {{ formatDuration(videoDuration) }}</p>
        </div>
      </div>

      <!-- Video Preview Player Container -->
      <div v-show="youtubeId" class="overflow-hidden rounded-lg border border-neutral-800 bg-neutral-950 aspect-video w-full max-w-xl mx-auto">
        <iframe
          id="yt-player-iframe"
          :src="embedUrl"
          class="w-full h-full border-0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          allowfullscreen
        ></iframe>
      </div>

      <!-- Enable Section Toggle -->
      <div class="flex items-center justify-between p-3 bg-neutral-900 rounded-lg border border-neutral-800 max-w-xl mx-auto">
        <div>
          <h4 class="text-xs font-semibold text-left">Download Specific Section</h4>
          <p class="text-[10px] text-neutral-400 mt-0.5 text-left">Clip a specific time range from the video</p>
        </div>
        <USwitch
          :model-value="enableSection"
          @update:model-value="val => $emit('update:enableSection', val)"
          :disabled="downloadActive"
        />
      </div>

      <!-- Range Slider & Inputs -->
      <div v-if="enableSection" class="space-y-4 p-3 bg-neutral-900 rounded-lg border border-neutral-800 max-w-xl mx-auto animate-fadeIn">
        <div class="flex items-center justify-between text-xs text-neutral-400 font-semibold mb-1">
          <span>Crop Range</span>
          <span class="text-primary font-bold">{{ startStr }} - {{ endStr }}</span>
        </div>

        <!-- Slider from Nuxt UI -->
        <div class="px-2 py-1">
          <USlider
            :model-value="sectionRange"
            @update:model-value="val => $emit('update:sectionRange', val)"
            :min="0"
            :max="videoDuration"
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
              :model-value="startStr"
              @update:model-value="val => $emit('update:startStr', val)"
              placeholder="00:00"
              size="xs"
              class="w-full font-mono text-center"
              :disabled="downloadActive"
              @blur="$emit('update-range')"
              @keyup.enter="$emit('update-range')"
            />
          </div>
          <div class="space-y-1">
            <span class="text-[9px] uppercase font-bold text-neutral-400">End Time</span>
            <UInput
              :model-value="endStr"
              @update:model-value="val => $emit('update:endStr', val)"
              placeholder="00:00"
              size="xs"
              class="w-full font-mono text-center"
              :disabled="downloadActive"
              @blur="$emit('update-range')"
              @keyup.enter="$emit('update-range')"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
