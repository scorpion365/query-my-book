require "ruby/openai"
require "pdf-reader"
require "optparse"
require "tokenizers"
require "csv"
require "daru"
require "dotenv"
Dotenv.load("../../.env")


$COMPLETIONS_MODEL = "text-davinci-003"

$MODEL_NAME = "curie"

$DOC_EMBEDDINGS_MODEL = "text-search-#{$MODEL_NAME}-doc-001"

$tokenizer = Tokenizers.from_pretrained("gpt2")

$client = OpenAI::Client.new(access_token: ENV["OPENAI_ACCESS_TOKEN"])

def count_tokens(text)
    # Count the number of tokens in text.
    $tokenizer.encode(text).tokens.length
end

def extract_pages(page_text, index)
    if page_text.strip.empty?
        return []
    end

    content = page_text.strip.split(' ').join(' ')
    outputs = [{title: "Page #{index}", content: content, tokens:count_tokens(content)}]

    return outputs
end

# Option parser so the script can be used in CLI
options = {}
OptionParser.new do |parser|
  parser.on("--pdf=name_of_pdf") { |v| options[:pdf] = v }
end.parse!

filename = options[:pdf]

reader = PDF::Reader.new(filename)

res = []
i = 1
reader.pages.each do |page|
    res += extract_pages(page.text, i)
    i += 1
end

df = Daru::DataFrame.new(res)

CSV.open("#{filename}.pages.csv", "w") do |csv|
    csv << ["title", "content", "tokens"]
    df.each_row do |row|
        csv << [row[0], row[1], row[2]]
    end
end

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

def compute_doc_embeddings(df)
    result = {}
    df.each_row_with_index do |row, idx|
        puts row, idx
        result[idx] = get_doc_embedding(row[1])
    end
    result
end

doc_embeddings = compute_doc_embeddings(df)

File.open("#{filename}.embeddings.csv", 'w') do |file|
    writer = CSV.new(file)
    writer << ["title"] + (0...4096).to_a
    doc_embeddings.each_pair do |i, embedding|
        writer << ["Page #{i + 1}"] + embedding
    end
end
