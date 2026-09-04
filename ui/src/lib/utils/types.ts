export interface NuiMessage<T = unknown> {
	action: string;
	data: T;
}


export type NuiDebugEvent<T = unknown> = {
	data: T;
	delay?: number;
}

export type NuiEventHandler<T = any> = (data: T) => void;
