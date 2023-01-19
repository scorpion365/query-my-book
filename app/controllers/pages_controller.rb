require_relative '../scripts/query_processor'

class PagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
  end

  def ask
    question_asked = request.POST.fetch("query", "")
    
    unless question_asked.end_with?('?')
      question_asked += '?'
    end
    
    previous_question = Question.where(question: question_asked).first
    puts previous_question
    if previous_question
      puts "This question was asked previously so returning the answer from db: #{previous_question.answer})"
      previous_question.ask_count += 1
      previous_question.save
      render json: {question: previous_question.question, answer: previous_question.answer}.to_json
      return
    end
    
    df = CSV.read(File.join(File.dirname(__FILE__), '../scripts/book.pdf.pages.csv'))
    document_embeddings = load_embeddings(File.join(File.dirname(__FILE__), '../scripts/book.pdf.embeddings.csv'))
    answer, context = answer_query_with_context(question_asked, df, document_embeddings)
    
    question = Question.new(question: question_asked, answer: answer, context: context)
    question.save
    
    render json: {answer: answer}.to_json
  end
end
