import { onDestroy } from "svelte";
import type { NuiDebugEvent, NuiEventHandler, NuiMessage } from "$lib/utils/types";
import { isEnvBrowser } from "$lib/utils/misc";

const eventListeners = new Map<string, NuiEventHandler[]>();

const eventListener = (event: MessageEvent<NuiMessage>) => {
	const { action, data } = event.data;
	const handlers = eventListeners.get(action);

	if (handlers) {
		handlers.forEach((handler) => handler(data));
	}
};

window.addEventListener("message", eventListener);

/**
 * A function that manage events listeners for receiving data from the client scripts
 * @param action The specific `action` that should be listened for.
 * @param handler The callback function that will handle data relayed by this function
 * @param debug An optional object or array of objects that will be used to simulate the event in the browser
 * 
 * @example
 * useNuiEvent<{visibility: true, wasVisible: 'something'}>('setVisible', (data) => {
 *   // whatever logic you want
 * }, { data: { visibility: true, wasVisible: 'something' }, delay: 1000 });
 *
 **/
export function useNuiEvent<T = unknown>(
	action: string,
	handler: NuiEventHandler<T>,
	debug?: NuiDebugEvent<T> | NuiDebugEvent<T>[],
) {
	if (isEnvBrowser() && debug) {
		const debugEvents = Array.isArray(debug) ? debug : [debug];
		debugEvents.forEach(({ data, delay }) => {
			if (delay) {
				setTimeout(() => handler(data), delay);
			} else {
				handler(data);
			}
		});
		return;
	}

	const handlers = eventListeners.get(action) || [];
	handlers.push(handler);
	eventListeners.set(action, handlers);

	onDestroy(() => {
		const handlers = eventListeners.get(action) || [];

		eventListeners.set(
			action,
			handlers.filter((h) => h !== handler),
		);
	});
}
