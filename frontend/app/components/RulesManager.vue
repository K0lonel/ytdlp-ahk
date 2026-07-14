<script setup>
defineProps({
  rules: {
    type: Array,
    required: true
  }
})

defineEmits(['add-rule', 'remove-rule', 'reset-rules', 'save-rules'])
</script>

<template>
  <div class="space-y-6 animate-fadeIn w-full">
    <div class="bg-neutral-900 border border-neutral-800 rounded-xl p-6 shadow-xl space-y-4">
      <div>
        <h3 class="text-sm font-bold uppercase tracking-widest text-neutral-400 flex items-center gap-2">
          <UIcon name="i-lucide-settings-2" class="w-4 h-4 text-primary" /> Filename Renaming Rules
        </h3>
        <p class="text-xs text-neutral-400 mt-1 leading-relaxed text-left">
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
                @change="$emit('save-rules')"
              />
            </div>
            <div class="space-y-1">
              <span class="text-[10px] text-neutral-500 font-bold uppercase">Replacement</span>
              <UInput
                v-model="rule.replacement"
                placeholder="Empty to remove"
                size="sm"
                class="font-mono w-full"
                @change="$emit('save-rules')"
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
              @click="$emit('remove-rule', idx)"
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
          @click="$emit('add-rule')"
        >
          Add Rule
        </UButton>
        <UButton
          icon="i-lucide-rotate-ccw"
          color="neutral"
          variant="ghost"
          size="sm"
          @click="$emit('reset-rules')"
        >
          Reset Defaults
        </UButton>
      </div>
    </div>
  </div>
</template>
