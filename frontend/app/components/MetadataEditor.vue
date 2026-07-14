<script setup>
defineProps({
  mediaPath: {
    type: String,
    required: true
  },
  editAction: {
    type: String,
    required: true
  },
  convertFormat: {
    type: String,
    required: true
  },
  metaTitle: {
    type: String,
    required: true
  },
  metaArtist: {
    type: String,
    required: true
  },
  metaAlbum: {
    type: String,
    required: true
  },
  metaYear: {
    type: String,
    required: true
  },
  metaGenre: {
    type: String,
    required: true
  },
  coverPath: {
    type: String,
    required: true
  },
  editOutputDir: {
    type: String,
    required: true
  },
  processState: {
    type: Object,
    required: true
  }
})

defineEmits([
  'update:editAction',
  'update:convertFormat',
  'update:metaTitle',
  'update:metaArtist',
  'update:metaAlbum',
  'update:metaYear',
  'update:metaGenre',
  'select-file',
  'select-directory',
  'trigger-process'
])
</script>

<template>
  <div class="space-y-6 animate-fadeIn">
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
            :model-value="mediaPath"
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
            @click="$emit('select-file', 'media')"
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
            @click="$emit('update:editAction', 'metadata')"
          >
            Edit Metadata Only
          </UButton>
          <UButton
            class="flex-1 justify-center py-2.5"
            :color="editAction === 'convert' ? 'primary' : 'neutral'"
            :variant="editAction === 'convert' ? 'solid' : 'outline'"
            icon="i-lucide-refresh-cw"
            :disabled="processState.active"
            @click="$emit('update:editAction', 'convert')"
          >
            Convert & Edit
          </UButton>
        </div>
      </div>

      <!-- Format Choice (visible only when converting) -->
      <div v-if="editAction === 'convert'" class="space-y-2 animate-fadeIn">
        <label class="text-xs font-semibold text-neutral-400">Target Output Format</label>
        <USelect
          :model-value="convertFormat"
          @update:model-value="val => $emit('update:convertFormat', val)"
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
            <UInput
              :model-value="metaTitle"
              @update:model-value="val => $emit('update:metaTitle', val)"
              placeholder="Song/Video Title"
              size="md"
              :disabled="processState.active"
            />
          </div>
          <div class="space-y-1.5">
            <label class="text-[11px] text-neutral-400">Artist / Channel</label>
            <UInput
              :model-value="metaArtist"
              @update:model-value="val => $emit('update:metaArtist', val)"
              placeholder="Artist Name"
              size="md"
              :disabled="processState.active"
            />
          </div>
          <div class="space-y-1.5">
            <label class="text-[11px] text-neutral-400">Album</label>
            <UInput
              :model-value="metaAlbum"
              @update:model-value="val => $emit('update:metaAlbum', val)"
              placeholder="Album Name"
              size="md"
              :disabled="processState.active"
            />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div class="space-y-1.5">
              <label class="text-[11px] text-neutral-400">Year</label>
              <UInput
                :model-value="metaYear"
                @update:model-value="val => $emit('update:metaYear', val)"
                placeholder="e.g. 2026"
                size="md"
                :disabled="processState.active"
              />
            </div>
            <div class="space-y-1.5">
              <label class="text-[11px] text-neutral-400">Genre</label>
              <UInput
                :model-value="metaGenre"
                @update:model-value="val => $emit('update:metaGenre', val)"
                placeholder="e.g. Rock"
                size="md"
                :disabled="processState.active"
              />
            </div>
          </div>
        </div>

        <!-- Cover Art Selector -->
        <div class="space-y-1.5 pt-2">
          <label class="text-[11px] text-neutral-400">Attach Custom Cover Image (Album Art)</label>
          <div class="flex gap-2">
            <UInput
              :model-value="coverPath"
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
              @click="$emit('select-file', 'cover')"
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
            :model-value="editOutputDir"
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
            @click="$emit('select-directory')"
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
        @click="$emit('trigger-process')"
      >
        Apply Changes
      </UButton>
    </div>
  </div>
</template>
