import React, { useState } from 'react';
import axios from "axios";

const QueryForm = () => {

  const [query, setQuery] = useState("");
  const [answer, setAnswer] = useState("");
  const [isLoaderVisible, setIsLoaderVisible] = useState(false);

  function createPost() {
    axios
      .post(`${process.env.HOSTNAME}/ask/`, {
        query: query,
      })
      .then((response) => {
        setIsLoaderVisible(false)
        setAnswer(response.data["answer"])
      });
  }

  const handleChange = (event) => {
    setQuery(event.target.value);
  }

  const handleSubmit = (event) => {
    event.preventDefault();
    setIsLoaderVisible(true);
    createPost();
  }

  return (
    <form className="mt-2" onSubmit={handleSubmit}>
      <div>
        <label htmlFor="query" className="block text-sm font-medium text-white">Enter your question below</label>
        <div className="mt-1">
          <input id="query" name="query" type="text" value={query} onChange={handleChange} required className="appearance-none block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm placeholder-gray-400 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm" />
        </div>
      </div>
      <div>
        <button type="submit" className="w-full mt-6 flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
          <svg className={`${isLoaderVisible ? "animate-spin" : "hidden"} -ml-1 mr-3 h-5 w-5 text-white`} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          Ask a query
        </button>
      </div>
      <div className="mt-4">
        <p className="text-white">{answer}</p>
      </div>
    </form>
  )
}
export default QueryForm;