import { useEffect, useState } from "react";
import { getSearchResults } from "../../helper/api";
import { Service } from "../../types";

const DemoLogic = () => {
    // State
    const [similar, setSimilar] = useState<Service[]>([]);
    const [focus, setFocus] = useState<number | null>(null);

    const handleSimilar = (description: string) => {
        getSearchResults({
            search: description,
        }).then((res) => setSimilar(res));
    };

    const useHandleDemoChange = (description: string) => {
        useEffect(() => {
            setSimilar([]);
        }, [description]);
    };

    return { similar, focus, setFocus, handleSimilar, useHandleDemoChange };
};

export default DemoLogic;