/**
 * Simple wrapper around fetch API tailored for CEF/FiveM
 * @param eventName - The endpoint eventname to trigger
 * @param data - Data you wish to send in the NUI Callback
 * @param mockData - Mock data to be returned if in the browser
 * @returns returnData - A promise for the data sent back by the NuiCallbacks CB argument
 */
export async function fetchNui<T = any>(
	eventName: string,
	data?: any,
	mockData?: T
): Promise<T> {
	const options = {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json; charset=UTF-8',
		},
		body: JSON.stringify(data),
	};

	const isBrowser = !window.invokeNative;

	if (isBrowser && mockData) {
		return mockData;
	}

	const resourceName = (window as any).GetParentResourceName
		? (window as any).GetParentResourceName()
		: 'nui-frame-app';

	try {
		const resp = await fetch(`https://${resourceName}/${eventName}`, options);
		const respFormatted = await resp.json();
		return respFormatted;
	} catch (error) {
		if (isBrowser) {
			// Fallback for browser if no mockData is provided but we are testing
			return undefined as any;
		}
		throw error;
	}
}
