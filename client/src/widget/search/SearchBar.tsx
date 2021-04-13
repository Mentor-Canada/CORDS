// Import
import React, { useState, FormEvent } from "react";
import styled from "styled-components";
import { FaSearch } from "react-icons/fa";

// Utils
import { getResults } from "../utils/apiCalls";

// Styling
const StyledSearchBar = styled.form`
    display: flex;
    align-items: center;
    width: 92%;
    margin-left: 0.2rem;
    input {
        font-size: 0.75rem;
        padding: 0.7rem;
        border-radius: 2rem;
        width: 100%;
        box-shadow: 2px 2px 5px grey;
    }
    button {
        display: flex;
        align-items: center;
        justify-content: center;
        height: 1.9rem;
        width: 1.9rem;
        margin-left: -2.2rem;
        border-radius: 50%;
        background-color: var(--primary-color);
        box-shadow: 2px 2px 5px grey;
    }
`;

// Props
interface Props {
    setServices: React.Dispatch<React.SetStateAction<Service[] | null>>;
}

// Component
const SearchBar = ({ setServices }: Props) => {
    const [search, setSearch] = useState("");

    const handleSearch = (e: FormEvent) => {
        e.preventDefault();
        getResults(search).then((res) => setServices(res));
    };

    return (
        <StyledSearchBar onSubmit={handleSearch}>
            <input
                type="text"
                placeholder="How can we help?"
                onChange={(e) => setSearch(e.target.value)}
            />
            <button type="submit">
                <FaSearch />
            </button>
        </StyledSearchBar>
    );
};

export default SearchBar;
