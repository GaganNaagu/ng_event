<script lang="ts">
  import { uiState } from '$lib/stores/uiState.svelte';
  import { fade, fly } from 'svelte/transition';

  const hudData = $derived(uiState.hudData);
  const active = $derived(uiState.hudActive);
  const pos = $derived(uiState.hudPosition);

  const posClasses = $derived({
    'top-center': 'top-4 left-1/2 -translate-x-1/2',
    'top-left': 'top-4 left-4',
    'top-right': 'top-4 right-4',
    'bottom-center': 'bottom-4 left-1/2 -translate-x-1/2',
    'bottom-left': 'bottom-4 left-4',
    'bottom-right': 'bottom-4 right-4',
    'center-left': 'top-1/2 left-4 -translate-y-1/2',
    'center-right': 'top-1/2 right-4 -translate-y-1/2'
  }[pos] || 'top-4 left-1/2 -translate-x-1/2');

  const isBottom = $derived(pos.startsWith('bottom'));
</script>

{#if active}
  <div 
    class="fixed {posClasses} z-50 pointer-events-none select-none flex {isBottom ? 'flex-col-reverse' : 'flex-col'} items-center gap-1.5"
    transition:fly={{ y: isBottom ? 20 : -20, duration: 400 }}
  >
    <!-- Minimal HUD Card -->
    <div class="bg-[#141414] border border-[#ff4d4d]/20 rounded-lg px-6 py-2 flex items-center gap-4 min-w-[240px] justify-center">
      <div class="text-[9px] uppercase tracking-[0.2em] text-[#ff4d4d] font-black border-r border-white/10 pr-4">Final Showdown</div>
      
      <div class="flex items-center gap-3">
        <span class="text-[9px] uppercase tracking-widest text-gray-500 font-bold">Clearance:</span>
        <span class="text-sm font-black text-white italic tracking-tighter">{hudData.lvlName || '---'}</span>
      </div>

      {#if hudData.lvlDescription}
        <div class="w-px h-3 bg-white/10 mx-1"></div>
        <div class="text-[9px] text-[#ff4d4d] font-black uppercase tracking-wider italic">
          {hudData.lvlDescription}
        </div>
      {/if}
    </div>

    <!-- Extra Info (Solid red background) -->
    {#if hudData.extraInfo}
      <div 
        class="bg-[#ff4d4d] rounded-md px-4 py-1"
        transition:fade
      >
        <div class="text-[9px] font-black text-black uppercase tracking-[0.15em] flex items-center gap-1.5">
           <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd" />
          </svg>
          {hudData.extraInfo}
        </div>
      </div>
    {/if}
  </div>
{/if}

<style>
  div {
    font-family: 'Inter', sans-serif;
  }
</style>
