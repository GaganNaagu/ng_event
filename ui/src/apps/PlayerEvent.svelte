<script lang="ts">
  import { uiState } from '$lib/stores/uiState.svelte';
  
  // Safe defaults via $derived
  let eventData = $derived(uiState.eventData || {});
  let guardiansLeft = $derived(eventData.guardiansLeft || 0);
  let totalGuardians = $derived(eventData.totalGuardians || 0);
  let isCleared = $derived(guardiansLeft === 0 && totalGuardians > 0);
</script>

<div class="relative w-full h-full text-white">
  <!-- Header -->
  <div class="pb-6 border-b border-[#333]">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-black uppercase tracking-wider text-danger">Level 3: Guardian's Ascent</h1>
        <p class="text-[10px] text-gray-500 mt-1 font-bold uppercase tracking-widest">High-Risk Secure Zone</p>
      </div>
    </div>
  </div>

  <!-- Content -->
  <div class="mt-6 space-y-6">
    <!-- Objective Card -->
    <div class="bg-[#222] p-5 rounded-lg border border-[#333] flex flex-col gap-3">
      <h2 class="text-xs font-bold text-gray-400 uppercase tracking-widest flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 text-indigo-500" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1.323l3.954 1.582 1.599-.8a1 1 0 01.894 1.79l-1.233.616 1.738 5.42a1 1 0 01-.285 1.05A3.989 3.989 0 0115 15a3.984 3.984 0 01-1.45-.266l-2.55 1.275a1 1 0 01-.894 0l-2.55-1.275A3.984 3.984 0 016 15c-1.103 0-2.103-.448-2.822-1.171a1 1 0 01-.285-1.05l1.738-5.42-1.233-.616a1 1 0 01.894-1.79l1.599.8L9 4.323V3a1 1 0 011-1zm-5 8.274l-.818 2.552c.25.112.526.174.818.174.292 0 .569-.062.818-.174L5 10.274zm10 0l-.818 2.552c.25.112.526.174.818.174.292 0 .569-.062.818-.174L15 10.274zm-5-3.082l-3.954-1.582L10 3.613l3.954 1.997L10 7.192z" clip-rule="evenodd" />
        </svg>
        Current Objective
      </h2>
      <p class="text-sm text-gray-400 leading-relaxed">
        You have entered the Guardian Zone. A highly secured stash rests in the center. To claim the Level 3 token, you must eliminate ALL guardians protecting the area.
      </p>
      
      {#if totalGuardians > 0}
        <div class="mt-4">
          <div class="flex justify-between text-[10px] font-black mb-2 tracking-widest uppercase">
            <span class={isCleared ? 'text-success' : 'text-danger'}>Guardians Remaining</span>
            <span class="text-white bg-[#111] px-2 py-0.5 rounded border border-[#333]">{guardiansLeft} / {totalGuardians}</span>
          </div>
          <div class="w-full bg-[#111] rounded-full h-2 overflow-hidden border border-[#333] relative">
            <div 
              class={`h-full rounded-full transition-all duration-1000 ${isCleared ? 'bg-success' : 'bg-danger'}`} 
              style="width: {(1 - (guardiansLeft / totalGuardians)) * 100}%"
            ></div>
          </div>
        </div>
      {:else}
        <div class="mt-2 text-center p-3 bg-[#111] rounded-lg text-xs border border-[#333] animate-pulse text-amber-500 font-bold tracking-widest uppercase">
          Awaiting target acquisition...
        </div>
      {/if}
    </div>

    <!-- Stats -->
    <div class="grid grid-cols-2 gap-4">
      <div class="bg-[#222] p-4 rounded-lg border border-[#333]">
        <h3 class="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Status</h3>
        {#if isCleared}
           <p class="text-success font-black text-lg uppercase tracking-tight">Area Secured</p>
        {:else}
           <p class="text-danger font-black text-lg uppercase tracking-tight">Hostile Activity</p>
        {/if}
      </div>
      <div class="bg-[#222] p-4 rounded-lg border border-[#333]">
        <h3 class="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-1">Loot Validation</h3>
        <p class="text-indigo-500 font-black text-lg uppercase tracking-tight">Secure Auth</p>
      </div>
    </div>
  </div>
</div>
