export interface Service {
    name: string;
    item_id: string;
    lat: number;
    lng: number;
    address: string;
    link: string;
    description: string;
    distance: number;
}

export interface Location {
    lat: number | undefined;
    lng: number | undefined;
    distance?: number | undefined;
}

export interface SearchBody {
    search: string;
}
export interface GeoSearchBody {
    search: string;
    lat: number | undefined;
    lng: number | undefined;
    distance: number | undefined;
}
export interface SimilarBody {
    resourceId: number;
    lat: number | undefined;
    lng: number | undefined;
}
