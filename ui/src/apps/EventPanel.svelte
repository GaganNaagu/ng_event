<script lang="ts">
	import { uiState } from "$lib/stores/uiState.svelte";
	import { fetchNui } from "$lib/utils/fetchNui";
	import Tooltip from "../lib/components/Tooltip.svelte";

	const eventData = $derived(uiState.eventData);
	const playerOwnData = $derived(
		eventData.playerOwnData || { level: 1, tokens: [], inEvent: false },
	);
	const playersList = $derived(eventData.playersList || []);
	const liveWinners = $derived(eventData.liveWinners || []);
	const eventHistory = $derived(eventData.history || []);
	let selectedSession = $state<any>(null);

	let activeTab = $state("player");
	let adminSubTab = $state("current"); // 'current' | 'history'

	function closePanel() {
		fetchNui("hideUI").then(() => {
			uiState.isVisible = false;
		});
	}

	function handleAction(action: string, targetId?: number, extra?: any) {
		fetchNui("event:ui:action", { action, targetId, extra });
	}

	// Helper for winner slots (always show 3)
	const winnerSlots = $derived(() => {
		const slots = [];
		for (let i = 1; i <= 3; i++) {
			const winner = liveWinners.find((w) => w.place === i);
			slots.push(
				winner || {
					place: i,
					name: "Yet to be Decided",
					time: "Waiting...",
				},
			);
		}
		return slots;
	});

	// Sort players by finished status (place), then level and tokens for leaderboard
	const leaderboard = $derived(() => {
		return [...playersList].sort((a, b) => {
			if (a.finished && !b.finished) return -1;
			if (!a.finished && b.finished) return 1;
			if (a.finished && b.finished) {
				return (a.place || 999) - (b.place || 999);
			}
			if (b.level !== a.level) return (b.level || 0) - (a.level || 0);
			return (b.tokens || 0) - (a.tokens || 0);
		});
	});
</script>

<div
	class="w-full max-w-5xl h-[700px] flex flex-col bg-[#0d0d0d] border border-white/5 rounded-xl overflow-hidden scale-[1.02]"
>
	<!-- Header & Tabs -->
	<div
		class="flex items-center px-8 py-5 bg-[#141414] border-b border-white/5 justify-between"
	>
		<div class="flex items-center gap-12">
			<h1
				class="text-xl font-black italic tracking-tighter text-white uppercase"
			>
				Final <span class="text-[#ff4d4d]">Showdown</span>
			</h1>

			<nav class="flex gap-1 bg-black/40 p-1 rounded-xl">
				<button
					onclick={() => (activeTab = "player")}
					class="px-6 py-2 rounded-lg text-xs font-black uppercase tracking-widest transition-all {activeTab ===
					'player'
						? 'bg-[#333] text-white'
						: 'text-[#444] hover:text-[#666]'}"
				>
					Player Panel
				</button>
				{#if uiState.isAdmin}
					<button
						onclick={() => {
							activeTab = "admin";
							adminSubTab = "current";
						}}
						class="px-6 py-2 rounded-lg text-xs font-black uppercase tracking-widest transition-all {activeTab ===
						'admin'
							? 'bg-[#333] text-white'
							: 'text-[#444] hover:text-[#666]'}"
					>
						Management
					</button>
				{/if}
			</nav>
		</div>
		<div class="flex items-center gap-6">
			<div class="flex flex-col items-end pr-6 border-r border-white/5">
				<span
					class="text-[9px] font-black text-[#444] uppercase tracking-widest"
					>Server Time</span
				>
				<div
					class="text-sm font-black text-white italic tracking-tighter"
				>
					{new Date().toLocaleTimeString([], {
						hour: "2-digit",
						minute: "2-digit",
						second: "2-digit",
					})}
				</div>
			</div>
			<Tooltip text="Close Panel (ESC)" position="left">
				<button
					onclick={closePanel}
					class="text-gray-500 hover:text-white transition-all hover:scale-110"
					aria-label="Close Panel"
				>
					<svg
						xmlns="http://www.w3.org/2000/svg"
						class="h-6 w-6"
						fill="none"
						viewBox="0 0 24 24"
						stroke="currentColor"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2.5"
							d="M6 18L18 6M6 6l12 12"
						/>
					</svg>
				</button>
			</Tooltip>
		</div>
	</div>

	<!-- Content -->
	<div
		class="flex-1 overflow-y-auto p-12 custom-scrollbar bg-[radial-gradient(circle_at_top_right,#1a1a1a,transparent)]"
	>
		{#if activeTab === "player"}
			<div class="max-w-3xl mx-auto space-y-10">
				<!-- Event Status Card -->
				<div
					class="bg-[#141414] p-8 rounded-2xl border border-white/5 flex justify-between items-center"
				>
					<div>
						<h3
							class="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2"
						>
							Event Status
						</h3>
						<div class="flex items-center gap-3">
							{#if eventData.eventActive}
								<div
									class="w-3 h-3 bg-success rounded-full animate-pulse"
								></div>
								<span
									class="text-2xl font-black text-white uppercase italic"
									>Active Live</span
								>
							{:else if eventData.eventHosting}
								<div
									class="w-3 h-3 bg-indigo-500 rounded-full"
								></div>
								<span
									class="text-2xl font-black text-white uppercase italic"
									>Recruiting Players</span
								>
							{:else}
								<div
									class="w-3 h-3 bg-gray-600 rounded-full"
								></div>
								<span
									class="text-2xl font-black text-gray-500 uppercase italic"
									>Offline</span
								>
							{/if}
						</div>
					</div>

					<div class="flex gap-4">
						{#if !playerOwnData.inEvent}
							<button
								disabled={!eventData.eventHosting ||
									eventData.eventActive}
								onclick={() => handleAction("join")}
								class="px-10 py-4 bg-[#ff4d4d] hover:bg-[#ff3333] disabled:bg-gray-800 disabled:opacity-50 text-white font-black uppercase tracking-widest text-xs rounded-xl transition-all hover:scale-105 active:scale-95"
							>
								Join Event
							</button>
						{:else}
							<button
								onclick={() => handleAction("leave")}
								class="px-10 py-4 bg-gray-800 hover:bg-danger text-white font-black uppercase tracking-widest text-xs rounded-xl transition-all hover:scale-105"
							>
								Leave Event
							</button>
						{/if}
					</div>
				</div>

				<!-- Player Stats Grid -->
				{#if playerOwnData.inEvent}
					<div class="grid grid-cols-2 gap-8">
						<div
							class="bg-[#141414] p-8 rounded-2xl border border-white/5 group"
						>
							<h3
								class="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-3 group-hover:text-success transition-colors"
							>
								Clearance Level
							</h3>
							<p
								class="text-5xl font-black text-white tracking-tighter"
							>
								LVL <span class="text-[#ff4d4d]"
									>{playerOwnData.level}</span
								>
							</p>
						</div>
						<div
							class="bg-[#141414] p-8 rounded-2xl border border-white/5"
						>
							<h3
								class="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-6"
							>
								Security Tokens
							</h3>
							<div class="flex gap-3">
								{#each playerOwnData.tokens as token, i}
									<div
										class="w-10 h-10 rounded-lg flex items-center justify-center border-2 transition-all {token
											? 'bg-indigo-500/20 border-indigo-500 text-indigo-500 scale-110'
											: 'bg-black/40 border-white/5 text-gray-800'}"
									>
										<span class="font-black text-sm"
											>{i + 1}</span
										>
									</div>
								{/each}
							</div>
						</div>
					</div>
				{/if}
			</div>
		{:else if activeTab === "admin" && uiState.isAdmin}
			<div class="space-y-8">
				<!-- Admin Sub-tabs -->
				<div class="flex gap-3 mb-4">
					<button
						onclick={() => (adminSubTab = "current")}
						class="px-5 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all {adminSubTab ===
						'current'
							? 'bg-[#ff4d4d] text-white'
							: 'bg-white/5 text-gray-500 hover:text-white'}"
					>
						Current Event
					</button>
					<button
						onclick={() => (adminSubTab = "history")}
						class="px-5 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all {adminSubTab ===
						'history'
							? 'bg-[#ff4d4d] text-white'
							: 'bg-white/5 text-gray-500 hover:text-white'}"
					>
						Event History
					</button>
				</div>

				{#if adminSubTab === "current"}
					<!-- Global Controls -->
					<div
						class="bg-[#141414] p-8 rounded-2xl border border-white/5"
					>
						<div class="flex justify-between items-center mb-6">
							<h3
								class="text-[10px] font-black text-gray-500 uppercase tracking-widest"
							>
								Global Controls
							</h3>
							<div class="flex gap-2">
								{#if eventData.eventActive}
									<span
										class="px-3 py-1 bg-success/10 text-success text-[9px] font-black rounded-lg uppercase tracking-widest border border-success/20"
										>Active Session</span
									>
								{:else if eventData.eventHosting}
									<span
										class="px-3 py-1 bg-indigo-500/10 text-indigo-400 text-[9px] font-black rounded-lg uppercase tracking-widest border border-indigo-500/20"
										>Recruiting</span
									>
								{:else}
									<span
										class="px-3 py-1 bg-white/5 text-gray-500 text-[9px] font-black rounded-lg uppercase tracking-widest border border-white/10"
										>Standby</span
									>
								{/if}
							</div>
						</div>
						<div class="grid grid-cols-3 gap-6 items-end">
							<button
								onclick={() => handleAction("host")}
								class="w-full py-4 bg-indigo-600/10 text-indigo-500 hover:bg-indigo-600/20 border border-indigo-500/30 rounded-xl font-black uppercase tracking-widest text-xs transition-all"
								>Host Event</button
							>

							<div class="flex flex-col gap-2">
								<span
									class="text-[9px] font-black text-gray-600 uppercase tracking-widest ml-1"
									>Starting Level</span
								>
								<div class="flex gap-2">
									<select
										id="start-level-select"
										class="bg-black/40 border border-white/10 rounded-xl px-3 h-12 text-xs font-black text-white outline-none focus:border-success/50 transition-colors cursor-pointer"
									>
										<option value="1">Level 1</option>
										<option value="2">Level 2</option>
										<option value="3">Level 3</option>
										<option value="4">Level 4</option>
										<option value="5">Level 5</option>
										<option value="6">Level 6</option>
									</select>
									<button
										onclick={() => {
											const el = document.getElementById(
												"start-level-select",
											) as HTMLSelectElement;
											handleAction(
												"start",
												undefined,
												parseInt(el.value),
											);
										}}
										class="flex-1 py-4 bg-success/10 text-success hover:bg-success/20 border border-success/30 rounded-xl font-black uppercase tracking-widest text-xs transition-all"
										>Start</button
									>
								</div>
							</div>

							<button
								onclick={() => handleAction("end")}
								class="w-full py-4 bg-danger/10 text-danger hover:bg-danger/20 border border-danger/30 rounded-xl font-black uppercase tracking-widest text-xs transition-all"
								>Stop Event</button
							>
						</div>
					</div>

					<!-- Winners & Leaderboard Grid -->
					<div class="grid grid-cols-5 gap-8">
						<!-- Winner List (3 Slots) -->
						<div class="col-span-2 space-y-4">
							<h3
								class="text-[10px] font-black text-gray-500 uppercase tracking-widest"
							>
								Winning Podium
							</h3>
							<div class="space-y-3">
								{#each winnerSlots() as slot}
									<div
										class="flex items-center gap-4 p-4 rounded-2xl border {slot.name ===
										'Yet to be Decided'
											? 'bg-black/20 border-white/5 opacity-50'
											: 'bg-success/10 border-success/30'}"
									>
										<div
											class="w-10 h-10 rounded-xl flex items-center justify-center font-black text-lg {slot.name ===
											'Yet to be Decided'
												? 'bg-white/5 text-gray-600'
												: 'bg-success/20 text-success'}"
										>
											#{slot.place}
										</div>
										<div class="flex flex-col">
											<span
												class="text-sm font-black uppercase italic {slot.name ===
												'Yet to be Decided'
													? 'text-gray-600'
													: 'text-white'}"
												>{slot.name}</span
											>
											<span
												class="text-[9px] font-bold uppercase tracking-widest text-gray-500"
												>{slot.time}</span
											>
										</div>
									</div>
								{/each}
							</div>
						</div>

						<!-- Leaderboard -->
						<div class="col-span-3 space-y-4">
							<h3
								class="text-[10px] font-black text-gray-500 uppercase tracking-widest"
							>
								Leaderboard (Live Ranking)
							</h3>
							<div
								class="bg-[#141414] rounded-2xl border border-white/5 overflow-hidden"
							>
								<table class="w-full text-left">
									<thead
										class="bg-black/40 text-[9px] font-black text-gray-600 uppercase tracking-widest"
									>
										<tr>
											<th class="px-6 py-4">Player</th>
											<th class="px-6 py-4 text-center"
												>Level</th
											>
											<th class="px-6 py-4 text-center"
												>Tokens</th
											>
											<th class="px-6 py-4 text-right"
												>Actions</th
											>
										</tr>
									</thead>
									<tbody class="divide-y divide-white/5">
										{#if leaderboard().length === 0}
											<tr
												><td
													colspan="4"
													class="px-6 py-12 text-center text-[10px] text-gray-600 font-black uppercase"
													>No participants</td
												></tr
											>
										{:else}
											{#each leaderboard() as player}
												<tr
													class="group transition-all {player.finished
														? player.place <= 3
															? 'bg-[#ffc107]/10 hover:bg-[#ffc107]/15 border-l-2 border-[#ffc107]'
															: 'bg-success/5 hover:bg-success/10 border-l-2 border-success/30'
														: 'hover:bg-white/[0.02]'}"
												>
													<td class="px-6 py-4">
														<div
															class="flex items-center gap-3"
														>
															{#if player.finished}
																<div
																	class="w-8 h-8 rounded-lg flex items-center justify-center font-black text-sm {player.place <=
																	3
																		? 'bg-[#ffc107]/20 text-[#ffc107]'
																		: 'bg-success/20 text-success'}"
																>
																	#{player.place}
																</div>
															{:else}
																<span
																	class="w-6 h-6 rounded bg-white/5 flex items-center justify-center text-[10px] font-black text-gray-500"
																	>{player.source}</span
																>
															{/if}
															<div
																class="flex flex-col"
															>
																<span
																	class="text-xs font-bold {player.finished &&
																	player.place <=
																		3
																		? 'text-[#ffc107]'
																		: 'text-gray-200'}"
																>
																	{player.name}
																</span>
																{#if player.finished && player.time}
																	<span
																		class="text-[9px] text-gray-500 font-bold uppercase tracking-widest"
																		>{player.time}</span
																	>
																{/if}
															</div>
														</div>
													</td>
													<td
														class="px-6 py-4 text-center"
													>
														{#if player.finished}
															<span
																class="px-2 py-1 bg-success/20 text-success text-[10px] font-black rounded italic uppercase"
																>Finished</span
															>
														{:else}
															<span
																class="px-2 py-1 bg-indigo-500/10 text-indigo-400 text-[10px] font-black rounded italic"
																>LVL {player.level}</span
															>
														{/if}
													</td>
													<td
														class="px-6 py-4 text-center text-xs font-black {player.finished
															? 'text-gray-500'
															: 'text-white'}"
														>{player.finished
															? "-"
															: player.tokens}</td
													>
													<td
														class="px-6 py-4 text-right"
													>
														<div
															class="flex gap-1 justify-end opacity-0 group-hover:opacity-100 transition-all"
														>
															<button
																onclick={() =>
																	handleAction(
																		"teleportSpawn",
																		player.source,
																	)}
																class="p-2 text-gray-500 hover:text-indigo-400"
																aria-label="Teleport to Spawn"
																><svg
																	class="w-4 h-4"
																	fill="none"
																	stroke="currentColor"
																	viewBox="0 0 24 24"
																	><path
																		stroke-linecap="round"
																		stroke-linejoin="round"
																		stroke-width="2.5"
																		d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
																	/></svg
																></button
															>
															<button
																onclick={() =>
																	handleAction(
																		"forceAdvance",
																		player.source,
																	)}
																class="p-2 text-gray-500 hover:text-success"
																aria-label="Force Advance Level"
																><svg
																	class="w-4 h-4"
																	fill="none"
																	stroke="currentColor"
																	viewBox="0 0 24 24"
																	><path
																		stroke-linecap="round"
																		stroke-linejoin="round"
																		stroke-width="2.5"
																		d="M13 5l7 7-7 7M5 5l7 7-7 7"
																	/></svg
																></button
															>
															<button
																onclick={() =>
																	handleAction(
																		"removePlayer",
																		player.source,
																	)}
																class="p-2 text-gray-500 hover:text-danger"
																aria-label="Remove Player"
																><svg
																	class="w-4 h-4"
																	fill="none"
																	stroke="currentColor"
																	viewBox="0 0 24 24"
																	><path
																		stroke-linecap="round"
																		stroke-linejoin="round"
																		stroke-width="2.5"
																		d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
																	/></svg
																></button
															>
														</div>
													</td>
												</tr>
											{/each}
										{/if}
									</tbody>
								</table>
							</div>
						</div>
					</div>
				{:else}
					<!-- Persistent History Tab -->
					<div
						class="bg-[#141414] p-8 rounded-2xl border border-white/5 h-full flex flex-col"
					>
						<div class="flex justify-between items-center mb-6">
							<div>
								<h3
									class="text-[10px] font-black text-gray-500 uppercase tracking-widest mb-2"
								>
									Persistent Event History
								</h3>
								<p
									class="text-[10px] text-gray-600 font-bold italic"
								>
									{selectedSession
										? "Detailed Session Report"
										: "Official record of champions from all sessions."}
								</p>
							</div>
							{#if selectedSession}
								<button
									onclick={() => (selectedSession = null)}
									class="px-4 py-2 bg-white/5 hover:bg-white/10 text-gray-400 hover:text-white rounded-lg text-[9px] font-black uppercase tracking-widest transition-all border border-white/5"
								>
									&larr; Back to List
								</button>
							{/if}
						</div>

						{#if eventHistory.length === 0}
							<div
								class="flex-1 flex flex-col items-center justify-center bg-black/20 rounded-2xl border border-dashed border-white/5 opacity-30"
							>
								<svg
									class="h-12 w-12 mb-4"
									fill="none"
									stroke="currentColor"
									viewBox="0 0 24 24"
									><path
										stroke-linecap="round"
										stroke-linejoin="round"
										stroke-width="2"
										d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
									/></svg
								>
								<span
									class="text-[10px] font-black uppercase tracking-widest"
									>No history record found</span
								>
							</div>
						{:else if selectedSession}
							<!-- Detailed Session View -->
							<div
								class="flex-1 overflow-y-auto pr-2 custom-scrollbar space-y-6"
							>
								<div class="grid grid-cols-3 gap-4">
									<div
										class="bg-black/40 p-4 rounded-xl border border-white/5"
									>
										<span
											class="text-[8px] font-black text-gray-600 uppercase block mb-1"
											>Session ID</span
										>
										<span
											class="text-lg font-black text-[#ff4d4d] italic tracking-tighter"
											>#{selectedSession.id}</span
										>
									</div>
									<div
										class="bg-black/40 p-4 rounded-xl border border-white/5"
									>
										<span
											class="text-[8px] font-black text-gray-600 uppercase block mb-1"
											>Completion Date</span
										>
										<span
											class="text-xs font-black text-white italic"
											>{selectedSession.date}</span
										>
									</div>
									<div
										class="bg-black/40 p-4 rounded-xl border border-white/5"
									>
										<span
											class="text-[8px] font-black text-gray-600 uppercase block mb-1"
											>Total Players</span
										>
										<span
											class="text-lg font-black text-indigo-400 italic tracking-tighter"
											>{selectedSession.leaderboard
												.length}</span
										>
									</div>
								</div>

								<div
									class="bg-black/20 rounded-xl border border-white/5 overflow-hidden"
								>
									<table class="w-full text-left">
										<thead
											class="bg-black/40 text-[9px] font-black text-gray-600 uppercase tracking-widest"
										>
											<tr>
												<th class="px-6 py-4">Player</th
												>
												<th
													class="px-6 py-4 text-center"
													>Final Level</th
												>
												<th
													class="px-6 py-4 text-center"
													>Tokens</th
												>
												<th class="px-6 py-4 text-right"
													>Result</th
												>
											</tr>
										</thead>
										<tbody class="divide-y divide-white/5">
											{#each selectedSession.leaderboard as player}
												<tr
													class="hover:bg-white/[0.02] transition-all {player.finished
														? 'bg-success/5'
														: ''}"
												>
													<td class="px-6 py-4">
														<div
															class="flex items-center gap-3"
														>
															<span
																class="text-xs font-bold text-gray-200"
																>{player.name}</span
															>
															<span
																class="text-[9px] text-gray-600 font-bold uppercase tracking-widest border border-white/10 px-1.5 py-0.5 rounded truncate max-w-[60px]"
																>ID: {player.source}</span
															>
														</div>
													</td>
													<td
														class="px-6 py-4 text-center"
													>
														<span
															class="text-[10px] font-black text-white italic"
															>LVL {player.level}</span
														>
													</td>
													<td
														class="px-6 py-4 text-center text-xs font-black text-gray-500"
														>{player.tokens}</td
													>
													<td
														class="px-6 py-4 text-right"
													>
														{#if player.finished}
															<span
																class="px-2 py-1 bg-success/20 text-success text-[9px] font-black rounded italic uppercase"
																>Win #{player.place}</span
															>
														{:else}
															<span
																class="px-2 py-1 bg-white/5 text-gray-600 text-[9px] font-black rounded italic uppercase"
																>Eliminated</span
															>
														{/if}
													</td>
												</tr>
											{/each}
										</tbody>
									</table>
								</div>
							</div>
						{:else}
							<!-- List of Sessions -->
							<div
								class="grid grid-cols-2 gap-4 overflow-y-auto pr-2 custom-scrollbar"
							>
								{#each eventHistory as record}
									<button
										onclick={() =>
											(selectedSession = record)}
										class="text-left flex items-center justify-between p-5 bg-black/40 rounded-2xl border border-white/5 group hover:border-[#ff4d4d]/30 hover:bg-[#ff4d4d]/5 transition-all outline-none"
									>
										<div class="flex items-center gap-5">
											<div
												class="w-12 h-12 bg-[#ff4d4d]/10 rounded-xl flex items-center justify-center font-black text-[#ff4d4d] italic text-xl tracking-tighter group-hover:scale-110 transition-transform"
											>
												<svg
													class="w-6 h-6"
													fill="none"
													stroke="currentColor"
													viewBox="0 0 24 24"
												>
													<path
														stroke-linecap="round"
														stroke-linejoin="round"
														stroke-width="2.5"
														d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
													/>
												</svg>
											</div>
											<div class="flex flex-col">
												<span
													class="text-white font-black uppercase italic tracking-tight text-lg group-hover:text-[#ff4d4d] transition-colors"
													>Event #{record.id ||
														"??"}</span
												>
												<span
													class="text-[9px] text-gray-600 font-bold uppercase tracking-widest"
													>{record.date}</span
												>
											</div>
										</div>
										<div
											class="px-4 py-2 bg-white/5 rounded-xl border border-white/5"
										>
											<span
												class="text-[8px] font-black text-gray-600 uppercase block mb-1"
												>Participants</span
											>
											<span
												class="text-xs font-black text-white italic tracking-tighter"
												>{record.leaderboard
													? record.leaderboard.length
													: "N/A"}</span
											>
										</div>
									</button>
								{/each}
							</div>
						{/if}
					</div>
				{/if}
			</div>
		{/if}
	</div>
</div>

<style>
	.custom-scrollbar::-webkit-scrollbar {
		width: 4px;
	}
	.custom-scrollbar::-webkit-scrollbar-track {
		background: transparent;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb {
		background: rgba(255, 255, 255, 0.05);
		border-radius: 10px;
	}
	.custom-scrollbar::-webkit-scrollbar-thumb:hover {
		background: rgba(255, 255, 255, 0.1);
	}

	.bg-success {
		background-color: #22c55e;
	}
	.text-success {
		color: #22c55e;
	}
	:global(.bg-danger) {
		background-color: #ef4444 !important;
	}
	.text-danger {
		color: #ef4444;
	}
</style>
