<script lang="ts">
	import { fade } from "svelte/transition";

	let { text, position = "top", children } = $props();
	let isHovered = $state(false);

	const positionClasses: Record<string, string> = {
		top: "bottom-full left-1/2 -translate-x-1/2 mb-2",
		bottom: "top-full left-1/2 -translate-x-1/2 mt-2",
		left: "right-full top-1/2 -translate-y-1/2 mr-3",
		right: "left-full top-1/2 -translate-y-1/2 ml-3",
	};
</script>

<div
	class="relative inline-flex items-center"
	onmouseenter={() => (isHovered = true)}
	onmouseleave={() => (isHovered = false)}
	role="presentation"
>
	{@render children()}

	{#if isHovered}
		<div
			transition:fade={{ duration: 150 }}
			class="absolute z-50 px-3 py-1.5 bg-[#141414] border border-white/10 text-white text-[10px] font-black uppercase tracking-widest whitespace-nowrap rounded pointer-events-none {positionClasses[
				position
			]}"
		>
			{text}
			<!-- Triangle -->
			<div
				class="absolute w-2 h-2 bg-[#141414] border-r border-b border-white/10 rotate-45
        {position === 'top' ? 'top-full -mt-1 left-1/2 -ml-1' : ''}
        {position === 'bottom' ? 'bottom-full -mb-1 left-1/2 -ml-1' : ''}
        {position === 'left' ? 'left-full -ml-1 top-1/2 -mt-1' : ''}
        {position === 'right'
					? 'right-full -mr-1 top-1/2 -mt-1 shadow-none'
					: ''}"
			></div>
		</div>
	{/if}
</div>
