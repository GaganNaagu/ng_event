<script lang="ts">
  import { fetchNui } from '$lib/utils/fetchNui';
  function toggleEvent() {
    fetchNui('toggleEventLevel', { level: 3 });
  }
</script>

<div class="w-full h-full text-white">
  <div class="pb-6 border-b border-[#333] mb-6">
    <h2 class="text-2xl font-black uppercase tracking-wider">Event Management</h2>
  </div>

  <div class="grid grid-cols-2 gap-4">
    <!-- Active Levels -->
    <div class="bg-[#222] p-6 rounded-lg border border-[#333]">
      <h3 class="text-[#888] uppercase tracking-[0.2em] text-[10px] font-black mb-4">Level 3 Guardian Zone</h3>
      <div class="flex gap-4 items-center">
        <div class="h-10 w-10 shrink-0 rounded-full bg-[#111] border border-[#333] flex items-center justify-center text-danger text-lg">🛡️</div>
        <div class="flex-1 text-xs text-gray-400 font-medium">
          Control the status of the Guardian zone manually. Toggle active state or force reset.
        </div>
      </div>
      <div class="mt-8">
        <button 
          onclick={toggleEvent}
          class="w-full py-3 bg-indigo-600 text-white text-xs font-black uppercase tracking-widest rounded-lg hover:bg-indigo-700 transition-all border border-indigo-500 shadow-lg active:translate-y-0.5">
          Toggle Level 3
        </button>
      </div>
    </div>

    <!-- Future Configuration -->
    <div class="bg-[#222] p-6 rounded-lg border border-[#333] border-dashed">
      <h3 class="text-[#555] uppercase tracking-[0.2em] text-[10px] font-black mb-4">Configuration (LOCKED)</h3>
      <p class="text-[#444] text-xs font-medium italic mt-4 text-center">Global event parameters under encryption.</p>
    </div>
  </div>
</div>
