<script setup>
import { ref, watch, nextTick } from 'vue'

const props = defineProps({
  downloadState: {
    type: Object,
    required: true
  },
  processState: {
    type: Object,
    required: true
  },
  isPlaylist: {
    type: Boolean,
    required: true
  },
  playlistIndex: {
    type: Number,
    required: true
  },
  playlistTotal: {
    type: Number,
    required: true
  },
  downloadTimeStr: {
    type: String,
    required: true
  },
  logMessages: {
    type: Array,
    required: true
  },
  isQueueDownloading: {
    type: Boolean,
    required: true
  },
  downloadQueue: {
    type: Array,
    required: true
  }
})

const emit = defineEmits(['clear-log'])

const consoleBox = ref(null)

watch(() => props.logMessages, () => {
  if (consoleBox.value) {
    nextTick(() => {
      consoleBox.value.scrollTop = consoleBox.value.scrollHeight
    })
  }
}, { deep: true })
</script>

<template>
  <!-- Right Column: Output Console & Download Info -->
  <div class="space-y-4 w-full order-first">
    <!-- Console Box -->
    <div class="bg-neutral-950 border border-neutral-800 rounded-xl p-4 shadow-xl space-y-2 font-mono text-xs h-[180px] flex flex-col">
      <div class="flex justify-between items-center text-neutral-400 border-b border-neutral-800 pb-1.5 mb-2 shrink-0 border-transparent">
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
          @click="emit('clear-log')"
        >
          Clear Log
        </UButton>
      </div>
      <div ref="consoleBox" class="grow overflow-y-auto space-y-1 playlist-scroll-container">
        <div v-for="(line, idx) in logMessages" :key="idx" class="whitespace-pre-wrap leading-relaxed select-text font-mono text-left">
          {{ line }}
        </div>
        <!-- Idle Placeholder -->
        <div v-if="logMessages.length === 0" class="text-neutral-500 text-center py-10 select-none">
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

      <!-- Batch Download Progress Indicator -->
      <div v-if="isQueueDownloading && downloadQueue.length > 0" class="text-[10px] font-semibold text-neutral-300 bg-neutral-950 p-2 rounded border border-neutral-800 flex justify-between items-center">
        <span class="text-neutral-500 uppercase tracking-wider text-[8px] font-bold">Batch Job:</span>
        <span class="truncate ml-2 max-w-[200px]" :title="downloadQueue[0].batchLabel">{{ downloadQueue[0].batchLabel }}</span>
      </div>

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
</template>
