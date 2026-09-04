export interface EventNotification {
    id: number;
    title: string;
    description: string;
    type: 'inform' | 'success' | 'error' | 'warning';
}

export interface CinematicState {
    show: boolean;
    url: string;
    volume: number;
    muted: boolean;
    loop: boolean;
}

export interface UIState {
    isVisible: boolean;
    isAdmin: boolean;
    activeApp: 'none' | 'playerEvent' | 'eventManager' | 'adminPanel' | 'eventPanel';
    eventData: {
        eventActive?: boolean;
        eventHosting?: boolean;
        playersList?: any[];
        liveWinners?: any[];
        history?: any[];
        playerOwnData?: {
            level: number;
            tokens: boolean[];
            inEvent: boolean;
            arenaKills?: number;
        };
    };
    hudActive: boolean;
    hudData: {
        lvlName: string;
        lvlDescription: string;
        currentWinners: number;
        maxWinners: number;
        extraInfo?: string;
    };
    notifications: EventNotification[];
    hudPosition: string;
    cinematic: CinematicState;
}

export const uiState = $state<UIState>({
    isVisible: false,
    isAdmin: false,
    activeApp: 'none',
    eventData: {},
    hudActive: false,
    hudData: {
        lvlName: '',
        lvlDescription: '',
        currentWinners: 0,
        maxWinners: 0
    },
    notifications: [],
    hudPosition: 'bottom-center',
    cinematic: {
        show: false,
        url: '',
        volume: 0.5,
        muted: false,
        loop: false,
    }
});
