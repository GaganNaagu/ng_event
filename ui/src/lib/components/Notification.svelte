<script lang="ts">
    import { uiState } from '$lib/stores/uiState.svelte';
    import { flip } from 'svelte/animate';
    import { fly } from 'svelte/transition';

    const notifications = $derived(uiState.notifications);
</script>

<div class="fixed top-24 right-6 z-[60] flex flex-col gap-3 pointer-events-none w-80">
    {#each notifications as notification (notification.id)}
        <div 
            animate:flip={{ duration: 400 }}
            transition:fly={{ x: 100, duration: 400 }}
            class="bg-[#141414] border-l-4 border-[#ff4d4d] p-4 rounded-r-lg shadow-none pointer-events-auto select-none"
        >
            <div class="flex items-start gap-3">
                <div class="mt-1">
                    {#if notification.type === 'error'}
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-red-500" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                        </svg>
                    {:else if notification.type === 'success'}
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-green-500" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
                        </svg>
                    {:else}
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-[#ff4d4d]" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
                        </svg>
                    {/if}
                </div>
                <div class="flex-1">
                    <h4 class="text-[10px] font-black uppercase tracking-[0.2em] text-[#ff4d4d] mb-0.5">{notification.title}</h4>
                    <p class="text-[11px] font-bold text-gray-300 leading-relaxed uppercase">{notification.description}</p>
                </div>
            </div>
        </div>
    {/each}
</div>

<style>
    div {
        font-family: 'Inter', sans-serif;
    }
</style>
