<script lang="ts">
	import { onMount, setContext } from "svelte";
	import { uiState } from "$lib/stores/uiState.svelte";
	import { fetchNui } from "$lib/utils/fetchNui";
	import EventPanel from "./apps/EventPanel.svelte";
	import EventHUD from "./apps/EventHUD.svelte";
	import Notification from "./lib/components/Notification.svelte";
	import CinematicOverlay from "./lib/components/CinematicOverlay.svelte";
	import { Howl } from "howler";

	// Listen for messages from FiveM client
	onMount(() => {
		const messageListener = (event: MessageEvent) => {
			const data = event.data;
			if (data.action === "setupUI") {
				uiState.isVisible = data.visible;
				uiState.isAdmin = data.isAdmin || false;
				uiState.activeApp = data.app;
				uiState.hudPosition = data.hudPosition || "bottom-center";

				if (data.eventData) {
					uiState.eventData = data.eventData;
				}
			} else if (data.action === "updateUIData") {
				uiState.eventData = {
					eventActive: data.eventActive,
					eventHosting: data.eventHosting,
					playersList: data.playersList,
					playerOwnData: data.playerOwnData,
					liveWinners: data.liveWinners,
					history: data.history,
				};
			} else if (data.action === "updateHUD") {
				uiState.hudActive = data.visible;
				if (data.hudData) {
					uiState.hudData = {
						lvlName: data.hudData.lvlName || "",
						lvlDescription: data.hudData.lvlDescription || "",
						currentWinners: data.hudData.currentWinners || 0,
						maxWinners: data.hudData.maxWinners || 0,
						extraInfo: data.hudData.extraInfo,
					};
				}
				if (data.hudPosition) {
					uiState.hudPosition = data.hudPosition;
				}
			} else if (data.action === "playSound") {
				if (data.url) {
					const sound = new Howl({
						src: [data.url],
						volume: data.volume || 0.5,
						html5: true, // Use HTML5 audio to prevent CORS/memory issues
						onplayerror: function () {
							sound.once("unlock", function () {
								sound.play();
							});
						},
					});
					sound.play();
				}
			} else if (data.action === "showNotification") {
				const id = Date.now();
				const notification = {
					id,
					title: data.title || "Event Update",
					description: data.description || "",
					type: data.type || "inform",
				};

				uiState.notifications = [
					...uiState.notifications,
					notification,
				];

				// Sound is now handled exclusively by the 'playSound' action
				// called from the Lua bridge for better control over URLs/volume

				setTimeout(() => {
					uiState.notifications = uiState.notifications.filter(
						(n) => n.id !== id,
					);
				}, 5000);
			} else if (data.action === "showCinematic") {
				uiState.cinematic.show = true;
				uiState.cinematic.url = data.url || "";
			} else if (data.action === "hideCinematic") {
				uiState.cinematic.show = false;
				uiState.cinematic.url = "";
			}
		};

		window.addEventListener("message", messageListener);

		return () => {
			window.removeEventListener("message", messageListener);
		};
	});

	// Global Escape Listener
	$effect(() => {
		const handleKeyDown = (e: KeyboardEvent) => {
			if (e.key === "Escape" && uiState.isVisible) {
				fetchNui("hideUI")
					.then(() => {
						uiState.isVisible = false;
					})
					.catch(() => {
						uiState.isVisible = false;
					});
			}
		};

		window.addEventListener("keydown", handleKeyDown);
		return () => window.removeEventListener("keydown", handleKeyDown);
	});
</script>

{#if uiState.isVisible}
	<main class="w-screen h-screen flex items-center justify-center p-4">
		<EventPanel />
	</main>
{/if}

<EventHUD />
<Notification />
<CinematicOverlay />

<style>
	main {
		font-family: "Inter", ui-sans-serif, system-ui, sans-serif;
	}
</style>
