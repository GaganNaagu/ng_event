<script lang="ts">
	import { uiState } from "$lib/stores/uiState.svelte";
	import { fetchNui } from "$lib/utils/fetchNui";

	function closePanel() {
		fetchNui("hideUI");
		uiState.isVisible = false;
	}

	function clearZone() {
		fetchNui("adminAction", { action: "forceClearZone", level: 3 });
	}

	function spectatePlayer() {
		fetchNui("adminAction", { action: "spectate" });
	}
</script>

<div
	class="relative w-full max-w-4xl bg-surface/90 backdrop-blur-xl border border-danger/20 rounded-3xl shadow-2xl p-6 text-white text-sm"
>
	<div
		class="flex justify-between items-center mb-6 border-b border-danger/20 pb-4"
	>
		<div>
			<h2 class="text-2xl font-bold tracking-wide text-danger">
				Admin Dashboard
			</h2>
			<p class="text-xs text-danger/60 mt-1 uppercase tracking-widest">
				Restricted Access
			</p>
		</div>
		<button
			onclick={closePanel}
			class="text-gray-400 hover:text-white transition-colors"
			>Close</button
		>
	</div>

	<div class="grid grid-cols-3 gap-4">
		<div class="col-span-1 space-y-3">
			<button
				onclick={clearZone}
				class="w-full py-3 bg-danger/10 text-danger hover:bg-danger/20 rounded-xl font-bold border border-danger/20 transition-all"
			>
				Force Clear Zone
			</button>
			<button
				onclick={spectatePlayer}
				class="w-full py-3 bg-accent/10 text-accent hover:bg-accent/20 rounded-xl font-bold border border-accent/20 transition-all"
			>
				Spectate Active
			</button>
		</div>

		<div
			class="col-span-2 bg-black/50 p-4 rounded-xl border border-white/5 font-mono text-xs text-gray-400"
		>
			<p class="text-success mb-2">System connected.</p>
			<p>Awaiting live server logs...</p>
		</div>
	</div>
</div>
