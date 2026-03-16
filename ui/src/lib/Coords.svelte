<script lang="ts">
	import { fetchNui } from "$lib/utils/fetchNui";
	import { store } from "$lib/providers/VisibilityProvider.svelte";
	interface ReturnData {
		x: number;
		y: number;
		z: number;
	}

	let clientData: ReturnData;

	const handleClientData = () => {
		fetchNui("getClientData", null, { x: 100, y: 100, z: 100 }).then(
			(returnData) => {
				clientData = returnData;
			},
		);
	};

	const closeDialog = () => {
		store.visibility = false;
		fetchNui("hideUI");
	};
</script>

<div class="container">
	<h2>Svelte NUI Popup!</h2>
	<div style="margin: 0.3vh 0;">
		Player coords: {JSON.stringify(clientData) || ""}
	</div>
	<div class="btn-wrapper">
		<button onclick={handleClientData}> Get client coords </button>
		<button onclick={closeDialog}>Close popup</button>
	</div>
	<span>Or press the escape key!</span>
</div>

<style>
	.container {
		font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
		display: flex;
		flex-direction: column;
		align-items: center;
		align-content: center;
		justify-content: center;
		border-radius: 5px;
		height: 17%;
		font-size: 1.5vh;
		color: white;
		user-select: none;
	}

	.btn-wrapper {
		display: flex;
		justify-content: space-evenly;
		align-items: center;
		align-content: center;
		width: 100%;
	}

	button {
		flex: 0 45%;
		padding: 0.8vh;
		background-color: white;
		color: black;
		font-family: "Segoe UI";
		border: none;
		border-radius: 5px;
	}

	button:hover {
		background-color: rgb(212, 212, 212);
	}
</style>
