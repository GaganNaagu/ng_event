<script lang="ts">
	import { uiState } from "$lib/stores/uiState.svelte";

	const cinematic = $derived(uiState.cinematic);
	let player: any = null;

	function loadYoutubeAPI() {
		if (window.YT) return;
		const tag = document.createElement("script");
		tag.src = "https://www.youtube.com/iframe_api";
		const firstScriptTag = document.getElementsByTagName("script")[0];
		firstScriptTag.parentNode?.insertBefore(tag, firstScriptTag);
	}

	window.onYouTubeIframeAPIReady = () => {
		console.log("YouTube API Ready");
	};

	$effect(() => {
		if (cinematic.show && cinematic.url) {
			loadYoutubeAPI();
			initPlayer();
		} else {
			if (player) {
				player.destroy();
				player = null;
			}
		}
	});

	function initPlayer() {
		if (!window.YT || !window.YT.Player) {
			setTimeout(initPlayer, 100);
			return;
		}

		let videoId = "";
		const url = cinematic.url;
		if (url.includes("v=")) {
			videoId = url.split("v=")[1].split("&")[0];
		} else if (url.includes("youtu.be/")) {
			videoId = url.split("youtu.be/")[1].split("?")[0];
		}

		if (!videoId) return;

		player = new window.YT.Player("music-player", {
			height: "0",
			width: "0",
			videoId: videoId,
			playerVars: {
				autoplay: 1,
				controls: 0,
				modestbranding: 1,
				loop: cinematic.loop ? 1 : 0,
				playlist: videoId,
			},
			events: {
				onReady: (event: any) => {
					console.log("Player Ready");
					event.target.setVolume(cinematic.volume * 100);
					const duration = event.target.getDuration();
					if (duration > 0) {
						fetch(
							`https://${GetParentResourceName()}/onDurationDetected`,
							{
								method: "POST",
								body: JSON.stringify({
									duration: duration * 1000,
								}),
							},
						);
					}
				},
				onStateChange: (event: any) => {
					if (
						event.data === window.YT.PlayerState.ENDED &&
						cinematic.loop
					) {
						event.target.playVideo(); // Loop if configured
					}
				},
			},
		});
	}

	function setVolume(val: number) {
		uiState.cinematic.volume = val;
		uiState.cinematic.muted = val === 0;

		if (player && player.setVolume) {
			player.setVolume(val * 100);
		}
	}

	function toggleMute() {
		uiState.cinematic.muted = !uiState.cinematic.muted;
		if (player && player.setVolume) {
			player.setVolume(
				uiState.cinematic.muted ? 0 : uiState.cinematic.volume * 100,
			);
		}
	}

	const displayVolume = $derived(cinematic.muted ? 0 : cinematic.volume);

	// Convert YouTube URL to Embed URL if needed
	const embedURL = $derived(() => {
		if (!cinematic.url) return "";
		let url = cinematic.url;
		const params =
			"autoplay=1&controls=0&modestbranding=1&loop=1&enablejsapi=1";
		if (url.includes("youtube.com/watch?v=")) {
			const id = url.split("v=")[1].split("&")[0];
			url = `https://www.youtube.com/embed/${id}?${params}&playlist=${id}`;
		} else if (url.includes("youtu.be/")) {
			const id = url.split("youtu.be/")[1].split("?")[0];
			url = `https://www.youtube.com/embed/${id}?${params}&playlist=${id}`;
		}
		return url;
	});
</script>

{#if cinematic.show}
	<div
		class="fixed inset-0 z-[9999] pointer-events-none flex flex-col justify-between overflow-hidden"
	>
		<!-- Top Bar -->
		<div
			class="w-full h-[10vh] bg-black shadow-[0_10px_30px_rgba(0,0,0,0.8)] transition-transform duration-1000"
			style="transform: translateY({cinematic.show ? '0' : '-100%'})"
		>
			<!-- Volume Controls (Top Right) -->
			<div
				class="absolute top-8 right-12 flex items-center gap-4 pointer-events-auto bg-black/60 backdrop-blur-md p-3 rounded-2xl border border-white/5 group"
			>
				<button
					onclick={toggleMute}
					class="text-white/60 hover:text-[#ff4d4d] transition-colors p-2"
				>
					{#if cinematic.muted || cinematic.volume === 0}
						<svg
							class="w-5 h-5"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
							><path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2.5"
								d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"
							/><path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2.5"
								d="M17 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2"
							/></svg
						>
					{:else if cinematic.volume < 0.5}
						<svg
							class="w-5 h-5"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
							><path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2.5"
								d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"
							/></svg
						>
					{:else}
						<svg
							class="w-5 h-5"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
							><path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2.5"
								d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z"
							/></svg
						>
					{/if}
				</button>
				<div class="flex flex-col gap-1 w-24">
					<div
						class="flex justify-between items-center text-[8px] font-black uppercase tracking-widest text-white/40"
					>
						<span>Music Volume</span>
						<span>{Math.round(displayVolume * 100)}%</span>
					</div>
					<input
						type="range"
						min="0"
						max="1"
						step="0.01"
						value={cinematic.volume}
						oninput={(e) =>
							setVolume(parseFloat(e.currentTarget.value))}
						class="w-full accent-[#ff4d4d] h-1 bg-white/5 rounded-full appearance-none cursor-pointer"
					/>
				</div>
			</div>
		</div>

		<!-- Hidden Music Player (Using YouTube API) -->
		<div
			id="music-player"
			class="fixed opacity-0 pointer-events-none -z-10"
		></div>

		<!-- Bottom Bar -->
		<div
			class="w-full h-[10vh] bg-black shadow-[0_-10px_30px_rgba(0,0,0,0.8)] transition-transform duration-1000 flex items-center justify-center"
			style="transform: translateY({cinematic.show ? '0' : '100%'})"
		>
			<div class="flex flex-col items-center gap-2">
				<h2
					class="text-[#ff4d4d] text-2xl font-black italic uppercase tracking-tighter animate-pulse"
				>
					Event Grand Finale
				</h2>
				<div class="w-48 h-1 bg-white/5 rounded-full overflow-hidden">
					<div
						class="h-full bg-[#ff4d4d] animate-[loading_30s_linear_infinite]"
					></div>
				</div>
			</div>
		</div>
	</div>
{/if}

<style>
	@keyframes loading {
		from {
			width: 0%;
		}
		to {
			width: 100%;
		}
	}
</style>
