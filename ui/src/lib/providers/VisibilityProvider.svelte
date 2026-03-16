<script lang="ts" module>
	let _visibility = $state(false);

	export let store = {
		set visibility(value: boolean) {
			_visibility = value;
		},
		get visibility() {
			return _visibility;
		},
	};

	useNuiEvent<boolean>(
		"setVisible",
		(visible) => {
			store.visibility = visible;
		},
		{ data: true },
	);
</script>

<script lang="ts">
	import { useNuiEvent } from "$lib/utils/useNuiEvent";
	import { fetchNui } from "$lib/utils/fetchNui";
	import { onMount, type Snippet } from "svelte";

	let { children } = $props();
	onMount(() => {
		const keyHandler = (e: KeyboardEvent) => {
			if (store.visibility && ["Escape"].includes(e.code)) {
				fetchNui("hideUI");
				store.visibility = false;
			}
		};

		window.addEventListener("keydown", keyHandler);

		return () => window.removeEventListener("keydown", keyHandler);
	});
</script>

{#if _visibility}
	{@render children()}
{/if}
