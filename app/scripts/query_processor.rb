require 'csv'

$client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

$COMPLETIONS_MODEL = "text-davinci-003"

$MODEL_NAME = "curie"

$DOC_EMBEDDINGS_MODEL = "text-search-#{$MODEL_NAME}-doc-001"
$QUERY_EMBEDDINGS_MODEL = "text-search-#{$MODEL_NAME}-query-001"

$MAX_SECTION_LEN = 500
$SEPARATOR = "\n* "
$separator_len = 3

def get_embedding(text, model)
    result = $client.embeddings(
      parameters: {model: model,
      input: text}
    )
    result["data"][0]["embedding"]
end

def get_doc_embedding(text)
    get_embedding(text, $DOC_EMBEDDINGS_MODEL)
end

def get_query_embedding(text)
    get_embedding(text, $QUERY_EMBEDDINGS_MODEL)
end


def vector_similarity(x, y)
    return nil unless x && y
    x_size = x.size
    y_size = y.size
    return nil unless x_size == y_size
    xy = x.zip(y).select {|i| i[0] && i[1]}
    return nil unless xy.size == x_size
    xy.map { |a,b| a*b }.reduce(:+)
end

def order_document_sections_by_query_similarity(query, contexts)
    # Find the query embedding for the supplied query, and compare it against all of the pre-calculated document embeddings
    # to find the most relevant sections.
  
    query_embedding = get_query_embedding(query)
  
    document_similarities = contexts.map do |doc_index, doc_embedding|
      [vector_similarity(query_embedding, doc_embedding), doc_index]
    end
    document_similarities.sort.reverse
    # Return the list of document sections, sorted by relevance in descending order.
    document_similarities
end


def load_embeddings(fname)
    embeddings = {}
    max_dim = 0
    CSV.foreach(fname, headers: true) do |row|
        title = row["title"]
        embedding = []
        row.headers.each do |header|
            if header == "title"
                dim = header.to_i
                max_dim = [max_dim, dim].max
                embedding[dim] = row[header].to_f
            end
        end    
        embeddings[title] = embedding
    end
    embeddings
end
  

def construct_prompt(question, context_embeddings, df)
    most_relevant_document_sections = order_document_sections_by_query_similarity(question, context_embeddings)
  
    chosen_sections = []
    chosen_sections_len = 0
    chosen_sections_indexes = []
    most_relevant_document_sections.each do |_, section_index|
      document_section = df.where(df['title'].eq(section_index)).first
      chosen_sections_len += document_section['tokens'].to_s.to_i + $separator_len
      if chosen_sections_len > $MAX_SECTION_LEN
        space_left = $MAX_SECTION_LEN - chosen_sections_len - SEPARATOR.length
        chosen_sections.push($SEPARATOR + document_section['content'].to_s[0...space_left])
        chosen_sections_indexes.push(section_index)
        break
      end
  
      chosen_sections.push($SEPARATOR + document_section['content'].to_s)
      chosen_sections_indexes.push(section_index)
    end
  
    header = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.\n\nContext that may be useful, pulled from Lorem Ipsum:\n"
    question_1 = "\n\n\nQ: What's the use of lorem ipsum?\n\nA: Lorem ipsum is used in print media, websites, etc. as a placeholder text."
    question_2 = "\n\n\nQ: When did lorem ipsum originate?\n\nA:  Lorem ipsum originated sometime around 45 BC and has been a standard text since 1500s."
  
    return [header + chosen_sections.join + question_1 + question_2 + "\n\n\nQ: " + question + "\n\nA: ", chosen_sections.join]
end


def answer_query_with_context(query, df, document_embeddings)
    df = Daru::DataFrame.rows(df.slice(1, df.length), order: ["title", "content", "tokens"])
    prompt, context = construct_prompt(query, document_embeddings, df)
    response = $client.completions(
        parameters: {
            model: $COMPLETIONS_MODEL,
            prompt: prompt,
            max_tokens: 150,
            temperature: 0.0,
        })
    return response["choices"][0]["text"].strip(), context
end
