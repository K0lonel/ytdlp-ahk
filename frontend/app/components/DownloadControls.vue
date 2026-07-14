<script setup>
defineProps({
  downloadUrl: {
    type: String,
    required: true
  },
  downloadFormat: {
    type: String,
    required: true
  },
  audioFormat: {
    type: String,
    required: true
  },
  videoFormat: {
    type: String,
    required: true
  },
  isPlaylist: {
    type: Boolean,
    required: true
  },
  outputDir: {
    type: String,
    required: true
  },
  embedThumbnail: {
    type: Boolean,
    required: true
  },
  addMetadata: {
    type: Boolean,
    required: true
  },
  downloadActive: {
    type: Boolean,
    required: true
  }
})

defineEmits([
  'update:downloadUrl',
  'update:downloadFormat',
  'update:audioFormat',
  'update:videoFormat',
  'update:isPlaylist',
  'update:embedThumbnail',
  'update:addMetadata',
  'select-directory',
  'trigger-download'
])
</script>

<template>
  <!-- Input URL Card -->
  <div class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-4">
    <div class="space-y-1.5">
      <div class="flex justify-between items-center">
        <label class="text-xs font-bold uppercase tracking-wider text-neutral-400">YouTube URL</label>
        <div class="flex items-center gap-3">
          <!-- Checkbox -->
          <UCheckbox
            :model-value="isPlaylist"
            @update:model-value="val => $emit('update:isPlaylist', val)"
            label="Playlist"
            :disabled="downloadActive"
          />
        </div>
      </div>
      <div class="flex gap-2">
        <UInput
          :model-value="downloadUrl"
          @update:model-value="val => $emit('update:downloadUrl', val)"
          placeholder="Paste YouTube video or playlist URL here..."
          class="grow font-mono"
          size="md"
          :disabled="downloadActive"
          icon="i-lucide-link"
        />
        <UButton
          color="primary"
          class="px-6 font-bold"
          :loading="downloadActive"
          @click="$emit('trigger-download')"
        >
          Start Download
        </UButton>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
      <!-- Format Options -->
      <div class="space-y-1.5">
        <label class="text-xs font-bold uppercase tracking-wider text-neutral-400 font-sans">Format & Codec</label>
        <div class="flex gap-2">
          <USelect
            :model-value="downloadFormat"
            @update:model-value="val => $emit('update:downloadFormat', val)"
            :items="[
              { label: 'Video (MP4/MKV/WEBM)', value: 'video' },
              { label: 'Audio Extract', value: 'audio' }
            ]"
            class="w-1/2"
            size="md"
            :disabled="downloadActive"
          />
          <USelect
            v-if="downloadFormat === 'audio'"
            :model-value="audioFormat"
            @update:model-value="val => $emit('update:audioFormat', val)"
            :items="['m4a', 'mp3', 'opus', 'wav']"
            class="w-1/2 font-mono"
            size="md"
            :disabled="downloadActive"
          />
          <USelect
            v-else
            :model-value="videoFormat"
            @update:model-value="val => $emit('update:videoFormat', val)"
            :items="['mp4', 'mkv', 'webm']"
            class="w-1/2 font-mono"
            size="md"
            :disabled="downloadActive"
          />
        </div>
      </div>

      <!-- Preferences -->
      <div class="space-y-1.5">
        <label class="text-xs font-bold uppercase tracking-wider text-neutral-400 font-sans">Preferences</label>
        <div class="flex gap-4 py-2">
          <UCheckbox
            :model-value="embedThumbnail"
            @update:model-value="val => $emit('update:embedThumbnail', val)"
            label="Embed Thumbnail"
            :disabled="downloadActive"
          />
          <UCheckbox
            :model-value="addMetadata"
            @update:model-value="val => $emit('update:addMetadata', val)"
            label="Add Metadata Tags"
            :disabled="downloadActive"
          />
        </div>
      </div>
    </div>

    <!-- Target Output Directory -->
    <div class="space-y-1.5">
      <label class="text-xs font-bold uppercase tracking-wider text-neutral-400 font-sans">Save Destination</label>
      <div class="flex gap-2">
        <UInput
          :model-value="outputDir"
          readonly
          placeholder="Select output folder..."
          class="grow"
          size="md"
          :disabled="downloadActive"
        />
        <UButton
          icon="i-lucide-folder"
          color="neutral"
          variant="subtle"
          class="px-4"
          :disabled="downloadActive"
          @click="$emit('select-directory')"
        >
          Browse
        </UButton>
      </div>
    </div>
  </div>
</template>
