class Question < ActiveRecord::Base
  self.table_name = "questions"
  attribute :question, :string, limit: 140
  attribute :context, :text
  attribute :answer, :text, limit: 1000
  attribute :created_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }
  attribute :ask_count, :integer, default: 1
end